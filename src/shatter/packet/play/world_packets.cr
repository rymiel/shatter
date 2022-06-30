require "../handler"
require "../../chunk"

module Shatter::Packet::Play
  @[Silent]
  # @[Describe(level: 0)]
  class WorldTime
    include Handler

    field age : Int64
    field time_of_day : Int64
  end

  @[Silent]
  # @[Describe]
  class GameState
    include Handler

    field reason : UInt8
    field value : Float32
  end

  @[Silent]
  # @[Describe]
  @[Alias(Chunk)]
  class ChunkPacket
    include Handler

    field chunk_x : Int32
    field chunk_z : Int32
    # field p_bitmask : UInt64[VarInt]
    field heightmap : NBT
    # field biomes : VarInt[VarInt]
    field _data : UInt8[VarInt] -> Slice
    # field data : Chunk = Chunk.new(con, @p_bitmask, @_data)
    # field tiles : NBT[VarInt]
  end

  @[Silent]
  # @[Describe]
  @[Alias(Sound)]
  class SoundPacket
    include Handler

    field id : Sound
    field category : Data::Sound::Category = Data::Sound::Category.new pkt.read_var_int
    field x : Float64 = pkt.read_i32 / 8
    field y : Float64 = pkt.read_i32 / 8
    field z : Float64 = pkt.read_i32 / 8
    field volume : Float32 = pkt.read_f32 * 100
    field pitch : Float32 = pkt.read_f32 * 100
  end
end
