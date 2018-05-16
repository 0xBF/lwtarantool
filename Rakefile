require 'rake'
require 'rake/extensiontask'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new do |ext|
  ext.name = 'lwtarantool'
  ext.ext_dir = 'ext/lwtarantool'
  ext.lib_dir = 'lib/lwtarantool'
end

RSpec::Core::RakeTask.new(:spec)

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  task default: [:spec, :rubocop]
rescue LoadError
  warn 'RuboCop is not available'
  task default: :spec
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |t|
    t.files = %w[lib/**/*.rb ext/lwtarantool/*.c]
    t.options = %w[--markup markdown]
  end
rescue LoadError
  warn 'Yard is not available'
end
