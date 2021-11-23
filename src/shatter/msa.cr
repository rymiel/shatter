require "uri"
require "json"
require "openssl"

class Shatter::MSA
  APPLICATION_ID = ENV["MSA_APPLICATION_ID"]
  CLIENT_SECRET  = ENV["MSA_SECRET"]
  REDIRECT_URI   = ENV["MSA_REDIRECT"]

  record AuthorizationToken, token_type : String, expires_in : Int32, scope : String, access_token : String, id_token : String do
    include JSON::Serializable
  end
  record MinecraftToken, username : String, roles : Array(String), token_type : String, access_token : String, expires_in : Int32 do
    include JSON::Serializable
  end
  record MinecraftProfile, id : String, name : String do
    include JSON::Serializable
  end

  class MojangAuthError < Exception
  end

  class XBLToken
    include JSON::Serializable

    @[JSON::Field(key: "NotAfter")]
    property not_after : Time
    @[JSON::Field(key: "Token")]
    property token : String
    @[JSON::Field(key: "DisplayClaims")]
    property display_claims : {xui: Array({uhs: String})}
  end

  def code(code : String) : AuthorizationToken
    r = HTTP::Client.post "https://login.live.com/oauth20_token.srf",
      headers: HTTP::Headers{"User-Agent" => "ShatterCrystal/#{Shatter::VERSION} MSA"},
      form: {
        "client_id"     => APPLICATION_ID,
        "client_secret" => CLIENT_SECRET,
        "code"          => code,
        "grant_type"    => "authorization_code",
        "redirect_uri"  => REDIRECT_URI,
        "scope"         => "xboxlive.signin",
      }
    # pp! JSON.parse r.body
    AuthorizationToken.from_json r.body
  end

  def refresh(refresh_token : String) : AuthorizationToken
    r = HTTP::Client.post "https://login.live.com/oauth20_token.srf",
      headers: HTTP::Headers{"User-Agent" => "ShatterCrystal/#{Shatter::VERSION} MSA"},
      form: {
        "client_id"     => APPLICATION_ID,
        "client_secret" => CLIENT_SECRET,
        "refresh_token" => refresh_token,
        "grant_type"    => "refresh_token",
        "redirect_uri"  => REDIRECT_URI,
        "scope"         => "xboxlive.signin",
      }
    # pp! JSON.parse r.body
    AuthorizationToken.from_json r.body
  end

  def xbl(t : AuthorizationToken) : XBLToken
    body = {
      "Properties" => {
        "AuthMethod" => "RPS",
        "SiteName"   => "user.auth.xboxlive.com",
        "RpsTicket"  => "d=#{t.access_token}",
      },
      "RelyingParty" => "http://auth.xboxlive.com",
      "TokenType"    => "JWT",
    }.to_json
    # c = HTTP::Client.new(URI.parse("https://user.auth.xboxlive.com"))
    # c.compress = false
    # c.post("/user/authenticate",
    #   headers: headers,
    #   body: body
    # ) do |r|
    #   pp! r
    #   b = r.body_io.gets_to_end
    #   pp! b
    #   XBLToken.from_json b
    # end
    Process.run("curl", ["-XPOST", "https://user.auth.xboxlive.com/user/authenticate", "-H", "Content-Type: application/json", "-H", "Accept: application/json", "-d", body]) do |p|
      XBLToken.from_json p.output.gets_to_end
    end
  end

  def xsts(t : XBLToken) : XBLToken
    r = HTTP::Client.post("https://xsts.auth.xboxlive.com/xsts/authorize",
      headers: HTTP::Headers{"User-Agent" => "ShatterCrystal/#{Shatter::VERSION} MSA", "Content-Type" => "application/json", "Accept" => "application/json"},
      body: {
        "Properties" => {
          "SandboxId"  => "RETAIL",
          "UserTokens" => [t.token],
        },
        "RelyingParty" => "rp://api.minecraftservices.com/",
        "TokenType"    => "JWT",
      }.to_json)
    # pp! r
    if www_auth = r.headers["WWW-Authenticate"]?
      if www_auth.includes? "XSTS error"
        raise "XSTS: #{www_auth.lchop("XSTS error=\"").rchop("\"")}"
      end
    end
    XBLToken.from_json r.body
  end

  def minecraft(t : XBLToken) : MinecraftToken
    HTTP::Client.post("https://api.minecraftservices.com/authentication/login_with_xbox",
      headers: HTTP::Headers{"User-Agent" => "ShatterCrystal/#{Shatter::VERSION} MSA", "Content-Type" => "application/json", "Accept" => "application/json"},
      body: {
        "identityToken" => "XBL3.0 x=#{t.display_claims[:xui][0][:uhs]};#{t.token}",
      }.to_json
    ) do |r|
      MinecraftToken.from_json r.body_io.gets_to_end
    end
  end

  def profile(t : MinecraftToken) : MinecraftProfile
    HTTP::Client.get("https://api.minecraftservices.com/minecraft/profile",
      headers: HTTP::Headers{
        "User-Agent"    => "ShatterCrystal/#{Shatter::VERSION} MSA",
        "Accept"        => "application/json",
        "Authorization" => "Bearer #{t.access_token}",
      }
    ) do |r|
      MinecraftProfile.from_json r.body_io.gets_to_end
    end
  end
end
