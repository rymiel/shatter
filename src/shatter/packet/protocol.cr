require "../packet"

module Shatter::Packet::Protocol
  alias PacketLists = {sb: Hash(Sb::Play, Int32), cb: Hash(Cb::Play, Int32)}
  PROTOCOLS      = Hash(UInt32, PacketLists).new
  PROTOCOL_NAMES = Hash(String, UInt32).new
end

require "./protocol/*"
