require "./data/entity"
require "./data/player"
require "./data/sound"
require "./packet/handler"
require "./packet/login/*"
require "./packet/play/*"
require "shatter-chat"
require "json"

module Shatter::PktId
  enum State
    Handshake
    Login
    Play
  end

  CB_STATE_MAP = {
    State::Login => Cb::Login,
    State::Play  => Cb::Play,
  }

  PACKET_HANDLERS = {} of (Cb::Login | Cb::Play) => ((IO, Connection) -> Packet::Handler)
  SILENT = {} of (Cb::Login | Cb::Play) => Bool

  module Sb
    enum Handshake
      Handshake = 0x00
    end

    enum Login
      LoginStart    = 0x00
      CryptResponse = 0x01
    end

    enum Play
      Chat           = 0x03
      ClientSettings = 0x05
      PluginMessage  = 0x0A
      KeepAlive      = 0x0F
    end
  end

  module Cb
    enum Login
      Disconnect     = 0x00
      CryptRequest   = 0x01
      LoginSuccess   = 0x02
      SetCompression = 0x03
    end

    enum Play
      SpawnEntity     = 0x00
      SpawnXpOrb      = 0x01
      SpawnLiving     = 0x02
      SpawnPainting   = 0x03
      SpawnPlayer     = 0x04
      SculkVibration  = 0x05
      EntityAnimation = 0x06
      Statistics      = 0x07
      DigAck          = 0x08
      BreakAnimation  = 0x09
      TileData        = 0x0A
      BlockAction     = 0x0B
      BlockChange     = 0x0C
      BossBar         = 0x0D
      Difficulty      = 0x0E
      Chat            = 0x0F
      ClearTitle      = 0x10
      TabComplete     = 0x11
      Commands        = 0x12
      CloseWindow     = 0x13
      WindowItems     = 0x14
      WindowProp      = 0x15
      Slot            = 0x16
      Cooldown        = 0x17
      PluginMessage   = 0x18
      NamedSound      = 0x19
      Disconnect      = 0x1A
      EntityStatus    = 0x1B
      Explosion       = 0x1C
      UnloadChunk     = 0x1D
      GameState       = 0x1E
      HorseWindow     = 0x1F
      WorldBorder     = 0x20
      KeepAlive       = 0x21
      Chunk           = 0x22
      Effect          = 0x23
      Particle        = 0x24
      Light           = 0x25
      JoinGame        = 0x26
      Map             = 0x27
      Trades          = 0x28
      EntityPosition  = 0x29
      EntityPosRot    = 0x2A
      EntityRotation  = 0x2B
      VehicleMove     = 0x2C
      OpenBook        = 0x2D
      OpenWindow      = 0x2E
      EditSign        = 0x2F
      Ping            = 0x30
      RecipeResponse  = 0x31
      Abilities       = 0x32
      EndCombat       = 0x33
      EnterCombat     = 0x34
      Death           = 0x35
      PlayInfo        = 0x36
      FacePlayer      = 0x37
      PlayerPosLook   = 0x38
      UnlockRecipes   = 0x39
      DestroyEntity   = 0x3A
      RemoveEffect    = 0x3B
      ResourcePack    = 0x3C
      Respawn         = 0x3D
      EntityHeadLook  = 0x3E
      MultiBlocks     = 0x3F
      AdvancementTab  = 0x40
      ActionBar       = 0x41
      BorderCenter    = 0x42
      BorderLerp      = 0x43
      BorderSize      = 0x44
      BorderWarnTime  = 0x45
      BorderWarnReach = 0x46
      Camera          = 0x47
      HeldItem        = 0x48
      ViewPosition    = 0x49
      ViewDistance    = 0x4A
      SpawnPoint      = 0x4B
      Scoreboard      = 0x4C
      EntityMeta      = 0x4D
      AttachEntity    = 0x4E
      EntityVelocity  = 0x4F
      Equipment       = 0x50
      SetXp           = 0x51
      Health          = 0x52
      Objective       = 0x53
      Passengers      = 0x54
      Team            = 0x55
      Score           = 0x56
      Subtitle        = 0x57
      WorldTime       = 0x58
      Title           = 0x59
      TitleTimes      = 0x5A
      EntitySound     = 0x5B
      Sound           = 0x5C
      StopSound       = 0x5D
      HeaderFooter    = 0x5E
      NBTQuery        = 0x5F
      CollectItem     = 0x60
      EntityTeleport  = 0x61
      Advancements    = 0x62
      EntityProp      = 0x63
      PotionEffect    = 0x64
      Recipes         = 0x65
      Tags            = 0x66
    end

    IGNORE = [
      Play::Light, Play::Commands, Play::Recipes, Play::Map, Play::Advancements, Play::Tags, Play::UnlockRecipes, Play::HeaderFooter, Play::EntityMeta, Play::PlayInfo, Play::EntityProp
    ]

    # silent_packet_handler Play::EntityProp do |pkt, con|
    #   entity = con.entities[pkt.read_var_int]
    #   properties = [] of Data::Entity::Property
    #   property_count = pkt.read_var_int
    #   property_count.times do
    #     properties << Data::Entity::Property.from_io pkt
    #   end
    #   # describe_packet EntityProp, entity, properties
    # end

    # silent_packet_handler Play::PlayInfo do |pkt, con|
    #   action_id = pkt.read_var_int
    #   action = ["Add", "Gamemode", "Ping", "Display name", "Remove"][action_id]
    #   description = {} of UUID => String?
    #   (pkt.read_var_int).times do
    #     uuid = pkt.read_uuid
    #     case action_id
    #     when 0
    #       name = pkt.read_var_string
    #       props = Hash(String, {String, String?}).new
    #       (pkt.read_var_int).times do
    #         key = pkt.read_var_string
    #         value = pkt.read_var_string
    #         is_signed = pkt.read_bool
    #         signature = is_signed ? pkt.read_var_string : nil
    #         props[key] = {value, signature}
    #       end
    #       gamemode = Data::Player::Gamemode.new(pkt.read_var_int.to_i32)
    #       ping = pkt.read_var_int
    #       display_name = pkt.read_bool ? Chat::AnsiBuilder.new.read(JSON.parse(pkt.read_var_string).as_h) : nil
    #       con.players[uuid] = Data::Player.new(uuid, name, props, gamemode, ping, display_name)
    #       description[uuid] = "#{uuid}#{display_name.nil? ? "" : " as #{display_name}"};#{gamemode};#{ping} ms;props[#{props.keys.join ", "}]"
    #     when 1
    #       new_gamemode = pkt.read_var_int.to_i32
    #       con.players[uuid].gamemode = Data::Player::Gamemode.new(new_gamemode)
    #       description[uuid] = new_gamemode.to_s
    #     when 2
    #       new_ping = pkt.read_var_int
    #       con.players[uuid].ping = new_ping
    #       description[uuid] = "#{new_ping}ms"
    #     when 3
    #       new_display_name = pkt.read_bool ? Chat::AnsiBuilder.new.read(JSON.parse(pkt.read_var_string).as_h) : nil
    #       con.players[uuid].display_name = new_display_name
    #       description[uuid] = new_display_name
    #     when 4 then description[uuid] = nil
    #     end
    #   end
    #   description_map = description.map { |k, v| v.nil? ? con.players[k].name : "#{con.players[k].name} => #{v}" }.join ", "
    #   action = "#{action}{#{description_map}}"
    #   describe_packet PlayInfo, action
    # end
  end
end
