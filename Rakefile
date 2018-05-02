require 'rake'
require 'rake/extensiontask'

task :compile => :prepare

Rake::ExtensionTask.new('lwtarantool')

task :prepare do
  puts :qqqqq
end

#namespace :gem do
#  desc 'Build gem file'
#  task :build do
#    system '
#      set -e
#
#      git submodule deinit --all -f
#      git submodule init
#      git submodule update
#      git -C ext/lwtarantool/vendor/tarantool-c submodule init third_party/msgpuck
#      git -C ext/lwtarantool/vendor/tarantool-c submodule update
#
#      gem build -q lwtarantool.gemspec
#    '
#  end
#
#  task :install => :build do
#    system 'gem install --user-install lwtarantool-*.gem'
#  end
#end


begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
  task default: %i[spec rubocop]
rescue LoadError
  warn 'RuboCop is not available'
  task default: :spec
end
