# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'lwtarantool'
  s.version     = '0.0.5'
  s.date        = '2019-09-24'
  s.summary     = 'Lightweight Tarantool client'
  s.description = 'Tarantool client library'
  s.authors     = ['Alexander Golovko']
  s.email       = 'ag@wallarm.com'
  s.files       = Dir['ext/**/*'].grep(/depend|\.(rb|c|h|cmake|txt)$/) +
                  Dir['lib/**/*.rb'] + ['README.md']
  s.extensions  = ['ext/lwtarantool/extconf.rb']
  s.homepage    = 'http://rubygems.org/gems/lwtarantool'
  s.license     = 'MIT'
  s.add_dependency('msgpack', '~> 1')
end
