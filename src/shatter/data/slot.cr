require "json"
require "nbt"

module Shatter::Data
  enum InvIdx
    CraftResult
    Craft1
    Craft2
    Craft3
    Craft4
    Helmet
    Chest
    Legs
    Boots
    R1C1
    R1C2
    R1C3
    R1C4
    R1C5
    R1C6
    R1C7
    R1C8
    R1C9
    R2C1
    R2C2
    R2C3
    R2C4
    R2C5
    R2C6
    R2C7
    R2C8
    R2C9
    R3C1
    R3C2
    R3C3
    R3C4
    R3C5
    R3C6
    R3C7
    R3C8
    R3C9
    Hotbar1
    Hotbar2
    Hotbar3
    Hotbar4
    Hotbar5
    Hotbar6
    Hotbar7
    Hotbar8
    Hotbar9
    Offhand
  end
  record Slot, name : String, count : UInt8, nbt : Hash(String, NBT::Tag)? do
    include JSON::Serializable

    def inspect(io : IO)
      io << count << "x " if count != 1
      io << name.lchop "minecraft:"
      io << nbt
    end

    def pretty_print(pp) : Nil
      pp.text "#{count}x " if count != 1
      pp.text name.lchop "minecraft:"
      nbt.pretty_print pp unless nbt.nil?
    end

    def self.from_io(io : IO, con : Shatter::Connection) : Slot?
      has_item = io.read_bool
      if has_item
        item_id = con.registry.item.reverse[io.read_var_int]
        item_count = io.read_u8
        item_nbt = NBT::Reader.new(io).read_named[:tag]
        item_structure = item_nbt.as_h?
        Slot.new(item_id, item_count, item_structure)
      else
        nil
      end
    end
  end
end
