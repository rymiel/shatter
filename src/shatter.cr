require "envy"
Envy.from_file ".env.yaml", perm: 0o400

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
