module Shatter::Packet::Login
  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2)]
  class CryptRequest
    include Packet::Handler

    field server_id : String
    array_field pkey_asn : UInt8, count: VarInt, array_type: Slice
    array_field nonce : UInt8, count: VarInt, array_type: Slice

    def run
      rsa_pkey = Crypto.key_for @pkey_asn
      shared_secret = Random::Secure.random_bytes(16)

      hash = Shatter::Crypto.digest do |d|
        d << server_id
        d << shared_secret
        d << pkey_asn
      end

      r = HTTP::Client.post "https://sessionserver.mojang.com/session/minecraft/join",
        headers: HTTP::Headers{
          "Content-Type" => "application/json",
          "User-Agent" => "ShatterCrystal/#{Shatter::VERSION} IG"
        },
        body: {
          "accessToken": con.minecraft_token.to_s,
          "selectedProfile": con.profile.try &.id,
          "serverId": hash
        }.to_json
      puts "Posted session for #{con.profile.try &.name} to #{con.ip}:#{con.port} => #{r.status}"
      unless r.status.no_content?
        pp! r
        begin
          error_reason = JSON.parse(r.body).as_h?.try &.["error"]?.try &.as_s? || "Unknown"
        rescue ex : JSON::ParseException
          error_reason = nil
        end
        raise MSA::MojangAuthError.new(error_reason)
      end

      encoded_secret = rsa_pkey.public_encrypt shared_secret
      encoded_nonce = rsa_pkey.public_encrypt nonce

      con.packet PktId::Sb::Login::CryptResponse do |pkt|
        pkt.write_var_int encoded_secret.size
        pkt.write encoded_secret
        pkt.write_var_int encoded_nonce.size
        pkt.write encoded_nonce
      end

      con.using_crypto = true
      con.io = Crypto::CipherStreamIO.new con.io, "aes-128-cfb8", shared_secret, shared_secret
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2)]
  class SetCompression
    include Packet::Handler

    field threshold : VarInt

    def run
      con.using_compression = pkt.read_var_int
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2)]
  class LoginSuccess
    include Packet::Handler

    def run
      con.transition :play
    end
  end
end
