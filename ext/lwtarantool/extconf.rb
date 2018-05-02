require 'mkmf'

unless find_header 'tarantool/tarantool.h', File.expand_path( '../vendor/tarantool-c/include', __FILE__)
  exit 1
end

$LOCAL_LIBS = '-ltarantool -lmsgpuck'

create_makefile 'lwtarantool/lwtarantool'
