require "../handler"

module Shatter::Packet::Play
  @[Silent]
  @[Describe(level: 2, transform: {slots: "\n" + @slots.map_with_index { |i, j| {Data::InvIdx.new(j), i} }.to_h.compact.pretty_inspect + "\n"})]
  class WindowItems
    include Handler

    field window : UInt8
    field state : VarInt
    field slots : Data::Slot?[VarInt]
    field carried : Data::Slot?
  end

  @[Silent]
  @[Describe(level: 2, transform: {codec: "#{@codec.inspect.size} chars of nope", dimension: "#{@dimension.inspect.size} chars of nope"})]
  class JoinGame
    include Handler

    field my_eid : UInt32
    field hardcore : Bool
    field gamemode : Data::Player::Gamemode = Data::Player::Gamemode.new(pkt.read_i8)
    field prev_gamemode : Data::Player::Gamemode? do
      x = pkt.read_i8
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
      con.packet Sb::Play::PluginMessage do |o|
        o.write_var_string "minecraft:brand"
        o.write "Shatter/#{Shatter::VERSION}".to_slice
      end

      con.packet Sb::Play::ClientSettings do |o|
        o.write_var_string "SHATTER"
        o.write_i8 2i8
        o.write_var_int 0u32
        o.write_bool true
        o.write_u8 0b01111111u8
        o.write_bool true
        o.write_bool true
        o.write_bool true if con.protocol >= Protocol::Version1_18_1::PROTOCOL_VERSION
      end
    end
  end

  @[Silent]
  @[Describe]
  class KeepAlive
    include Handler

    field ping_id : Int64

    def run
      con.packet Sb::Play::KeepAlive do |o|
        o.write_i64 @ping_id
      end
    end
  end

  @[Silent]
  @[Describe(transform: {
    action_id: ["Add", "Gamemode", "Ping", "Display name", "Remove"][@action_id],
    actions:   @actions.map { |k, v| v.nil? ? con.players[k].name : "#{con.players[k].name} => #{v.to_s k}" }.join ", ",
  })]
  class PlayInfo
    private PLAY_INFO_FIELDS = {
      "name"  => {String, pkt.read_var_string},
      "props" => {Hash(String, {String, String?}), begin
        props = Hash(String, {String, String?}).new
        (pkt.read_var_int).times do
          key = pkt.read_var_string
          props[key] = {pkt.read_var_string, pkt.read_bool ? pkt.read_var_string : nil}
        end
        props
      end},
      "gamemode"     => {Data::Player::Gamemode, Data::Player::Gamemode.new(pkt.read_var_int.to_i8)},
      "ping"         => {UInt32, pkt.read_var_int},
      "display_name" => {ChatContainer?, pkt.read_bool ? ChatContainer.new(pkt.read_var_string) : nil},
    }

    macro fields(c, f = [] of Nil, r = nil, s = nil)
      class {{c}}
        include JSON::Serializable
        {% for i in f %}
          @{{i.id}} : {{PLAY_INFO_FIELDS[i.id.stringify][0]}}
        {% end %}
        def initialize(uuid, pkt, con)
          {% for i in f %}
            @{{i.id}} = {{PLAY_INFO_FIELDS[i.id.stringify][1]}}
          {% end %}
          {% unless r.nil? %}{{ r }}{% end %}
        end
        {% if s %}
          def to_s(uuid : UUID)
            {{ s }}
          end
        {% end %}
      end
    end

    PlayInfo.fields ActionNew, [:name, :props, :gamemode, :ping, :display_name],
      con.players[uuid] = Data::Player.new(uuid, @name, @props, @gamemode, @ping, @display_name),
      "#{uuid}#{@display_name.nil? ? "" : " as #{@display_name}"};#{@gamemode};#{@ping} ms;props[#{@props.keys.join ", "}]"
    PlayInfo.fields ActionGameMode, [:gamemode],
      con.players[uuid].gamemode = Data::Player::Gamemode.new(@gamemode), @gamemode
    PlayInfo.fields ActionDisplayName, [:display_name],
      con.players[uuid].display_name = @display_name, @display_name
    PlayInfo.fields ActionPing, [:ping], con.players[uuid].ping = @ping, "#{@ping}ms"
    PlayInfo.fields ActionRemove, s: "Removed"

    alias Action = ActionNew | ActionGameMode | ActionDisplayName | ActionPing | ActionRemove

    include Handler

    field action_id : VarInt
    field actions : {UUID, Play::PlayInfo::Action}[VarInt] do
      uuid = pkt.read_uuid
      action = case @action_id
               when 0 then Play::PlayInfo::ActionNew.new uuid, pkt, con
               when 1 then Play::PlayInfo::ActionGameMode.new uuid, pkt, con
               when 2 then Play::PlayInfo::ActionPing.new uuid, pkt, con
               when 3 then Play::PlayInfo::ActionDisplayName.new uuid, pkt, con
               when 4 then Play::PlayInfo::ActionRemove.new uuid, pkt, con
               else        raise "Invalid PlayInfoAction type #{@action_id}"
               end
      {uuid, action}
    end
  end
end
