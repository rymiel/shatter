require "json"
require "nbt"

class Shatter::Data::Chunk
  include JSON::Serializable

  class Tile
    include JSON::Serializable

    getter xz : UInt8
    getter y : UInt16
    getter type : UInt32
    getter data : NBT::Tag

    def initialize(source : IO)
      @xz = source.read_u8
      @y = source.read_u16
      @type = source.read_var_int
      @data = NBT::Reader.new(source).read_named[:tag]
    end
  end

  class Section117
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

  class Section119
    include JSON::Serializable

    class PaletteContainer
      include JSON::Serializable
      getter bits_per_block : UInt8
      getter palette : Array(String)?
      getter data : Array(UInt64)

      def initialize(is_biome, con : Shatter::Connection, source : IO::Memory)
        @bits_per_block = source.read_u8
        if @bits_per_block == 0
          @palette = [is_biome ? "Biome #{source.read_var_int}" : con.block_states[source.read_var_int]]
        elsif @bits_per_block < (is_biome ? 4 : 9)
          @bits_per_block = 4 if @bits_per_block <= 4 && !is_biome
          @palette = Array(String).new(source.read_var_int) do
            is_biome ? "Biome #{source.read_var_int}" : con.block_states[source.read_var_int]
          end
        else
          @palette = nil # "Direct" palette, not encountered in vanilla so not implemented here
        end

        @data = Array(UInt64).new(source.read_var_int) { source.read_u64 }
      end

      def to_s(io : IO)
        if bits_per_block == 0
          io << "Single PaletteContainer filled with #{palette.not_nil!.first.lchop("minecraft:")}"
          return
        end

        bpb_mask = 2 ** @bits_per_block - 1
        block_per_long = 64 // @bits_per_block
        is_compact = (palette.try(&.size) || 0) <= 16
        nums_per_block = is_compact ? 1 : 2
        longs_per_line = is_compact ? 16 : 8

        io << "PaletteContainer #{@bits_per_block}bpb (#{block_per_long}bpl, 0b#{bpb_mask.to_s 2}) [\n"
        io << "    Palette {"
        palette.try &.each_with_index do |i, j|
          io << ", " if j != 0
          io << "#{j.to_s 16}:#{i.lchop("minecraft:")}"
        end
        io << "}"
        data.each_with_index do |i, j|
          io << (j % longs_per_line == 0 ? "\n   |" : "  ")
          t = i
          block_indices = Array(String).new
          block_per_long.times do
            block_indices << (t & bpb_mask).to_s(16).rjust(nums_per_block, '0')
            t >>= @bits_per_block
          end

          if is_compact
            block_indices.reverse.join io, ""
          else
            block_indices.reverse.join io, ' '
          end
        end
        io << "\n]"
      end
    end

    getter block_count : UInt16
    getter blocks : PaletteContainer
    getter biomes : PaletteContainer

    def initialize(con : Shatter::Connection, source : IO::Memory)
      @block_count = source.read_u16
      @blocks = PaletteContainer.new false, con, source
      @biomes = PaletteContainer.new true, con, source
    end

    def to_s(io : IO)
      io << "Chunk::Section of #{block_count} blocks: {\n"
      io << "  Blocks "
      blocks.to_s io
      io << "\n  Biomes "
      biomes.to_s io
      io << "\n}"
    end
  end

  getter sections : Array(Section117) | Array(Section119)

  def initialize(con : Shatter::Connection, primary_bitmask : Array(UInt64), array : Bytes)
    section_count = primary_bitmask.sum &.popcount
    source = IO::Memory.new(array)

    @sections = Array(Section117).new section_count do
      Section117.new con, source
    end
  end

  def initialize(con : Shatter::Connection, array : Bytes)
    source = IO::Memory.new(array)

    sections = Array(Section119).new
    until source.pos == source.size # TODO: Apparently the amount of sections to be read from the world height from the dimension codec
      sections << Section119.new con, source
    end
    @sections = sections
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
