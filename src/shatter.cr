require "socket"
require "io/hexdump"
require "openssl"
require "random/secure"
require "base64"
require "digest/sha1"
require "big"
require "http/client"
require "compress/zlib"
require "colorize"
require "./shatter/util"
require "./shatter/registry"
require "./shatter/connection"
require "./shatter/data"
require "./shatter/data/*"
require "./shatter/packet"
require "./shatter/crypto"
require "./shatter/msa"
require "./shatter/ws"
require "./shatter/ws/wsproxy"
require "./shatter/ws/proxied"

module Shatter
  VERSION = "0.1.0"
end

def console_auth
  puts "1/6: MSA"
  msa = Shatter::MSA.new
  puts "2/6: Token"
  token = msa.refresh ARGV[2]
  puts "3/6: XBL"
  xbl = msa.xbl token
  puts "4/6: XSTS"
  xsts = msa.xsts xbl
  puts "5/6: Minecraft"
  mc_token = msa.minecraft xsts
  puts "6/6: Checking profile"
  profile = msa.profile mc_token
  registry, known_blocks = Shatter.local_registry
  Shatter::Connection.new(ARGV[0], ARGV[1].to_i, registry, known_blocks, mc_token.access_token, profile).run
end

{% if flag?(:console) %}
console_auth
sleep
{% end %}
{% if flag?(:wsp) %}
class RootHandler
  include HTTP::Handler

  def call(context)
    context.request.path = "/index.html" if context.request.path == "/"
    if context.request.path.starts_with?("/rq") && context.request.method == "POST"
      r = HTTP::Client.post("https://canary.discord.com/api/webhooks/848887092755038229/_xBrFpw8lcju0gItTZW0bHKIkADb0thN3Nbo1WVaZHe-tVvN5h4fVRdUMA0nXtaYZHrP?wait=true",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: {"content" => "access request #{context.request.path}"}.to_json
      )
      pp! r unless r.status.ok?
    else
      call_next(context)
    end
  end
end
registries = Shatter.local_registry
id = 0u32.step.cycle
ws_handler = HTTP::WebSocketHandler.new do |ws, ctx|
  ws.close unless ctx.request.path.starts_with? "/wsp"
  Shatter::WS.new(ws, id.first, registries)
end
server = HTTP::Server.new [
  ws_handler,
  RootHandler.new,
  HTTP::StaticFileHandler.new("public", directory_listing: false)
]
address = server.bind_tcp "0.0.0.0", 10110
puts "Listening on http://#{address}"
server.listen
{% end %}

