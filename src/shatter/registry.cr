require "json"

module Shatter
  class RegistryHash
    include JSON::Serializable

    getter entries : Hash(String, {protocol_id: UInt32})

    @[JSON::Field(ignore: true)]
    @reverse_memo : Hash(UInt32, String)? = nil

    def reverse
      if @reverse_memo.nil?
        r = @entries.map { |k, v| {v[:protocol_id], k} }.to_h
        @reverse_memo = r
        r
      else
        @reverse_memo.not_nil!
      end
    end
  end

  class Registry
    include JSON::Serializable

    @[JSON::Field(key: "minecraft:entity_type")]
    getter entity : RegistryHash
    @[JSON::Field(key: "minecraft:sound_event")]
    getter sound : RegistryHash
    @[JSON::Field(key: "minecraft:item")]
    getter item : RegistryHash
    @[JSON::Field(key: "minecraft:block")]
    getter block_id : RegistryHash
  end

  class BlockState
    include JSON::Serializable

    getter id : UInt64
    getter default = false
    getter properties : Hash(String, String)? = nil
  end

  class RegistryBlock
    include JSON::Serializable

    getter states : Array(BlockState)
  end

  def self.local_registry : {Shatter::Registry, Array(String)}
    registry = File.open "registries.json" do |f|
      Shatter::Registry.from_json f
    end
    blocks = File.open "blocks.json" do |f|
      Hash(String, Shatter::RegistryBlock).from_json f
    end
    max_block_state = blocks.map { |k, v| v.states.map &.id }.flatten.max
    known_blocks = Array(String).new(max_block_state + 1, "")
    blocks.each do |k, v|
      v.states.each do |s|
        prop = s.properties.nil? ? "" : "[#{s.properties.not_nil!.map { |k, v| "#{k}=#{v}" }.join(",")}]"
        known_blocks[s.id] = k + prop
      end
    end
    {registry, known_blocks}
  end
end
