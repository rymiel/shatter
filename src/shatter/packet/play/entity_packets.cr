module Shatter::Packet::Play
  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class EntityHeadLook
    include Packet::Handler

    field ent : Entity
    field head : Angle

    def run
      @ent.head = @head
    end
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class EntityPosition
    include Packet::Handler

    field ent : Entity
    field dx : Float64 = pkt.read_i16 / (128 * 32)
    field dy : Float64 = pkt.read_i16 / (128 * 32)
    field dz : Float64 = pkt.read_i16 / (128 * 32)
    field on_ground : Bool

    def run
      @ent.x += @dx
      @ent.y += @dy
      @ent.z += @dz
    end
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class EntityVelocity
    include Packet::Handler

    field ent : Entity
    field vx : Velocity
    field vy : Velocity
    field vz : Velocity

    def run
      @ent.vx = @vx
      @ent.vy = @vy
      @ent.vz = @vz
    end
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class EntityPosRot
    include Packet::Handler

    field ent : Entity
    field dx : Float64 = pkt.read_i16 / (128 * 32)
    field dy : Float64 = pkt.read_i16 / (128 * 32)
    field dz : Float64 = pkt.read_i16 / (128 * 32)
    field yaw : Angle
    field pitch : Angle
    field on_ground : Bool

    def run
      @ent.x += @dx
      @ent.y += @dy
      @ent.z += @dz
      @ent.yaw = @yaw
      @ent.pitch = @pitch
    end
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class EntityTeleport
    include Packet::Handler

    field ent : Entity
    field x : Float64
    field y : Float64
    field z : Float64
    field yaw : Angle
    field pitch : Angle
    field on_ground : Bool

    def run
      @ent.x = @x
      @ent.y = @y
      @ent.z = @z
      @ent.yaw = @yaw
      @ent.pitch = @pitch
    end
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 0)]
  class EntityRotation
    include Packet::Handler

    field ent : Entity
    field yaw : Angle
    field pitch : Angle
    field on_ground : Bool

    def run
      @ent.yaw = @yaw
      @ent.pitch = @pitch
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 4)]
  class EntityStatus
    include Packet::Handler

    field ent : Entity = con.entities[pkt.read_u32]
    field status : Data::Entity::Status = Data::Entity::Status.new pkt.read_u8.to_i32
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe(level: 3)]
  class DestroyEntity
    include Packet::Handler

    array_field entities : Entity, count: VarInt
  end

  @[Shatter::Packet::Silent]
  # @[Shatter::Packet::Describe]
  class SpawnLiving
    include Packet::Handler

    field eid : VarInt
    field uuid : UUID
    field type : EntityType
    field x : Float64
    field y : Float64
    field z : Float64
    field yaw : Angle
    field pitch : Angle
    field head : Angle
    field vx : Velocity
    field vy : Velocity
    field vz : Velocity

    def run
      con.entities[@eid] = Data::Entity.new @eid, @uuid, @type, @x, @y, @z, @yaw, @pitch, @head, @vx, @vy, @vz
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe]
  class SpawnEntity
    include Packet::Handler

    field eid : VarInt
    field uuid : UUID
    field type : EntityType
    field x : Float64
    field y : Float64
    field z : Float64
    field yaw : Angle
    field pitch : Angle
    field data : Int32
    field vx : Velocity
    field vy : Velocity
    field vz : Velocity

    def run
      con.entities[@eid] = Data::Entity.new @eid, @uuid, @type, @data, @x, @y, @z, @yaw, @pitch, @vx, @vy, @vz
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe]
  class SpawnPlayer
    include Packet::Handler

    field eid : VarInt
    field uuid : UUID
    field x : Float64
    field y : Float64
    field z : Float64
    field yaw : Angle
    field pitch : Angle

    def run
      con.entities[@eid] = Data::Entity.new @eid, @uuid, "minecraft:player", @x, @y, @z, @yaw, @pitch
      con.entities[@eid].player_name = con.players[@uuid].name
    end
  end

  @[Shatter::Packet::Silent]
  @[Shatter::Packet::Describe(level: 2)]
  class Equipment
    include Packet::Handler

    enum InSlot
      MainHand
      OffHand
      Boots
      Leggings
      Chestplate
      Helmet
    end

    field ent : Entity
    field equipment : Hash(InSlot, Data::Slot?) do
      has_more = true
      arr = Array({Play::Equipment::InSlot, Data::Slot?}).new
      while has_more
        slot_indicator = pkt.read_u8
        has_more = slot_indicator & 0b1000_0000 > 0
        in_slot = Play::Equipment::InSlot.new (slot_indicator & 0b0111_1111).to_i32
        item = Data::Slot.from_io pkt, con
        arr << {in_slot, item}
      end
      arr.to_h
    end
  end
end
