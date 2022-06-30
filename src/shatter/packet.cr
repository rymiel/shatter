require "./data/entity"
require "./data/player"
require "./data/sound"
require "./packet/protocol"
require "./packet/handler"
require "shatter-chat"
require "json"

module Shatter::Packet
  enum State
    Handshake
    Status
    Login
    Play
  end

  CB_STATE_MAP = {
    State::Login  => Cb::Login,
    State::Play   => Cb::Play,
    State::Status => Cb::Status,
  }

  alias HandlerProc = (IO, Connection) -> Handler?

  PACKET_HANDLERS = Hash(Cb::Any, Array(HandlerProc)).new { |h, k| h[k] = [] of HandlerProc }
  SILENT          = Hash(Cb::Any, Bool).new

  module Sb
    enum Handshake
      Handshake = 0x00
    end

    enum Status
      Request = 0x00
    end

    enum Login
      LoginStart    = 0x00
      CryptResponse = 0x01
    end

    enum Play
      Chat
      ClientSettings
      PluginMessage
      KeepAlive
    end
  end

  module Cb
    enum Login
      Disconnect     = 0x00
      CryptRequest   = 0x01
      LoginSuccess   = 0x02
      SetCompression = 0x03
    end

    enum Status
      Response = 0x00
    end

    enum Play
      SpawnEntity
      SpawnXpOrb
      SpawnLiving
      SpawnPainting
      SpawnPlayer
      SculkVibration
      EntityAnimation
      Statistics
      DigAck
      BreakAnimation
      TileData
      BlockAction
      BlockChange
      BossBar
      Difficulty
      Chat
      ClearTitle
      TabComplete
      Commands
      CloseWindow
      WindowItems
      WindowProp
      Slot
      Cooldown
      PluginMessage
      NamedSound
      Disconnect
      EntityStatus
      Explosion
      UnloadChunk
      GameState
      HorseWindow
      WorldBorder
      KeepAlive
      Chunk
      Effect
      Particle
      Light
      JoinGame
      Map
      Trades
      EntityPosition
      EntityPosRot
      EntityRotation
      VehicleMove
      OpenBook
      OpenWindow
      EditSign
      Ping
      RecipeResponse
      Abilities
      EndCombat
      EnterCombat
      Death
      PlayInfo
      FacePlayer
      PlayerPosLook
      UnlockRecipes
      DestroyEntity
      RemoveEffect
      ResourcePack
      Respawn
      EntityHeadLook
      MultiBlocks
      AdvancementTab
      ActionBar
      BorderCenter
      BorderLerp
      BorderSize
      BorderWarnTime
      BorderWarnReach
      Camera
      HeldItem
      ViewPosition
      ViewDistance
      SpawnPoint
      Scoreboard
      EntityMeta
      AttachEntity
      EntityVelocity
      Equipment
      SetXp
      Health
      Objective
      Passengers
      Team
      Score
      Subtitle
      WorldTime
      Title
      TitleTimes
      EntitySound
      Sound
      StopSound
      HeaderFooter
      NBTQuery
      CollectItem
      EntityTeleport
      Advancements
      EntityProp
      PotionEffect
      Recipes
      Tags
      SimulationDistance

      ServerData
      SystemChat
      PlayerChat
      ChatPreview
      ToggleChatPreview
    end

    alias Any = Login | Status | Play

    IGNORE = [
      Play::Light, Play::Commands, Play::Recipes, Play::Map, Play::Advancements, Play::Tags, Play::UnlockRecipes, Play::HeaderFooter,
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
  end
end
