require_relative 'rspec_helpers/tarantool'

require 'lwtarantool'

RSpec.configure do |conf|
  conf.include RSpecHelpers::Tarantool
end
