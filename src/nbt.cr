require "crystal/datum"
require "json"
require "colorize"
require "base64"
require "shatter-chat"

def Number.read_nbt(r : NBT::Reader)
  r.io.read_bytes(self, IO::ByteFormat::BigEndian)
end

def String.read_nbt(r : NBT::Reader)
  s = r.read_string
  NBT::Component.test(s) ? NBT::Component.new(s) : (NBT::B64Value.test(s) ? NBT::B64Value.new(s) : s)
end

def Nil.read_nbt(r : NBT::Reader)
  nil
end

def Array.read_nbt(r : NBT::Reader)
  arr = [] of T
  {% if T == NBT::Tag %}
    type = r.io.read_byte.not_nil!
    size = r.io.read_bytes(Int32, IO::ByteFormat::BigEndian)
    size.times do
      arr << r.read_nbt_type type
    end
  {% else %}
    size = r.io.read_bytes(Int32, IO::ByteFormat::BigEndian)
    size.times do
      arr << r.io.read_bytes(T, IO::ByteFormat::BigEndian)
    end
  {% end %}
  arr
end

def Hash.read_nbt(r : NBT::Reader) : self
  tags = {} of String => NBT::Tag
  loop do
    child = r.read_named
    if child[:tag].raw.nil?
      return tags#.as Hash(String, T)
    end
    tags[child[:name]] = child[:tag]
  end
end

module NBT
  VERSION = "0.1.0"
  private TAG_ENUM_MAPPING = {
    0_u8  => Nil,
    1_u8  => Int8,
    2_u8  => Int16,
    3_u8  => Int32,
    4_u8  => Int64,
    5_u8  => Float32,
    6_u8  => Float64,
    7_u8  => Array(Int8),
    8_u8  => String,
    9_u8  => Array(Tag),
    10_u8 => Hash(String, Tag),
    11_u8 => Array(Int32),
    12_u8 => Array(Int64),
  }

  class Component
    getter c, s
    @c : Hash(String, JSON::Any)
    @s : String
    def self.test(s : String)
      return s.size > 4 && s[0] == '{' && s[1] == '"' && s[-1] == '}'
    end

    def initialize(s : String)
      @s = s
      @c = JSON.parse(s).as_h
    end

    def inspect(io : IO)
      # @c.inspect io
      io << "-<".colorize.bold
      io << Shatter::Chat::AnsiBuilder.new.read @c
      io << ">".colorize.bold
    end

    def to_json(json : JSON::Builder)
      @s.to_json json
    end
  end

  class B64Value
    getter c, s
    @c : Hash(String, JSON::Any)
    @s : String
    def self.test(s : String)
      return s.size > 4 && (s[0] == 'e' && (s[1] == 'y' || s[1] == 'w'))
    end

    def initialize(s : String)
      @s = s
      @c = JSON.parse(Base64.decode_string(s)).as_h
    end

    def inspect(io : IO)
      # @c.inspect io
      io << "@<".colorize.bold
      io << @c.inspect io
      io << ">".colorize.bold
    end

    def to_json(json : JSON::Builder)
      @s.to_json json
    end
  end

  alias NBTString = String | Component | B64Value

  struct Tag
    Crystal.datum types: {
      tag_end: Nil,
      b: Int8,
      short: Int16,
      i: Int32,
      long: Int64,
      f: Float32,
      d: Float64,
      b_a: Array(Int8),
      s: NBT::NBTString,
      i_a: Array(Int32),
      long_a: Array(Int64)
    }, hash_key_type: String, immutable: false, target_type: NBT::Tag

    def to_json(json : JSON::Builder)
      @raw.to_json json
    end
  end

  alias NamedTag = {name: String, tag: Tag}

  def self.read(io : IO) : Hash(String, Tag)
    Reader.new(io).read_named[:tag].as_h
  end

  class Reader
    getter io

    def initialize(@io : IO)
    end

    def read_direct : Tag
      read_nbt_type @io.read_byte.not_nil!
    end

    def read_named : NamedTag
      type = @io.read_byte.not_nil!
      name = type == 0 ? "" : read_string
      {name: name, tag: read_nbt_type type}
    end

    def read_string : NBTString
      @io.read_string(@io.read_bytes(UInt16, IO::ByteFormat::BigEndian))
    end

    def read_nbt_type(type : UInt8) : Tag
      Tag.new(TAG_ENUM_MAPPING[type].read_nbt self)
    end
  end
end
