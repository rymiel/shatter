require "../data"
require "shatter-chat/../spec/spec_builder"

module Shatter::Packet
  annotation Silent
  end

  annotation Describe
  end

  annotation Alias
  end

  module TypeReader
  end

  macro type_reader(alias_type, return_type, &block)
    {% if alias_type != return_type %}
      alias {{alias_type}} = {{return_type}}
    {% end %}
    {% alias_type = alias_type.id.gsub(/::/, "_r_").gsub(/\(/, "_g_").gsub(/, /, "_a_").gsub(/\)/, "_e_") %}
    module TypeReader::A_{{alias_type}}
      {% if block.args.size == 1 %}
        def self.read({{block.args[0]}} : IO, __ignore : ::Shatter::Connection) : {{return_type}}
          {{yield}}
        end
      {% elsif block.args.size == 2 %}
        def self.read({{block.args[0]}} : IO, {{block.args[1]}} : ::Shatter::Connection) : {{return_type}}
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
  type_reader Data::Slot?, Data::Slot? do |pkt, con|
    ::Shatter::Data::Slot.from_io pkt, con
  end

  type_reader NBT, ::NBT::Tag do |pkt|
    ::NBT::Reader.new(pkt).read_named[:tag]
  end
  
  type_reader Chat, String do |pkt|
    raw_message = pkt.read_var_string
    message_json = JSON.parse(raw_message).as_h
    {% if flag?(:wsp) %}
      Shatter::Chat::HtmlBuilder.new.read message_json
    {% else %}
      Shatter::Chat::AnsiBuilder.new.read message_json
    {% end %}
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
      {% if val.is_a?(Nop) %}
        {% if block %}
          def self.%read(pkt : ::IO, con : ::Shatter::Connection)
            {{ yield }}
          end
          @[::Shatter::Packet::Handler::Field(reader: %read, real_type: {{t.type}})]
        {% elsif t.type.id != t.type.resolve.id %}
          @[::Shatter::Packet::Handler::Field(real_type: {{t.type}})]
        {% end %}
        @{{t.var.id}} : {{t.type}}
      {% else %}
        @[::Shatter::Packet::Handler::Field(self_defining: {{ val }})]
        @{{t.var.id}} : {{t.type}}
      {% end %}
  
      def {{t.var.id}} : {{t.type}}
        @{{t.var.id}}
      end
    end

    macro array_field(t, *, count, array_type = Array, &block)
      {% val = t.value %}
      {% if block %}
        def self.%read(pkt : ::IO, con : ::Shatter::Connection)
          {{ yield }}
        end
        @[::Shatter::Packet::Handler::Field(reader: %read, real_type: {{t.type}}, quantifier: {{count}}, array_type: {{array_type}})]
      {% else %}
        @[::Shatter::Packet::Handler::Field(real_type: {{t.type}}, quantifier: {{count}}, array_type: {{array_type}})]
      {% end %}
      @{{t.var.id}} : {{array_type}}({{t.type}})
  
      def {{t.var.id}} : {{array_type}}({{t.type}})
        @{{t.var.id}}
      end
    end

    macro included
      {% qualifier = @type.id.split("::")[-2].id %}
      {% name = @type.id.split("::")[-1].id %}
      {% alias_ann = @type.annotation(::Shatter::Packet::Alias) %}
      {% if alias_ann %}
        {% name = alias_ann[0].id %}
      {% end %}
      {% e = "::Shatter::PktId::Cb::#{qualifier}::#{name}".id %}
      {% if @type.annotation(::Shatter::Packet::Silent) %}
        ::Shatter::PktId::SILENT[{{e}}] = true
      {% end %}
      ::Shatter::PktId::PACKET_HANDLERS[{{e}}] = ->(pkt : ::IO, con : ::Shatter::Connection) {
        r = self.new(pkt: pkt, con: con)
        {% if @type.annotation(::Shatter::Packet::Describe) %}
        con.packet_callback.try &.call(r, con)
        r.describe
        {% end %}
        r
      }
      @__con : ::Shatter::Connection
      @__pkt : ::IO
      def con : ::Shatter::Connection
        @__con
      end
      def pkt : ::IO
        @__pkt
      end
    end

    def initialize(*, pkt : ::IO, con : ::Shatter::Connection)
      @__pkt = pkt
      @__con = con
      {% begin %}
      {% properties = {} of Nil => Nil %}
      {% for ivar in @type.instance_vars %}
        {% unless ivar.id.starts_with?("__") %}
          {% ann = ivar.annotation(::Shatter::Packet::Handler::Field) %}
          {%
            properties[ivar.id] = {
              type:       ivar.type,
              real_type:  ann && ann[:real_type],
              self_def:   ann && ann[:self_defining],
              quantifier: ann && ann[:quantifier],
              reader:     ann && ann[:reader],
              array_type: (ann && ann[:array_type]) || "Array"
            }
          %}
        {% end %}
      {% end %}

      {% for name, value in properties %}
        {% m = value[:real_type] || value[:type] %}
        {% t = m.id.gsub(/(.*) \| (.*)/, "::Union(\\1, \\2)").gsub(/::/, "_r_").gsub(/\(/, "_g_").gsub(/, /, "_a_").gsub(/\)/, "_e_") %}
        {% if value[:self_def] %}
          @{{name}} = {{ value[:self_def] }}
        {% elsif value[:quantifier] %}
          {% if value[:quantifier].is_a?(InstanceVar) %}
            %quantifier = {{ value[:quantifier] }}
          {% elsif value[:quantifier].is_a?(Path) %}
            %quantifier = ::Shatter::Packet::TypeReader::A_{{value[:quantifier]}}.read(pkt, con)
          {% end %}
          @{{name}} = {{ value[:array_type].id }}({{m}}).new(%quantifier.to_i32) do
            {% if value[:reader] %}
              {% reader = @type.class.methods.find &.name.==(value[:reader].id) %}
              {{ reader.body }}
            {% else %}
              ::Shatter::Packet::TypeReader::A_{{t}}.read(pkt, con)
            {% end %}
          end
        {% else %}
          {% if value[:reader] %}
            {% reader = @type.class.methods.find &.name.==(value[:reader].id) %}
            @{{name}} = {{ reader.body }}
          {% else %}
            @{{name}} = ::Shatter::Packet::TypeReader::A_{{t}}.read(pkt, con)
          {% end %}
        {% end %}
      {% end %}
      self.run
      con.last_packet = self
      {% end %}
    end

    protected def run
    end

    def describe(io : IO = STDOUT)
      {% begin %}
      {% ann = @type.annotation(::Shatter::Packet::Describe) %}
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
        {% order = ann[:order].map {|i| @type.instance_vars.find {|j| j.id == i.id} } %}
      {% else %}
        {% order = @type.instance_vars %}
      {% end %}
      {% for ivar in order %}
        {% unless ivar.id.starts_with? "_" %}
          io << "{{ ivar.id }}=".colorize.dark_gray
          %field = @{{ivar.id}}
          {% if transform && transform[ivar.id.symbolize] %}
            io << {{ transform[ivar.id.symbolize] }}
          {% elsif ivar.type < Float %}
            io << %field.format(decimal_places: 2, only_significant: true)
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