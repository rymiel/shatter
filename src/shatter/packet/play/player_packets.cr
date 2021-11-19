module Shatter::Packet::Play
  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2, transform: {slots: "\n" + @slots.map_with_index { |i, j| {Data::InvIdx.new(j), i} }.to_h.compact.pretty_inspect + "\n"})]
  class WindowItems
    include Packet::Handler

    field window : UInt8
    field state : VarInt
    field slots : Data::Slot?[VarInt]
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
    field worlds : String[VarInt]
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
      con.packet PktId::Sb::Play::PluginMessage do |o|
        o.write_var_string "minecraft:brand"
        o.write "Shatter/#{Shatter::VERSION}".to_slice
      end

      con.packet PktId::Sb::Play::ClientSettings do |o|
        o.write_var_string "SHATTER"
        o.write_i8 2i8
        o.write_var_int 0u32
        o.write_i8 1i8
        o.write_u8 0b01111111u8
        o.write_i8 1i8
        o.write_i8 1i8
      end
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe]
  class KeepAlive
    include Packet::Handler

    field ping_id : Int64

    def run
      con.packet PktId::Sb::Play::KeepAlive do |o|
        o.write_i64 @ping_id
      end
    end
  end
end
