require "socket"
require "./registry"
require "./msa"
require "./packet"
require "./crypto"

module Shatter
  class Connection
    property io : IO? = nil
    property sock : TCPSocket? = nil
    property using_crypto = false
    property using_compression = 0_u32
    @entities = Hash(UInt32, Data::Entity).new do |hash, key|
      Data::Entity.new key, UUID.empty, "unknown:unknown"
    end
    @players = Hash(UUID, Data::Player).new do |hash, key|
      hash[key] = Data::Player.new(key, ".unknown", ({} of String => {String, String?}), Data::Player::Gamemode::Survival, 0_u32, nil)
    end
    getter entities
    getter players

    getter state = Packet::State::Handshake
    getter protocol : UInt32
    getter ip : String
    getter port : Int32
    getter registry : Registry
    getter block_states : Array(String)
    getter profile : MSA::MinecraftProfile
    getter minecraft_token : String
    getter packet_callback : ((Packet::Handler, Connection) ->)? = nil

    alias OutboundContainer = {pid: Bytes, body: Bytes}
    getter outbound = Channel(OutboundContainer).new

    @read_mutex = Mutex.new

    def initialize(@protocol, @ip, @port, @registry, @block_states, @minecraft_token, @profile, @packet_callback = nil)
    end

    def transition(s : Packet::State)
      @state = s
    end

    def matching_cb(i : UInt32) : (Packet::Cb::Login | Packet::Cb::Play | Packet::Cb::Status)
      if @state.play?
        i = Packet::Protocol::PROTOCOLS[@protocol][:cb][i]
      end
      Packet::CB_STATE_MAP[@state].new i.to_i32
    end

    def packet(packet_id : Packet::Sb::Play | Packet::Sb::Status | Packet::Sb::Login | Packet::Sb::Handshake, &block : IO ->)
      mem = IO::Memory.new
      raw_packet_id = Packet::Protocol::PROTOCOLS[@protocol]?.try &.[:sb][packet_id]? || packet_id.to_i32
      var_p_id = Shatter.var_int raw_packet_id

      yield mem
      slice = mem.to_slice
      @outbound.send({pid: var_p_id, body: slice})
      wide_dump(mem, packet_id, true)
      sleep 0
    end

    def io : IO
      @io.not_nil!
    end

    private def read_packet : Packet::Handler?
      buffer = Bytes.new 0
      @read_mutex.synchronize do
        size = io.read_var_int
        raise IO::EOFError.new if size == 0
        buffer = Bytes.new size
        io.read_fully buffer
      end

      pkt = IO::Memory.new buffer
      if @using_compression > 0
        real_size = pkt.read_var_int
        if real_size >= @using_compression
          uncompressed_buffer = Bytes.new real_size
          Compress::Zlib::Reader.new(pkt).read_fully uncompressed_buffer
          pkt = IO::Memory.new uncompressed_buffer
        end
      end
      raw_packet_id = pkt.read_var_int
      packet_id = matching_cb raw_packet_id

      pkt_body_start = pkt.pos
      is_ignored = Packet::Cb::IGNORE.includes? packet_id
      is_silent = Packet::SILENT[packet_id]?
      handler = Packet::PACKET_HANDLERS[packet_id]?
      return if is_ignored
      resolved = nil
      pkt.read_at(pkt_body_start, pkt.size - pkt_body_start) { |b| wide_dump(b, packet_id, unknown: handler.nil?) } unless is_silent
      if handler
        resolved = handler.call(pkt, self)
        resolved.describe
        resolved.run
        @packet_callback.try &.call(resolved, self)
      end
      return resolved
    end

    private def wide_dump(b : IO, packet_id, out_pkt = false, unknown = false)
      marker = out_pkt ? "OUT-PKT>".colorize.green : " IN-PKT<".colorize.red
      packet_name = packet_id.to_s.rjust(16).colorize(out_pkt ? :light_green : :red)
      marker = marker.bold if unknown
      packet_name = packet_name.bold if unknown
      STDERR.puts((b.as IO::Memory).to_slice.wide_hexdump(
        sections: 4, address: 6,
        prefix: "#{marker}#{packet_name}|#{Shatter.hex(packet_id.to_i32).colorize.dark_gray} "
      ))
    end

    private def close_from(ex : Exception)
      puts "Failed to read packet due to error #{ex.message}, disconnecting"
      @sock.try &.close
    end

    def use_crypto_io(io : Crypto::CipherStreamIO)
      @using_crypto = true
      @io = io
    end

    def inspect(io : IO) : Nil
      io << {{@type.name.id.stringify}} << '('
      {% for ivar, i in @type.instance_vars %}
        {% if ivar.name != "registry" && ivar.name != "block_states" %}
          {% if i > 0 %}
            io << ", "
          {% end %}
          io << "@{{ivar.id}}="
          @{{ivar.id}}.inspect(io)
        {% end %}
      {% end %}
      io << ')'
    end

    def run
      spawn name: "conwrapper main #{@profile.name}" do
        TCPSocket.open(@ip, @port) do |sock|
          @sock = sock
          @io = @sock

          spawn name: "conwrapper inbound #{@profile.name}" do
            loop do
              read_packet
            rescue ex : Exception
              close_from ex
              ex.inspect_with_backtrace STDERR
              break
            end
          end

          spawn name: "conwrapper outbound #{@profile.name}" do
            loop do
              x = @outbound.receive
              break if x.nil?
              var_p_id = x[:pid]
              mem = x[:body]
              real_size = mem.size + var_p_id.size
              if @using_compression > 0
                if real_size > @using_compression
                  compressed_body = IO::Memory.new
                  Compress::Zlib::Writer.open compressed_body do |w|
                    w.write var_p_id
                    w.write mem
                  end
                  io.write_var_int compressed_body.size
                  io.write_var_int real_size
                  io.write compressed_body.to_slice
                else
                  io.write_var_int real_size + 1
                  io.write_var_int 0
                  io.write var_p_id
                  io.write mem
                end
              else
                io.write_var_int real_size
                io.write var_p_id
                io.write mem
              end
              io.flush
            end
          end

          packet Packet::Sb::Handshake::Handshake do |pkt|
            pkt.write_var_int @protocol
            pkt.write_var_string @ip
            pkt.write_bytes(@port.to_u16, IO::ByteFormat::BigEndian)
            pkt.write_var_int 2
          end

          transition :login

          packet Packet::Sb::Login::LoginStart do |pkt|
            pkt.write_var_string @profile.try &.name || "Steve"
          end

          sleep
        end
      end
    end

    def ping
      spawn name: "conwrapper ping #{@profile.name}" do
        TCPSocket.open(@ip, @port) do |sock|
          @sock = sock
          @io = @sock

          spawn name: "conwrapper ping outbound #{@profile.name}" do
            loop do
              x = @outbound.receive?
              break if x.nil?
              real_size = x[:body].size + x[:pid].size
              io.write_var_int real_size
              io.write x[:pid]
              io.write x[:body]
              io.flush
            end
          end

          packet Packet::Sb::Handshake::Handshake do |pkt|
            pkt.write_var_int 756
            pkt.write_var_string @ip
            pkt.write_bytes(@port.to_u16, IO::ByteFormat::BigEndian)
            pkt.write_var_int 1
          end

          transition :status

          packet Packet::Sb::Status::Request do
          end

          read_packet
          @outbound.close
        end
      rescue ex : Socket::ConnectError
        # Swallow
      end
    end
  end
end
