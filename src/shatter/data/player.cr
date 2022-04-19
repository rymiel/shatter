require "uuid"
require "../packet/handler"

module Shatter::Data
  class Player
    enum Gamemode : Int8
      Survival
      Creative
      Adventure
      Spectator
    end
    property uuid : UUID
    property name : String
    property props : Hash(String, {String, String?})
    property gamemode : Gamemode
    property ping : UInt32
    property display_name : Packet::ChatContainer?

    def initialize(@uuid, @name, @props, @gamemode, @ping, @display_name)
    end

    def to_s(io : IO)
      io << "<Player "
      io << (display_name || @name)
      io << ";"
      @uuid.to_s io
      io << ">"
    end

    def inspect(io : IO)
      io << "#<Player " << @name
      io << " as " << display_name if display_name
      io << ";"
      @uuid.to_s io
      io << ";" << gamemode.to_s
      io << ";" << ping.to_s << "ms"
      io << ">"
    end
  end
end
