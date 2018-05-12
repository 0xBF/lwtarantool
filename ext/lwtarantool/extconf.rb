require 'mkmf'

$INCFLAGS << ' -I$(srcdir)/vendor/tarantool-c/include'
$LIBPATH << 'msgpuck/'
$LIBPATH << 'tarantool-c/tnt/'
$LOCAL_LIBS = '-ltarantool -lmsgpuck'

create_makefile 'lwtarantool/lwtarantool'
