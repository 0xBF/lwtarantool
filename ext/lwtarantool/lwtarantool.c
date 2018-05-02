#include <ruby.h>
#include "lwtarantool.h"

VALUE lwt_Class;

void Init_lwtarantool() {
  lwt_Class = rb_define_module( "LWTarantool");

  init_errors();
  init_conn();
  init_request();
}
