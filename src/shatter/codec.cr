require "json"

module Shatter
  class Codec
    class DimensionType
      include JSON::Serializable
      KEY = "minecraft:dimension_type"

      getter height : Int32
    end

    class ChatType
      include JSON::Serializable
      KEY = "minecraft:chat_type"
    end

    class WorldgenBiome
      include JSON::Serializable
      KEY = "minecraft:worldgen/biome"
    end

    alias Raw = Hash(String, Entry::Base)
    getter data : Raw

    def initialize(@data)
    end

    def biomes! : Entry::Entry(WorldgenBiome)
      @data[WorldgenBiome::KEY].as Entry::Entry(WorldgenBiome)
    end

    def self.new(pull : JSON::PullParser)
      Codec.new Raw.new pull
    end

    def to_json(builder : JSON::Builder)
      @data.to_json builder
    end

    def to_s(io : IO)
      io << @data.pretty_inspect
    end
  end

  module Codec::Entry
    abstract class Base
      include JSON::Serializable

      use_json_discriminator "type", {
        DimensionType::KEY => Entry(DimensionType),
        ChatType::KEY      => Entry(ChatType),
        WorldgenBiome::KEY => Entry(WorldgenBiome),
      }

      getter type : String

      abstract def name_for!(id : UInt32) : String
    end

    record Item(T), name : String, id : UInt32, element : T do
      include JSON::Serializable
    end

    class Entry(T) < Base
      include JSON::Serializable

      getter value : Array(Item(T))

      def get!(id : UInt32) : T
        value.find!(&.id.== id).element
      end

      def name_for!(id : UInt32) : String
        value.find!(&.id.== id).name
      end
    end
  end
end
