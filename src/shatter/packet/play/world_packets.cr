require "../handler"
require "../../data/chunk"

module Shatter::Packet::Play
  @[Describe(0, time, default: false)]
  class WorldTime
    include Handler

    field age : Int64
    field time_of_day : Int64
  end

  @[Describe(0, state, default: false)]
  class GameState
    include Handler

    field reason : UInt8
    field value : Float32
  end

  @[Alias(Chunk)]
  @[Version(:==, Protocol::Version1_17_1::PROTOCOL_VERSION)]
  @[Describe(0, chunk, default: false)]
  class ChunkPacket1171
    include Handler

    field chunk_x : Int32
    field chunk_z : Int32
    field p_bitmask : UInt64[VarInt]
    field heightmap : NBT
    field biomes : VarInt[VarInt]
    field _data : UInt8[VarInt] -> Slice
    field data : Data::Chunk = Data::Chunk.new(con, @p_bitmask, @_data)
    field tiles : NBT[VarInt]
  end

  @[Alias(Chunk)]
  @[Version(:==, Protocol::Version1_19::PROTOCOL_VERSION)]
  @[Describe(0, chunk, default: false)]
  class ChunkPacket119
    include Handler

    record Tile, xz : UInt8, y : UInt16, type : VarInt, data : NBT

    field chunk_x : Int32
    field chunk_z : Int32
    field heightmap : NBT
    field _data : UInt8[VarInt] -> Slice
    field data : Data::Chunk = Data::Chunk.new(con, @_data)
    field tiles : Data::Chunk::Tile[VarInt]
  end

  @[Alias(Sound)]
  @[Describe(0, sound)]
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
