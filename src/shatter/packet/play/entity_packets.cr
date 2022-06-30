require "../handler"

module Shatter::Packet::Play
  @[Silent]
  @[Describe(level: 0, tag: :movement)]
  class EntityHeadLook
    include Handler

    field ent : Entity
    field head : Angle

    def run(con)
      @ent.head = @head
    end
  end

  @[Silent]
  @[Describe(level: 0, tag: :movement)]
  class EntityPosition
    include Handler

    field ent : Entity
    field dx : Float64 = pkt.read_i16 / (128 * 32)
    field dy : Float64 = pkt.read_i16 / (128 * 32)
    field dz : Float64 = pkt.read_i16 / (128 * 32)
    field on_ground : Bool

    def run(con)
      @ent.x += @dx
      @ent.y += @dy
      @ent.z += @dz
    end
  end

  @[Silent]
  @[Describe(level: 0, tag: :movement)]
  class EntityVelocity
    include Handler

    field ent : Entity
    field vx : Velocity
    field vy : Velocity
    field vz : Velocity

    def run(con)
      @ent.vx = @vx
      @ent.vy = @vy
      @ent.vz = @vz
    end
  end

  @[Silent]
  @[Describe(level: 0, tag: :movement)]
  class EntityPosRot
    include Handler

    field ent : Entity
    field dx : Float64 = pkt.read_i16 / (128 * 32)
    field dy : Float64 = pkt.read_i16 / (128 * 32)
    field dz : Float64 = pkt.read_i16 / (128 * 32)
    field yaw : Angle
    field pitch : Angle
    field on_ground : Bool

    def run(con)
      @ent.x += @dx
      @ent.y += @dy
      @ent.z += @dz
      @ent.yaw = @yaw
      @ent.pitch = @pitch
    end
  end

  @[Silent]
  @[Describe(level: 0, tag: :movement)]
  class EntityTeleport
    include Handler

    field ent : Entity
    field x : Float64
    field y : Float64
    field z : Float64
    field yaw : Angle
    field pitch : Angle
    field on_ground : Bool

    def run(con)
      @ent.x = @x
      @ent.y = @y
      @ent.z = @z
      @ent.yaw = @yaw
      @ent.pitch = @pitch
    end
  end

  @[Silent]
  @[Describe(level: 0, tag: :movement)]
  class EntityRotation
    include Handler

    field ent : Entity
    field yaw : Angle
    field pitch : Angle
    field on_ground : Bool

    def run(con)
      @ent.yaw = @yaw
      @ent.pitch = @pitch
    end
  end

  @[Silent]
  @[Describe(level: 3)]
  class EntityStatus
    include Handler

    field ent : Entity = con.entities[pkt.read_u32]
    field status : Data::Entity::Status = Data::Entity::Status.new pkt.read_i8
  end

  @[Silent]
  @[Describe(level: 3)]
  class EntityProp
    include Handler

    field ent : Entity = con.entities[pkt.read_var_int]
    field properties : Array(Data::Entity::Property) = Array(Data::Entity::Property).new(pkt.read_var_int) { Data::Entity::Property.from_io pkt }

    def run(con)
      properties.each do |prop|
        ent.properties[prop.key] = prop
      end
    end
  end

  @[Silent]
  @[Describe(level: 2)]
  class DestroyEntity
    include Handler

    field entities : Entity[VarInt]
  end

  @[Silent]
  @[Describe]
  class SpawnLiving
    include Handler

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

    def run(con)
      con.entities[@eid] = Data::Entity.new @eid, @uuid, @type, @x, @y, @z, @yaw, @pitch, @head, @vx, @vy, @vz
    end
  end

  @[Silent]
  @[Describe]
  class SpawnEntity
    include Handler

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

    def run(con)
      con.entities[@eid] = Data::Entity.new @eid, @uuid, @type, @data, @x, @y, @z, @yaw, @pitch, @vx, @vy, @vz
    end
  end

  @[Silent]
  @[Describe(level: 4)]
  class SpawnPlayer
    include Handler

    field eid : VarInt
    field uuid : UUID
    field x : Float64
    field y : Float64
    field z : Float64
    field yaw : Angle
    field pitch : Angle

    def run(con)
      con.entities[@eid] = Data::Entity.new @eid, @uuid, "minecraft:player", @x, @y, @z, @yaw, @pitch
      con.entities[@eid].player_name = con.players[@uuid].name
    end
  end

  @[Silent]
  @[Describe(level: 2)]
  class Equipment
    include Handler

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
