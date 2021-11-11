require "uuid/json"

module Shatter
  class WS
    module ChatProxy
      alias SbStructure = {chat: String}
      alias CbStructure = {html: String, sender: UUID, position: UInt8}

      def self.convert_cb(pkt : Packet::Play::ChatMessage) : CbStructure
        html_message = Shatter::Chat::HtmlBuilder.new.read JSON.parse(pkt.message).as_h
        {html: html_message, sender: pkt.sender, position: pkt.position}
      end

      def self.convert_sb(s : SbStructure, pkt : IO)
        pkt.write_var_string s[:chat]
      end
    end
  end
end