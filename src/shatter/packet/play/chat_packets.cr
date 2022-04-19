require "../handler"

module Shatter::Packet::Play
  @[Silent]
  @[Describe(
    level: 3,
    order: {position, sender, message},
    transform: {
      sender:  ((@sender.to_s == "00000000-0000-0000-0000-000000000000") ? "{0}" : @sender.to_s),
      message: Shatter::Chat::AnsiBuilder.new.read(JSON.parse(@message).as_h),
    })]
  @[Alias(Chat)]
  class ChatMessage
    include Handler

    field message : String
    field position : UInt8
    field sender : UUID
  end

  @[Describe(level: 3)]
  class PluginMessage
    include Handler

    field identifier : String
    field data : Bytes = pkt.gets_to_end.to_slice
  end

  @[Silent]
  @[Describe(level: 5, transform: {message: Shatter::Chat::AnsiBuilder.new.read(JSON.parse(@message).as_h)})]
  class Disconnect
    include Handler

    field message : String

    def run
      con.sock.try &.close
    end
  end
end
