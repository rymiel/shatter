module Shatter::Packet::Play
  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2, transform: {slots: "\n" + @slots.map_with_index{|i, j| {Data::InvIdx.new(j), i}}.to_h.compact.pretty_inspect + "\n"})]
  class WindowItems
    include Packet::Handler

    field window : UInt8
    field state : VarInt
    array_field slots : Data::Slot?, count: VarInt
    field carried : Data::Slot?
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2, transform: {codec: "#{@codec.inspect.size} chars of nope", dimension: "#{@dimension.inspect.size} chars of nope"})]
  class JoinGame
    include Packet::Handler

    field my_eid : UInt32
    field hardcore : Bool
    field gamemode : Data::Player::Gamemode = Data::Player::Gamemode.new(pkt.read_u8.to_i32)
    field prev_gamemode : Data::Player::Gamemode? do
      x = pkt.read_i8.to_i32
      x < 0 ? nil : Data::Player::Gamemode.new(x)
    end
    array_field worlds : String, count: VarInt
    field codec : NBT
    field dimension : NBT
    field world : String
    field hash_seed : UInt64
    field max_players : VarInt
    field view_distance : VarInt
    field reduced_debug : Bool
    field has_respawn : Bool
    field is_debug : Bool
    field is_flat : Bool
    
    def run
      my_uuid = UUID.new(con.profile.id)
      con.entities[my_eid] = Data::Entity.new my_eid, UUID.new(con.profile.id), "minecraft:player"
      con.players[my_uuid].name = con.profile.name
    end
  end
end