require "openssl"
require "openssl_ext"

module Shatter::Crypto
  def self.digest : String
    digest = Digest::SHA1.new
    yield digest
    big = BigInt.new(OpenSSL::BN.from_bin(digest.final).to_dec)
    if (big.bit 159) == 1
      "-" + (BigInt.new(big.to_s(2).gsub({'0' => '1', '1' => '0'}), 2) + 1).to_s 16 # wtf
    else
      big.to_s 16
    end
  end

  def self.key_for(asn : Bytes)
    OpenSSL::PKey::RSA.new(IO::Memory.new("-----BEGIN PUBLIC KEY-----\n" + Base64.encode(asn) + "-----END PUBLIC KEY-----\n"))
  end

  class CipherStreamIO < IO
    getter read_cipher : OpenSSL::Cipher
    getter write_cipher : OpenSSL::Cipher

    def initialize(@io : IO, cipher_method : String, iv : Bytes, key : Bytes)
      @read_cipher = OpenSSL::Cipher.new cipher_method
      @read_cipher.decrypt
      @read_cipher.key = key
      @read_cipher.iv = iv
      @write_cipher = OpenSSL::Cipher.new cipher_method
      @write_cipher.encrypt
      @write_cipher.key = key
      @write_cipher.iv = iv
    end

    def read(slice : Bytes)
      upstream_size = @io.read slice
      upstream = slice[0, upstream_size]
      o = @read_cipher.update upstream
      slice.copy_from o
      upstream_size
    end

    def write(slice : Bytes) : Nil
      @io.write @write_cipher.update(slice)
    end
  end
end
