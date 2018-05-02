#include <ruby.h>
#include "lwtarantool.h"

VALUE lwt_eError = NULL;
VALUE lwt_eLoginError = NULL;
VALUE lwt_eResolvError = NULL;
VALUE lwt_eSyncError = NULL;
VALUE lwt_eSystemError = NULL;
VALUE lwt_eTimeoutError = NULL;
VALUE lwt_eUnknownError = NULL;

void init_errors() {
  lwt_eError = rb_define_class_under( lwt_Class, "Error", rb_eStandardError);
  lwt_eLoginError = rb_define_class_under( lwt_Class, "LoginError", lwt_eError);
  lwt_eSyncError = rb_define_class_under( lwt_Class, "SyncError", lwt_eError);
  lwt_eSystemError = rb_define_class_under( lwt_Class, "SystemError", lwt_eError);
  lwt_eResolvError = rb_define_class_under( lwt_Class, "ResolvError", lwt_eError);
  lwt_eTimeoutError = rb_define_class_under( lwt_Class, "TimeoutError", lwt_eError);
  lwt_eUnknownError = rb_define_class_under( lwt_Class, "UnknownError", lwt_eError);

  //lwt_eLoginError = rb_define_class_under( lwt_Class, "LoginError", lwt_eError);
  //lwt_eLoginError = rb_define_class_under( lwt_Class, "LoginError", lwt_eError);
  //lwt_eLoginError = rb_define_class_under( lwt_Class, "LoginError", lwt_eError);
}
