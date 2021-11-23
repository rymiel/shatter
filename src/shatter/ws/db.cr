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
      AlterList
    end

    column id : UUID, primary: true
    has_many servers : ServerList, foreign_key: "user"

    column roles : Role
    column allowed : Array(String)
    column created_at : Time
    column last_known_name : String?

    def role_array : Bool[3]
      StaticArray[roles.tester?,
       roles.superuser?,
       roles.alter_list?]
    end
  end

  class ServerList
    include Clear::Model
    self.table = "serverlist"

    belongs_to owner : User, foreign_key: "user", foreign_key_type: UUID
    column id : UInt64, primary: true

    column host : String
    column port : Int32
    column created_at : Time
  end
end
