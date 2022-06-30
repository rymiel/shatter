require "../packet"

module Shatter::Packet::Protocol
  alias PacketLists = {sb: Hash(Sb::Play, Int32), cb: Hash(Int32, Cb::Play)}
  PROTOCOLS      = Hash(UInt32, PacketLists).new
  PROTOCOL_NAMES = Hash(String, UInt32).new
end

require "./protocol/*"
