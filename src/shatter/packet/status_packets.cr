require "./handler"

module Shatter::Packet::Status
  @[Describe(level: 2)]
  class Response
    include Handler

    field data : JSON::Any = JSON.parse(pkt.read_var_string)
  end
end
