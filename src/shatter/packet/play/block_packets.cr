require "../handler"

module Shatter::Packet::Play
  @[Describe(2, blocks, default: false)]
  class BlockChange
    include Handler

    field pos : Position

    field state : BlockState
  end

  @[Describe(2, blocks)]
  class BlockAction
    include Handler

    KNOWN_ACTION = {
      "minecraft:note_block"     => ["Play note"],
      /minecraft:\w*piston/      => ["Extend", "Retract"],
      /minecraft:\w*chest/       => [nil, "Update viewers"],
      /minecraft:\w*shulker_box/ => [nil, "Update viewers"],
      "minecraft:beacon"         => [nil, "Recalculate beam"],
      "minecraft:mob_spawner"    => [nil, "Reset delay"],
      "minecraft:end_gateway"    => [nil, "Fire beam"],
      "minecraft:bell"           => [nil, "Ring"],
    }
    KNOWN_PARAM = {
      /minecraft:(\w*piston|bell)/ => ["Down", "Up", "South", "West", "North", "East"],
    }

    field pos : Position
    field _action : UInt8
    field _param : UInt8
    field block : BlockID
    field action : String = Play::BlockAction::KNOWN_ACTION.find { |k, _| k === @block }.try &.[1][@_action] || @_action.to_s
    field param : String = Play::BlockAction::KNOWN_PARAM.find { |k, _| k === @block }.try &.[1][@_param] || @_param.to_s
  end

  @[Describe(2, blocks, default: false)]
  class MultiBlocks
    include Handler

    field _val : UInt64
    field _sect_x : Int64 = (@_val >> 42).as_signed_bit_width(22)
    field _sect_y : Int64 = (@_val << 44 >> 44).as_signed_bit_width(20)
    field _sect_z : Int64 = (@_val << 22 >> 42).as_signed_bit_width(22)
    field _garbage : Bool

    @[Transform(@blocks.map { |i| "<x#{i[:x]},y#{i[:y]},z#{i[:z]}: #{i[:state]}>" }.join ", ")]
    field blocks : {x: Int64, y: Int64, z: Int64, state: String}[VarInt] do
      block = pkt.read_var_long
      local_x = ((block & 0xF00) >> 8)
      local_z = ((block & 0x0F0) >> 4)
      local_y = (block & 0x00F)
      state = con.block_states[(block >> 12).to_i32]
      {x: (@_sect_x * 16 + local_x), y: (@_sect_y * 16 + local_y), z: (@_sect_z * 16 + local_z), state: state}
    end
  end
end
