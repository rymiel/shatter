module Shatter
  class WS
    module Frame
      alias Auth = {token: String}
      alias Connect = {host: String, port: Int32?, listening: Array(PktId::Cb::Play), proxied: Array(PktId::Cb::Play)}
    end

    alias Permits = Hash(String, Array(String))

    class_getter active = [] of WS

    getter! con : WSProxy
    getter! mc_token : String
    getter! profile : MSA::MinecraftProfile
    property abort_connection = false
    getter id : UInt32
    getter registries : {Shatter::Registry, Array(String)}
    getter ws : HTTP::WebSocket
    getter opened : Time
    @authenticating = false

    private def logged_send(s)
      local_log s, trace: true, passthrough: true
      @ws.send(s)
    end

    def initialize(@ws, @id, @registries)
      local_log "New connection"
      @opened = Time.utc
      @@active << self
      # ws.on_ping { ws.pong ctx.request.path }
      @ws.on_message do |raw_message|
        local_log raw_message, trace: true
        if @mc_token.nil? && !@authenticating
          @authenticating = true
          ws_log = ->(msg : String) { ws.send({"log" => msg}.to_json) }
          frame = Frame::Auth.from_json raw_message
          @mc_token, @profile = wsp_auth frame
          next if reject request_offer: true
          local_log "Auth as #{profile.name} successful"
          logged_send({"ready" => profile.name, "id" => profile.id}.to_json)
        elsif !@mc_token.nil? && @con.nil?
          frame = Frame::Connect.from_json raw_message
          next if reject host: frame[:host]
          @con = WSProxy.new(
            frame[:host],
            frame[:port] || 25565,
            frame[:listening],
            frame[:proxied],
            self
          )
          con.run unless abort_connection
        elsif !@con.nil?
          json = JSON.parse(raw_message).as_h?
          next unless json
          if json.has_key?("list")
            user_permit = permits[profile.id]?
            next if user_permit.nil?
            next unless user_permit.includes? "*"
            logged_send({"list" => @@active.map { |i| {
              "Shatter::WS" => {
                "opened"     => i.opened,
                "id"         => i.id,
                "profile"    => i.profile,
                "connection" => i.con?.try { |c| {"host" => "#{c.ip}:#{c.port}", "state" => c.state, "listening" => c.listening, "proxying" => c.proxied} } || "[No connection]",
              },
            } }}.to_json)
          elsif json.has_key?("emulate") && json["emulate"].as_s?
            emulate = json["emulate"].as_s
            local_log "Emulate #{emulate}"
            case emulate
            when "Chat"
              structure = ChatProxy::SbStructure.from_json json["proxy"].to_json
              local_log "Proxy chat: #{structure}"
              con.packet(PktId::Sb::Play::Chat) { |pkt| ChatProxy.convert_sb structure, pkt }
            else raise "Unknown proxy capability"
            end
          end
        end
      rescue ex
        puts ex.inspect_with_backtrace
        logged_send({"error" => "Your connection to the server has been closed because of #{ex.class}. #{ex.message}"}.to_json)
        @ws.close
        raise ex
      end
      ws.on_close { |close|
        local_log "Connection dropped (#{close})"
        abort_connection = true
        @mc_token = nil
        @con.try &.sock.try &.close
        @@active.delete self
      }
    end

    private def permits
      File.open "permits.json" { |f| Permits.from_json f }
    end

    private def reject(*, host : String? = nil, request_offer = false)
      user_permit = permits[profile.id]?
      if user_permit.nil?
        local_log "Dropping #{profile.id} (#{profile.name}) because they aren't whitelisted"
        logged_send({"error" => "You are not whitelisted to access this service"}.to_json)
        logged_send({"offer" => "/rq/#{profile.name}/#{profile.id}"}.to_json) if request_offer
        @ws.close
        return true
      end
      if host
        unless user_permit.includes?(host) || user_permit.includes?("*")
          local_log "Dropping #{profile.name} because they tried to access #{host}, but wasn't permitted"
          logged_send({"error" => "You are not permitted to access that server using this service"}.to_json)
          @ws.close
          return true
        end
      end
      false
    end

    def wsp_auth(frame : Frame::Auth)
      remote_log "1/6: MSA"
      msa = Shatter::MSA.new
      remote_log "2/6: Token"
      token = msa.code frame[:token]
      remote_log "3/6: XBL"
      xbl = msa.xbl token
      remote_log "4/6: XSTS"
      xsts = msa.xsts xbl
      remote_log "5/6: Minecraft"
      mc_token = msa.minecraft xsts
      remote_log "6/6: Checking profile"
      profile = msa.profile mc_token
      {mc_token.access_token, profile}
    end

    def remote_log(s : String)
      local_log s, passthrough: true
      @ws.send({"log" => s}.to_json)
    end

    def local_log(s : String, trace = false, passthrough = false)
      STDOUT << id.to_s.rjust(3).colorize.yellow.bold << " "
      STDOUT << ((@profile.try &.name) || "[unknown]").rjust(16).colorize.light_cyan << " "
      STDOUT << if trace && passthrough
        "]LOG[".colorize.blue
      elsif trace
        "(LOG)".colorize.blue
      elsif passthrough
        ">LOG>".colorize.red
      else
        "*LOG*".colorize.yellow.underline
      end
      s = s.colorize.dark_gray if trace
      STDOUT << " " << s << "\n"
    end

    def inspect(io : IO) : Nil
      io << {{@type.name.id.stringify}} << '('
      {% for ivar, i in @type.instance_vars %}
        {% if ivar.name != "registries" %}
          {% if i > 0 %}
            io << ", "
          {% end %}
          io << "@{{ivar.id}}="
          @{{ivar.id}}.inspect(io)
        {% end %}
      {% end %}
      io << ')'
    end
  end
end
