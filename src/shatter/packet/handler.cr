require "../data"
require "../data/entity"
require "../packet"
require "../connection"
require "json"

module Shatter::Packet
  annotation AlwaysHexdump
  end

  annotation Describe
  end

  annotation Transform
  end

  annotation Alias
  end

  annotation Version
  end

  module TypeReader
  end

  module TypeAlias
  end

  macro type_reader(alias_type, return_type, &block)
    {% if alias_type != return_type %}
      alias {{alias_type}} = {{return_type}}
      record TypeAlias::{{alias_type}}
      {% alias_type = "TypeAlias::#{alias_type}".id %}
    {% end %}

    module TypeReader
      {% if block.args.size == 1 %}
        def self.read(type : {{alias_type}}.class, {{block.args[0]}} : IO, __ignore : ::Shatter::Connection) : {{return_type}}
          {{yield}}
        end
      {% elsif block.args.size == 2 %}
        def self.read(type : {{alias_type}}.class, {{block.args[0]}} : IO, {{block.args[1]}} : ::Shatter::Connection) : {{return_type}}
          {{yield}}
        end
      {% end %}
    end
  end

  type_reader VarInt, UInt32, &.read_var_int
  type_reader Angle, Float64, &.read_angle
  type_reader Velocity, Float64, &.read_i16./(400)
  type_reader Entity, ::Shatter::Data::Entity do |pkt, con|
    con.entities[pkt.read_var_int]
  end
  type_reader BlockState, String do |pkt, con|
    con.block_states[pkt.read_var_int]
  end
  type_reader BlockID, String do |pkt, con|
    con.registry.block_id.reverse[pkt.read_var_int]
  end
  type_reader EntityType, String do |pkt, con|
    con.registry.entity.reverse[pkt.read_var_int]
  end
  type_reader Sound, String do |pkt, con|
    con.registry.sound.reverse[pkt.read_var_int]
  end
  type_reader Data::Slot?, Data::Slot? do |pkt, con|
    ::Shatter::Data::Slot.from_io pkt, con
  end
  type_reader Chunk::Tile, Chunk::Tile do |pkt, con|
    ::Shatter::Chunk::Tile.new pkt
  end

  type_reader NBT, ::NBT::Tag do |pkt|
    ::NBT::Reader.new(pkt).read_named[:tag]
  end

  type_reader Chat, String do |pkt|
    pkt.read_var_string
  end

  type_reader UUID, UUID, &.read_uuid
  type_reader Bool, Bool, &.read_bool
  type_reader String, String, &.read_var_string
  {% for type in %w(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64 Float32 Float64) %}
    type_reader {{type.id}}, {{type.id}}, &.read_bytes({{type.id}}, IO::ByteFormat::BigEndian)
  {% end %}

  module Handler
    annotation Field
    end

    macro field(t, &block)
      {% val = t.value %}
      {% return_type = t.type %}
      {% if val.is_a?(Nop) %}
        {%
          is_array = false
          array_type = "Array".id
          has_reader = false
          real_type = t.type

          if t.type.is_a? ProcNotation && t.type.inputs[0].name.resolve == StaticArray
            is_array = t.type.inputs[0]
            array_type = t.type.output.resolve.name(generic_args: false)
          elsif t.type.is_a? Generic && t.type.name.resolve == StaticArray
            is_array = t.type
          end

          if is_array
            real_type = is_array.type_vars[0]
            quantifier = is_array.type_vars[1]
            return_type = (array_type.stringify + "(" + real_type.stringify + ")").id
          end

          if real_type.is_a? Union
            real_type = ("::Union(" + real_type.types.splat.stringify + ")").id
          end
        %}

        {% if block %}
          {% has_reader = true %}
          def self.%read(pkt : ::IO, con : ::Shatter::Connection)
            {{ yield }}
          end
        {% end %}

        {% if is_array || t.type.id != t.type.resolve.id %}
          @[::Shatter::Packet::Handler::Field({% if has_reader %}reader: %read, {% end %}{% if is_array %}quantifier: {{quantifier}}, array_type: {{array_type}}, {% end %} real_type: {{real_type}})]
        {% end %}
      {% else %}
        @[::Shatter::Packet::Handler::Field(self_defining: {{ val }})]
      {% end %}
      {% if t.var.id.starts_with?("_") %}
        @[::JSON::Field(ignore: true)]
      {% end %}
      @{{t.var.id}} : {{return_type}}

      def {{t.var.id}} : {{return_type}}
        @{{t.var.id}}
      end
    end

    macro included
      include JSON::Serializable
      {% qualifier = @type.id.split("::")[-2].id %}
      {% name = @type.id.split("::")[-1].id %}
      {% alias_ann = @type.annotation(::Shatter::Packet::Alias) %}
      {% if alias_ann %}
        {% name = alias_ann[0].id %}
      {% end %}
      {% e = "::Shatter::Packet::Cb::#{qualifier}::#{name}".id %}
      {% if @type.annotation(::Shatter::Packet::Describe) && !@type.annotation(::Shatter::Packet::AlwaysHexdump) %}
        ::Shatter::Packet::SILENT[{{e}}] = true
      {% end %}
      ::Shatter::Packet::PACKET_HANDLERS[{{e}}] << ->(pkt : ::IO, con : ::Shatter::Connection) {
        {% if v_ann = @type.annotation(::Shatter::Packet::Version) %}
          return nil unless con.protocol {{ v_ann[0].id }} {{ v_ann[1].id }}
        {% end %}
        self.new(pkt, con).as Packet::Handler?
      }

      @@packet_name = {{ name.stringify }}
      def packet_name : String
        @@packet_name
      end

      def describe(con : ::Shatter::Connection, io : IO = STDERR)
        {% if @type.annotation(::Shatter::Packet::Describe) %}
        _describe(con, io)
        {% end %}
      end
      def has_describe? : Bool
        {% if @type.annotation(::Shatter::Packet::Describe) %}true{% else %}false{% end %}
      end

      def self.new(pkt : ::IO, con : ::Shatter::Connection)
        instance = allocate
        instance.initialize(pkt, con)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end
    end

    macro type_or_alias(type)
      {% if ::Shatter::Packet::TypeAlias.has_constant?(type.id) %}
        ::Shatter::Packet::TypeAlias::{{type.id}}
      {% else %}
        {{type.id}}
      {% end %}
    end

    def initialize(pkt : ::IO, con : ::Shatter::Connection)
      {% begin %}
      {% properties = {} of Nil => Nil %}
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(::Shatter::Packet::Handler::Field) %}
        {%
          properties[ivar.id] = {
            type:       ivar.type,
            real_type:  ann && ann[:real_type],
            self_def:   ann && ann[:self_defining],
            quantifier: ann && ann[:quantifier],
            reader:     ann && ann[:reader],
            array_type: (ann && ann[:array_type]) || "Array",
          }
        %}
      {% end %}

      {% for name, value in properties %}
        {% target_type = value[:real_type] || value[:type] %}
        {% if value[:self_def] %}
          @{{name}} = {{ value[:self_def] }}
        {% elsif value[:quantifier] %}
          {% if value[:quantifier].is_a?(InstanceVar) %}
            %quantifier = {{ value[:quantifier] }}
          {% elsif value[:quantifier].is_a?(Path) %}
            %quantifier = ::Shatter::Packet::TypeReader.read(type_or_alias({{value[:quantifier]}}), pkt, con)
          {% end %}
          @{{name}} = {{ value[:array_type].id }}({{target_type}}).new(%quantifier.to_i32) do
            {% if value[:reader] %}
              {% reader = @type.class.methods.find &.name.==(value[:reader].id) %}
              {{ reader.body }}
            {% else %}
              ::Shatter::Packet::TypeReader.read(type_or_alias({{target_type}}), pkt, con)
            {% end %}
          end
        {% else %}
          {% if value[:reader] %}
            {% reader = @type.class.methods.find &.name.==(value[:reader].id) %}
            @{{name}} = {{ reader.body }}
          {% else %}
            @{{name}} = ::Shatter::Packet::TypeReader.read(type_or_alias({{target_type}}), pkt, con)
          {% end %}
        {% end %}
      {% end %}
      {% end %}
    end

    protected def run(con : ::Shatter::Connection)
    end

    private def _describe(con : ::Shatter::Connection, io : IO)
      {% begin %}
      {% ann = @type.annotation(::Shatter::Packet::Describe) %}
      {% if ann[:tag] %}
      return unless (ENV["SHATTER_DESCRIBE_TAGS"]? || "").split(",").includes?({{ ann[:tag].id.stringify }})
      {% end %}
      {% transform = ann && ann[:transform] %}
      {% level = (ann && ann[:level]) || 1 %}
      %color = {% if level == 0 %} :dark_gray
               {% elsif level == 1 %} :red
               {% elsif level == 2 %} :yellow
               {% elsif level == 3 %} :light_yellow
               {% elsif level == 4 %} :magenta
               {% elsif level == 5 %} :light_magenta
               {% end %}
      io << " IN-PKT<".colorize.light_red
      io << "{{ @type.id.split("::").last.id }}".rjust(16).colorize %color
      io << "|"
      {% if ann && ann[:order] %}
        {% order = ann[:order].map { |i| @type.instance_vars.find { |j| j.id == i.id } } %}
      {% else %}
        {% order = @type.instance_vars %}
      {% end %}
      {% for ivar in order %}
        {% unless ivar.id.starts_with? "_" %}
          io << "{{ ivar.id }}=".colorize.dark_gray
          %field = @{{ivar.id}}
          {% transform = ivar.annotation(::Shatter::Packet::Transform) %}
          {% if !flag?("SHATTER_IGNORE_FIELD_TRANSFORM") && transform %}
            io << {{ transform[0] }}
          {% elsif ivar.type < Float %}
            io << %field.format(decimal_places: 2, only_significant: true)
          {% elsif ivar.type == Bytes %}
            io << "Bytes(" << %field.size << ")[" << %field.hexstring << "]"
          {% else %}
            %field.to_s io
          {% end %}
          io << " "
        {% end %}
      {% end %}
      io.puts
      {% end %}
    end
  end
end
