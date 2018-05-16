#include <ruby.h>
#include "lwtarantool.h"

static VALUE rClass;

VALUE
lwt_request_create( VALUE conn, uint64_t id) {
  VALUE self;
  lwt_request_t * req;

  req = ZALLOC(lwt_request_t);
  req->id = id;

  self = Data_Wrap_Struct( rClass, NULL, NULL, req);
  rb_iv_set(self, "@conn", conn);

  //printf("Create request %p, reply: %p\n", req, req->reply);

  return self;
}

void
lwt_request_add_reply( VALUE self, struct tnt_reply *reply) {
  lwt_request_t * req;
  Data_Get_Struct(self, lwt_request_t, req);

  //printf("Add reply %p to request %p\n", reply, req);

  req->reply = reply;
}

/*
 * Document-class: LWTarantool::Request
 *
 * Request id
 *
 * @return [Integer] id
 */
static VALUE
lwt_request_id( VALUE self) {
  lwt_request_t * req;
  Data_Get_Struct(self, lwt_request_t, req);

  return rb_uint2inum(req->id);
}

/*
 * Document-class: LWTarantool::Request
 *
 * Check if request already processed.
 */
static VALUE
lwt_request_is_ready( VALUE self) {
  lwt_request_t * req;
  Data_Get_Struct(self, lwt_request_t, req);

  if (req->reply == NULL) 
    return Qfalse;
  else
    return Qtrue;
}

/*
static VALUE
lwt_request_code( VALUE self) {
  lwt_request_t * req;
  Data_Get_Struct(self, lwt_request_t, req);

  if (req->reply == NULL) 
    return Qnil;

  return rb_uint2inum(req->reply->code);
}
*/

static VALUE
lwt_request_error( VALUE self) {
  lwt_request_t * req;
  Data_Get_Struct(self, lwt_request_t, req);

  if (req->reply == NULL)
    return Qnil;

  if (req->reply->code == 0)
    return Qnil;

  if (req->reply->error == NULL)
    return Qnil;

  const char *data = req->reply->error;
  size_t data_len = req->reply->error_end - data;
  return rb_str_new(data, data_len);
}

static VALUE
lwt_request_result( VALUE self) {
  lwt_request_t * req;
  Data_Get_Struct(self, lwt_request_t, req);

  if (req->reply == NULL)
    return Qnil;

  if (req->reply->code != 0)
    return Qnil;

  const char *data = req->reply->data;
  size_t data_len = req->reply->data_end - data;
  return rb_str_new(data, data_len);
}

void init_request() {
  /*
   * Document-class: LWTarantool::Request
   *
   * Class for work with Tarantool requests
   */
  rClass = rb_define_class_under( lwt_Class, "Request", rb_cObject);

  rb_define_method(rClass, "id", lwt_request_id, 0);
  rb_define_method(rClass, "ready?", lwt_request_is_ready, 0);
  //rb_define_method(rClass, "code", lwt_request_code, 0);
  rb_define_private_method(rClass, "_error", lwt_request_error, 0);
  rb_define_private_method(rClass, "_result", lwt_request_result, 0);
}
