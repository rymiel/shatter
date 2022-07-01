require "../handler"

module Shatter::Packet::Play
  @[Describe(3, chat,
    order: {position, sender, message})]
  @[Alias(Chat)]
  class ChatMessage
    include Handler

    @[Transform(Shatter::Chat::AnsiBuilder.new.read(JSON.parse(@message).as_h))]
    field message : String
    field position : UInt8
    @[Transform((@sender.to_s == "00000000-0000-0000-0000-000000000000") ? "{0}" : @sender.to_s)]
    field sender : UUID
  end

  @[AlwaysHexdump]
  @[Describe(3)]
  class PluginMessage
    include Handler

    field identifier : String
    @[Transform(String.new(@data).inspect)]
    field data : Bytes = pkt.gets_to_end.to_slice
  end

  @[Describe(5)]
  class Disconnect
    include Handler

    @[Transform(Shatter::Chat::AnsiBuilder.new.read(JSON.parse(@message).as_h))]
    field message : String

    def run(con)
      con.sock.try &.close
    end
  end
end
