require "../protocol"

module Shatter::Protocol::Version1_18_2
  PROTOCOL_VERSION = 758u32
  PROTOCOL_NAMES["1.18.2"] = PROTOCOL_VERSION
  PROTOCOLS[PROTOCOL_VERSION] = PROTOCOLS[Version1_18_1::PROTOCOL_VERSION] # No changes
end
