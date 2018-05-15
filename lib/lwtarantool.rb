require 'lwtarantool/lwtarantool'
require 'lwtarantool/connection'
require 'lwtarantool/request'

module LWTarantool
  def self.new(*args)
    LWTarantool::Connection.new(*args)
  end
end
