require "uuid"
require "json"

module Shatter::Data
  class Entity
    include JSON::Serializable
    property eid : UInt32
    property uuid : UUID
    property type : String
    property x : Float64
    property y : Float64
    property z : Float64
    property yaw : Float64
    property pitch : Float64
    property head : Float64? = nil
    property data : Int32? = nil
    property vx : Float64
    property vy : Float64
    property vz : Float64
    property player_name : String? = nil
    property properties : Hash(String, Property) = {} of String => Property

    def initialize(@eid, @uuid, @type, @x = 0.0, @y = 0.0, @z = 0.0, @yaw = 0.0, @pitch = 0.0, @head = 0.0, @vx = 0.0, @vy = 0.0, @vz = 0.0)
      # Entity.new(eid, uuid, type, x, y, z, yaw, pitch, head, vx, vy, vz)
    end

    # def initialize(@eid, @uuid, @type, @x0, @y, @z, @yaw, @pitch, @head, @vx, @vy, @vz = 0.0)
    # end

    def initialize(@eid, @uuid, @type, @data : Int32?, @x = 0.0, @y = 0.0, @z = 0.0, @yaw = 0.0, @pitch = 0.0, @vx = 0.0, @vy = 0.0, @vz = 0.0)
    end

    def to_s(io : IO)
      io << "<Ent"
      @eid.to_s io
      io << " "
      io << @type.lchop("minecraft:")
      io << "(" << @player_name << ")" unless @player_name.nil?
      io << ";"
      @uuid.to_s io
      io << ">"
    end

    def inspect(io : IO)
      io << "#<Ent"
      @eid.to_s io
      io << " "
      io << @type.lchop("minecraft:")
      io << "(" << @player_name << ")" unless @player_name.nil?
      io << ";"
      @uuid.to_s io
      io << ";" << @data if @data
      io << "@x" << @x.format(decimal_places: 2, only_significant: true)
      io << ",y" << @y.format(decimal_places: 2, only_significant: true)
      io << ",z" << @z.format(decimal_places: 2, only_significant: true)
      io << ";y" << @yaw.format(decimal_places: 2, only_significant: true)
      io << ",p" << @pitch.format(decimal_places: 2, only_significant: true)
      io << ",h" << @head.not_nil!.format(decimal_places: 2, only_significant: true) if @head
      io << ";vx" << @vx.format(decimal_places: 2, only_significant: true)
      io << ",vy" << @vy.format(decimal_places: 2, only_significant: true)
      io << ",vz" << @vz.format(decimal_places: 2, only_significant: true)
      io << ">"
    end
  end
end

class Shatter::Data::Entity
  enum Status : Int8
    TippedArrowColorParticle =  0
    RabbitRotatedJump        =  1
    LivingHurt               =  2
    LivingDeath              =  3
    Attack                   =  4
    Unknown5                 =  5
    TamingFailed             =  6
    TamingSuccess            =  7
    WolfShakingWater         =  8
    PlayerItemUseFinished    =  9
    SheepEat                 = 10
    IronGolemPoppy           = 11
    VillagerBreed            = 12
    VillagerAngry            = 13
    VillagerHappy            = 14
    WitchMagic               = 15
    ZombieVillagerCured      = 16
    FireworkExplosion        = 17
    AnimalHearts             = 18
    SquidResetRotation       = 19
    SilverfishBlockParticle  = 20
    GuardianAttack           = 21
    PlayerReducedDebug       = 22
    PlayerIncreasedDebug     = 23
    PlayerOp0                = 24
    PlayerOp1                = 25
    PlayerOp2                = 26
    PlayerOp3                = 27
    PlayerOp4                = 28
    ShieldBlock              = 29
    ShieldBreak              = 30
    FishingHookPull          = 31
    ArmorStandHit            = 32
    Thorns                   = 33
    IronGolemStopPoppy       = 34
    TotemOfUndying           = 35
    DrownHurt                = 36
    BurnHurt                 = 37
    DolphinHappy             = 38
    RavagerStunned           = 39
    OcelotTamingFailed       = 40
    OcelotTamingSuccess      = 41
    VillagerSweat            = 42
    PlayerBadOmenTrigger     = 43
    BerryHurt                = 44
    FoxEat                   = 45
    Teleport                 = 46
    MainHandBreak            = 47
    OffHandBreak             = 48
    HelmetBreak              = 49
    ChestplateBreak          = 50
    LeggingsBreak            = 51
    BootsBreak               = 52
    HoneySlide               = 53
    LivingHoneySlide         = 54
    SwapHands                = 55
    WolfStopShake            = 56
    FreezingHurt             = 57
    GoatLowerHead            = 58
    GoatRaiseHead            = 59
    DeathSmoke               = 60
  end

  enum ModifierOperation : Int8
    Add
    AddPercent
    MulPercent
  end

  record Modifier, uuid : UUID, amount : Float64, operation : ModifierOperation do
    def self.from_io(io : IO) : Modifier
      uuid = io.read_uuid
      amount = io.read_f64
      operation = ModifierOperation.new io.read_i8
      Modifier.new(uuid, amount, operation)
    end

    def inspect(io : IO)
      io << "<"
      io << "Modifier "
      @uuid.to_s io
      io << " "
      io << @operation
      io << " "
      io << @amount.format(decimal_places: 2, only_significant: true)
      io << ">"
    end
  end

  record Property, key : String, value : Float64, modifiers : Array(Modifier) do
    def self.from_io(io : IO) : Property
      key = io.read_var_string
      value = io.read_f64
      modifiers = [] of Modifier
      modifier_count = io.read_var_int
      modifier_count.times do
        modifiers << Modifier.from_io io
      end
      Property.new(key, value, modifiers)
    end

    def inspect(io : IO)
      io << "<Property "
      io << @key.lchop("minecraft:")
      io << "="
      io << @value.format(decimal_places: 2, only_significant: true)
      @modifiers.to_s io
      io << ">"
    end
  end
end
