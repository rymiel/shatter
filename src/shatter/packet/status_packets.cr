module Shatter::Packet::Status
  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 2)]
  class Response
    include Packet::Handler

    field data : JSON::Any = JSON.parse(pkt.read_var_string)
  end
end
