require "../../chunk"

module Shatter::Packet::Play
  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class WorldTime
    include Packet::Handler

    field age : Int64
    field time_of_day : Int64
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe]
  class GameState
    include Packet::Handler

    field reason : UInt8
    field value : Float32
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe]
  @[Shatter::Packet::Alias(Chunk)]
  class ChunkPacket
    include Packet::Handler

    field chunk_x : Int32
    field chunk_z : Int32
    array_field p_bitmask : UInt64, count: VarInt
    field heightmap : NBT
    array_field biomes : VarInt, count: VarInt
    array_field _data : UInt8, count: VarInt, array_type: Slice
    field data : Chunk = Chunk.new(con, @p_bitmask, @_data)
    array_field tiles : NBT, count: VarInt
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe]
  @[Shatter::Packet::Alias(Sound)]
  class SoundPacket
    include Packet::Handler

    field id : Sound
    field category : Data::Sound::Category = Data::Sound::Category.new pkt.read_var_int.to_i32
    field x : Float64 = pkt.read_i32 / 8
    field y : Float64 = pkt.read_i32 / 8
    field z : Float64 = pkt.read_i32 / 8
    field volume : Float32 = pkt.read_f32 * 100
    field pitch : Float32 = pkt.read_f32 * 100
  end
end
