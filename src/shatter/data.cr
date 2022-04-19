require "uuid"
require "nbt"

module Shatter
  def self.var_int(value : UInt32) : Bytes
    a = Array(UInt8).new
    more = true
    while more
      b = (value & 0x7F).to_u8
      value >>= 7
      if value == 0
        more = false
      else
        b |= 0x80
      end

      a << b
    end
    a.to_unsafe.to_slice a.size
  end

  def self.var_int(value : Int32) : Bytes
    var_int(value.to_u32!)
  end

  module Data
    enum InvIdx
      CraftResult
      Craft1
      Craft2
      Craft3
      Craft4
      Helmet
      Chest
      Legs
      Boots
      R1C1
      R1C2
      R1C3
      R1C4
      R1C5
      R1C6
      R1C7
      R1C8
      R1C9
      R2C1
      R2C2
      R2C3
      R2C4
      R2C5
      R2C6
      R2C7
      R2C8
      R2C9
      R3C1
      R3C2
      R3C3
      R3C4
      R3C5
      R3C6
      R3C7
      R3C8
      R3C9
      Hotbar1
      Hotbar2
      Hotbar3
      Hotbar4
      Hotbar5
      Hotbar6
      Hotbar7
      Hotbar8
      Hotbar9
      Offhand
    end
    record Slot, name : String, count : UInt8, nbt : Hash(String, NBT::Tag)? do
      include JSON::Serializable
      def inspect(io : IO)
        io << count << "x " if count != 1
        io << name.lchop "minecraft:"
        io << nbt
      end

      def pretty_print(pp) : Nil
        pp.text "#{count}x " if count != 1
        pp.text name.lchop "minecraft:"
        nbt.pretty_print pp unless nbt.nil?
      end

      def self.from_io(io : IO, con : Shatter::Connection) : Slot?
        has_item = io.read_bool
        if has_item
          item_id = con.registry.item.reverse[io.read_var_int]
          item_count = io.read_u8
          item_nbt = NBT::Reader.new(io).read_named[:tag]
          item_structure = item_nbt.as_h?
          Slot.new(item_id, item_count, item_structure)
        else
          nil
        end
      end
    end
  end
end

struct UInt64
  def as_signed_bit_width(power : Int) : Int64
    if self >= (2 ** (power - 1))
      self.to_i64 - (2 ** power)
    else
      self.to_i64
    end
  end
end

struct UInt32
  def as_signed_bit_width(power : Int) : Int32
    if self >= (2 ** (power - 1))
      self.to_i32 - (2 ** power)
    else
      self.to_i32
    end
  end
end

class IO
  def write_var_int(value : Int32) : Nil
    write Shatter.var_int value
  end

  def write_var_int(value : UInt32) : Nil
    write Shatter.var_int value
  end

  def write_var_string(s : String) : Nil
    write Shatter.var_int s.bytesize
    print s
  end

  def read_var_int : UInt32
    result = 0_u32
    shift = 0
    loop do
      b = read_byte
      return result if b.nil?
      result |= ((0x7F & b).to_u32) << shift
      return result if b & 0x80 == 0
      shift += 7
    end
  end

  def read_var_long : UInt64
    result = 0_u64
    shift = 0
    loop do
      b = read_byte
      return result if b.nil?
      result |= ((0x7F & b).to_u64) << shift
      return result if b & 0x80 == 0
      shift += 7
    end
  end

  def read_var_string : String
    size = read_var_int
    buf = Bytes.new size
    read buf
    return String.new(buf)
  end

  {% for name, type in {
                         i8: Int8, i16: Int16, i32: Int32, i64: Int64,
                         u8: UInt8, u16: UInt16, u32: UInt32, u64: UInt64,
                         f32: Float32, f64: Float64,
                       } %}
    def read_{{name}} : {{type}}
      read_bytes {{type}}, IO::ByteFormat::BigEndian
    end

    def write_{{name}}(i : {{type}}) : Nil
      write_bytes i, IO::ByteFormat::BigEndian
    end
  {% end %}

  def read_bool : Bool
    read_u8 != 0_u8
  end

  def write_bool(i : Bool) : Nil
    write_i8(i ? 1i8 : 0i8)
  end

  def read_angle : Float64
    read_i8 / 256 * 360
  end

  def read_uuid : UUID
    UUID.new read_n_bytes 16
  end

  def read_n_bytes(size : Int) : Bytes
    buffer = Bytes.new size
    read_fully buffer
    buffer
  end

  class WideHexdump < IO
    def initialize(@io : IO, @output : IO = STDERR, @read = false, @write = false)
    end

    def read(buf : Bytes) : Int32
      @io.read(buf).to_i32.tap do |read_bytes|
        buf[0, read_bytes].wide_hexdump(@output) if @read && read_bytes
      end
    end

    def write(buf : Bytes) : Nil
      return if buf.empty?

      @io.write(buf).tap do
        buf.wide_hexdump(@output) if @write
      end
    end

    delegate :peek, :close, :closed?, :flush, :tty?, :pos, :pos=, :seek, to: @io
  end
end

struct Slice(T)
  def wide_hexdump(*, address = 8, sections = 2, prefix = "") : String
    self.as(Slice(UInt8))

    return "" if empty?

    line_size = address + 3 + (33 * sections)
    descriptor_size = (8 * sections)

    full_lines, leftover = size.divmod(descriptor_size)
    if leftover == 0
      str_size = full_lines * (line_size + prefix.size)
    else
      str_size = (full_lines + 1) * (line_size + prefix.size) - (descriptor_size - leftover)
    end

    String.new(str_size) do |buf|
      pos = 0
      offset = 0

      while pos < size
        # Ensure we don't write outside the buffer:
        # slower, but safer (speed is not very important when hexdump is used)
        prefix.to_slice.copy_to Slice.new(buf + offset, { {line_size, str_size - offset}.min, prefix.size }.max)
        offset += prefix.size
        wide_hexdump_line(Slice.new(buf + offset, {line_size, str_size - offset}.min), pos, address: address, sections: sections)
        pos += descriptor_size
        offset += line_size
      end

      {str_size, str_size}
    end
  end

  def wide_hexdump(io : IO)
    self.as(Slice(UInt8))

    return 0 if empty?

    line = uninitialized UInt8[77]
    line_slice = line.to_slice
    count = 0

    pos = 0
    while pos < size
      line_bytes = wide_hexdump_line(line_slice, pos)
      io.write_string(line_slice[0, line_bytes])
      count += line_bytes
      pos += 16
    end

    io.flush
    count
  end

  private def wide_hexdump_line(line, start_pos, *, address = 8, sections = 2)
    hex_offset = address + 2
    ascii_delimiter = hex_offset + (sections * 25)
    ascii_offset = ascii_delimiter

    0.upto(address - 1) do |j|
      line[address - 1 - j] = to_hex((start_pos >> (4 * j)) & 0xf)
    end
    line[address] = 0x20_u8
    line[address + 1] = 0x20_u8

    pos = start_pos
    (sections * 8).times do |i|
      break if pos >= size
      v = unsafe_fetch(pos)
      pos += 1

      line[hex_offset] = to_hex(v >> 4)
      line[hex_offset + 1] = to_hex(v & 0x0f)
      line[hex_offset + 2] = 0x20_u8
      hex_offset += 3

      if i % 8 == 7
        line[hex_offset] = 0x20_u8
        hex_offset += 1
      end

      line[ascii_offset] = 0x20_u8 <= v <= 0x7e_u8 ? v : 0x2e_u8
      ascii_offset += 1
    end

    while hex_offset < ascii_delimiter
      line[hex_offset] = 0x20_u8
      hex_offset += 1
    end

    if ascii_offset < line.size
      line[ascii_offset] = 0x0a_u8
      ascii_offset += 1
    end

    ascii_offset
  end

  private def to_hex(c)
    ((c < 10 ? 48_u8 : 87_u8) + c)
  end
end
