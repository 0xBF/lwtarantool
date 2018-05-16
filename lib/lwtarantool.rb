# frozen_string_literal: true

require 'lwtarantool/lwtarantool'
require 'lwtarantool/connection'
require 'lwtarantool/request'

## LWTarantool
#
# A modern and simple Tarantool 1.7+ library for Ruby.
#
# It doesn't support all  tarantool protocol features, the only function calls,
# but allow work with tarantool in async paradigm.
#
module LWTarantool
  #
  # Same as {LWTarantool::Connection#initialize LWTarantool::Connection.new(args)}
  #
  # @return {LWTarantool::Connection}
  #
  def self.new(args)
    LWTarantool::Connection.new(args)
  end
end
