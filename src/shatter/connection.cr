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

    getter state = PktId::State::Handshake
    getter ip : String
    getter port : Int32
    getter registry : Registry
    getter block_states : Array(String)
    getter profile : MSA::MinecraftProfile
    getter minecraft_token : String
    getter packet_callback : ((Packet::Handler, Connection) ->)?
    setter last_packet : Packet::Handler? = nil

    def initialize(@ip, @port, @registry, @block_states, @minecraft_token, @profile, @packet_callback = nil)
    end

    def transition(s : Symbol)
      case s
      when :handshake then @state = PktId::State::Handshake
      when :login then @state = PktId::State::Login
      when :play then @state = PktId::State::Play
      end
    end

    def matching_cb(i : UInt32) : (PktId::Cb::Login | PktId::Cb::Play)
      PktId::CB_STATE_MAP[@state].new i.to_i32
    end

    def packet(packet_id : Enum, &block : IO ->)
      mem = IO::Memory.new
      raw_packet_id = packet_id.to_i32
      var_p_id = Shatter.var_int raw_packet_id

      yield mem
      slice = mem.to_slice
      wide_dump(mem, packet_id, true)

      real_size = mem.size + var_p_id.size
      if @using_compression > 0
        if real_size > @using_compression
          compressed_body = IO::Memory.new
          Compress::Zlib::Writer.open compressed_body do |w|
            w.write var_p_id
            w.write slice
          end
          io.write_var_int compressed_body.size
          io.write_var_int real_size
          io.write compressed_body.to_slice
        else
          io.write_var_int real_size + 1
          io.write_var_int 0
          io.write var_p_id
          io.write slice
        end
      else
        io.write_var_int real_size
        io.write var_p_id
        io.write slice
      end
    end

    def io : IO
      @io.not_nil!
    end

    private def read_packet
      size = io.read_var_int
      raise IO::EOFError.new if size == 0
      buffer = Bytes.new size
      io.read_fully buffer
      pkt = IO::Memory.new buffer
      if @using_compression > 0
        real_size = pkt.read_var_int
        if real_size >= @using_compression
          uncompressed_buffer = Bytes.new real_size
          Compress::Zlib::Reader.new(pkt).read_fully uncompressed_buffer
          pkt = IO::Memory.new uncompressed_buffer
        end
      else
        real_size = -1
      end
      raw_packet_id = pkt.read_var_int
      packet_id = matching_cb raw_packet_id
      # puts "Incoming packet: #{@state}/#{packet_id} #{size} -> #{real_size}"
      pkt_body_start = pkt.pos
      is_silent = PktId::SILENT[packet_id]?
      handler = PktId::PACKET_HANDLERS[packet_id]?
      pkt.read_at(pkt_body_start, pkt.size - pkt_body_start) { |b| wide_dump(b, packet_id, unknown: handler.nil?) } unless is_silent
      handler.try &.call(pkt, self)
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

    private def close_from(ioex : IO::Error)
      puts "Failed to read packet due to IO error #{ioex.message}, disconnecting"
      @sock.try &.close
    end

    def run
      spawn do
        TCPSocket.open(@ip, @port) do |sock|
          @io = @sock = sock
          spawn do
            loop do
              read_packet
            rescue ioex : IO::Error
              close_from ioex
              break
            end
          end
          
          packet PktId::Sb::Handshake::Handshake do |pkt|
            pkt.write_var_int 756
            pkt.write_var_string @ip
            pkt.write_bytes(@port.to_u16, IO::ByteFormat::BigEndian)
            pkt.write_var_int 2
          end
          
          transition :login
      
          packet PktId::Sb::Login::LoginStart do |pkt|
            pkt.write_var_string @profile.try &.name || "Steve"
          end
          sleep
        end
      end
    end
  end
end