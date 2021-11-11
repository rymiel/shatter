module Shatter::Packet::Play
  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(
    level: 3,
    order: {position, sender, message},
    transform: {
      sender: ((@sender.to_s == "00000000-0000-0000-0000-000000000000") ? "{0}" : @sender.to_s),
      message: Shatter::Chat::AnsiBuilder.new.read(JSON.parse(@message).as_h)
    })]
  @[Shatter::Packet::Alias(Chat)]
  class ChatMessage
    include Packet::Handler

    field message : String
    field position : UInt8
    field sender : UUID
  end
end