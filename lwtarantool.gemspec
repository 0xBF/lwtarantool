Gem::Specification.new do |s|
    s.name        = 'lwtarantool'
    s.version     = '0.0.1'
    s.date        = '2018-05-03'
    s.summary     = "Lightweight Tarantool client"
    s.description = "Tarantool client library"
    s.authors     = ["Alexander Golovko"]
    s.email       = 'ag@wallarm.com'
    s.files       = Dir['ext/**/*'].grep(/depend|\.(rb|c|h|cmake|txt)$/) + Dir['lib/**/*.rb']
    s.extensions  = ["ext/lwtarantool/extconf.rb"]
    s.homepage    = 'http://rubygems.org/gems/lwtarantool'
    s.license     = 'MIT'
    s.add_dependency("msgpack", '~> 1.0')
end
