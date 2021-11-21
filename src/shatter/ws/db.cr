require "uuid"
require "clear"
Clear::SQL.init ENV["PG_URL"]

module Shatter::WS::DB
  class EnumConverter(E)
    def self.to_column(x) : E?
      case x
      when Nil
        nil
      when Int32
        E.new(x)
      else
        raise "Cannot convert from #{x.class} to enum #{E}"
      end
    end

    def self.to_db(x : E?)
      (x.try &.to_i) || 0
    end
  end

  Clear::Model::Converter.add_converter("Shatter::WS::DB::User::Role", Shatter::WS::DB::EnumConverter(Shatter::WS::DB::User::Role))

  class User
    include Clear::Model
    self.table = "user"

    @[Flags]
    enum Role
      Tester
      Superuser
    end

    column id : UUID, primary: true

    column roles : Role
    column allowed : Array(String)
    column created_at : Time
    column last_known_name : String?
  end
end
