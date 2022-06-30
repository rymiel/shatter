require "json"

class Shatter::Chunk
  include JSON::Serializable

  class Section
    include JSON::Serializable
    getter block_count : UInt16
    getter bits_per_block : UInt8
    getter palette : Array(String)?
    getter compacted_data : Array(UInt64)

    def initialize(con : Shatter::Connection, source : IO::Memory)
      @block_count = source.read_u16
      @bits_per_block = source.read_u8
      @palette = @bits_per_block >= 9 ? nil : Array(String).new(source.read_var_int) { con.block_states[source.read_var_int] }
      @compacted_data = Array(UInt64).new(source.read_var_int) { source.read_u64 }
    end

    def to_s(io : IO)
      bpb_mask = 2 ** @bits_per_block - 1
      block_per_long = 64 // @bits_per_block
      io << "Chunk::Section of #{block_count} blocks, #{@bits_per_block}bpb (#{block_per_long}bpl, 0b#{bpb_mask.to_s 2}) [\n"
      io << "    Palette {"
      palette.try &.each_with_index do |i, j|
        io << ", " if j != 0
        io << "#{j}:#{i.lchop("minecraft:")}"
      end
      io << "}"
      compacted_data.each_with_index do |i, j|
        io << (j % 2 == 0 ? "\n   |" : "  ")
        t = i
        block_indices = Array(String).new
        block_per_long.times do
          block_indices << (t & bpb_mask).to_s.rjust(2, '0')
          t >>= @bits_per_block
        end
        block_indices.reverse.join io, ' '
      end
      io << "\n]"
    end
  end

  getter sections : Array(Section)

  def initialize(con : Shatter::Connection, primary_bitmask : Array(UInt64), array : Bytes)
    section_count = primary_bitmask.sum &.popcount
    source = IO::Memory.new(array)

    @sections = Array(Section).new section_count do
      Section.new con, source
    end
  end

  def to_s(io : IO)
    io << "Chunk["
    @sections.each_with_index do |i, j|
      io << (j == 0 ? "\n  " : ",\n  ")
      i.to_s io
    end
    io << "\n]"
  end
end
