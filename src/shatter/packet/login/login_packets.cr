require "../handler"

module Shatter::Packet::Login
  @[Describe(2 crypt, default: false)]
  class CryptRequest
    include Handler

    field server_id : String
    field pkey_asn : UInt8[VarInt] -> Slice
    field nonce : UInt8[VarInt] -> Slice

    def run(con)
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
          "User-Agent"   => "ShatterCrystal/#{Shatter::VERSION} IG",
        },
        body: {
          "accessToken":     con.minecraft_token.to_s,
          "selectedProfile": con.profile.try &.id,
          "serverId":        hash,
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

      con.packet Sb::Login::CryptResponse do |pkt|
        pkt.write_var_int encoded_secret.size
        pkt.write encoded_secret
        pkt.write_bool true if con.protocol >= Protocol::Version1_19::PROTOCOL_VERSION
        pkt.write_var_int encoded_nonce.size
        pkt.write encoded_nonce
      end

      con.use_crypto_io Crypto::CipherStreamIO.new con.io, "aes-128-cfb8", shared_secret, shared_secret
    end
  end

  @[Describe(2)]
  class SetCompression
    include Handler

    field threshold : VarInt

    def run(con)
      con.using_compression = @threshold
    end
  end

  @[Describe(2)]
  class LoginSuccess
    include Handler

    def run(con)
      con.transition :play
    end
  end
end
