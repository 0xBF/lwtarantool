require 'rake'
require 'rake/extensiontask'

Rake::ExtensionTask.new do |ext|
  ext.name = 'lwtarantool'
  ext.ext_dir = 'ext/lwtarantool'
  ext.lib_dir = 'lib/lwtarantool'
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  task default: %i[spec rubocop]
rescue LoadError
  warn 'RuboCop is not available'
  task default: :spec
end
