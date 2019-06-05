#include <ruby.h>
#include <ruby/st.h>

#include <stdio.h>
#include <stdlib.h>

#include <tarantool/tarantool.h>
#include <tarantool/tnt_net.h>
#include <tarantool/tnt_opt.h>

#include "lwtarantool.h"


static int
lwt_conn_interrupt_request(uint64_t *id, VALUE req) {
  struct tnt_reply *reply = tnt_reply_init(NULL);

  char * error = "Request canceled due to connection close";

  reply->code = -1;
  reply->error = error;
  reply->error_end = error + strlen(error);

  lwt_request_add_reply(req, reply);

  return ST_DELETE;
}

static int
lwt_conn_mark_request(uint64_t *id, VALUE req) {
  rb_gc_mark(req);
  return ST_CONTINUE;
}

static void
lwt_conn_mark(void *s) {
  lwt_conn_t *conn = (lwt_conn_t *) s;
  st_foreach(conn->requests, lwt_conn_mark_request, 0);
}

static void
lwt_conn_dealloc(lwt_conn_t *conn) {
  if (conn == NULL)
    return;

  if (conn->tnt != NULL) {
    tnt_close(conn->tnt);
    tnt_stream_free(conn->tnt);
  }
  if (conn->requests) {
    st_clear(conn->requests);
    st_free_table(conn->requests);
  }
}

static VALUE
lwt_conn_alloc( VALUE klass) {
  lwt_conn_t * conn;
  conn = ZALLOC(lwt_conn_t);

  conn->tnt = tnt_net(NULL);
  conn->requests = st_init_numtable();

  return Data_Wrap_Struct( klass, lwt_conn_mark, lwt_conn_dealloc, conn);
}

static void
lwt_conn_raise_error(lwt_conn_t *conn) {
  switch(tnt_error(conn->tnt)) {
    case TNT_EMEMORY:
      rb_raise(rb_eNoMemError, "%s", tnt_strerror(conn->tnt));
      break;
    case TNT_ERESOLVE:
      rb_raise(lwt_eResolvError, "%s", tnt_strerror(conn->tnt));
      break;
    case TNT_ETMOUT:
      rb_raise(lwt_eTimeoutError, "%s", tnt_strerror(conn->tnt));
      break;
    case TNT_ELOGIN:
      rb_raise(lwt_eLoginError, "%s", tnt_strerror(conn->tnt));
      break;
    case TNT_ESYSTEM:
      rb_raise(lwt_eSystemError, "%s", tnt_strerror(conn->tnt));
      break;
    case TNT_EBIG:
      rb_raise(lwt_eTooLargeRequestError, "%s", tnt_strerror(conn->tnt));
      break;
    case TNT_EFAIL:
    default:
      rb_raise(lwt_eUnknownError, "%s", tnt_strerror(conn->tnt));
      break;
  }
}

static VALUE
lwt_conn_connect(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  if (tnt_connect(conn->tnt) < 0)
    lwt_conn_raise_error(conn);

  return Qtrue;
}

static VALUE
lwt_conn_disconnect(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  tnt_close(conn->tnt);
  st_foreach(conn->requests, lwt_conn_interrupt_request, 0);

  return Qtrue;
}

/**
 * Document-class: LWTarantool::Connection
 *
 * Create new connection to Tarantool.
 *
 * @param [Hash] args the options to establish connection
 * @option args [String] :url The tarantool address
 * @option args [Integer] :recv_buf_size Receive buffer size (unknown effect)
 * @option args [Integer] :send_buf_size Send buffer size (maximum request size)
 *
 * @example
 *   LWTarantool::Connection.new(url: 'tcp://127.0.0.1:3301')
 *
 * @return [LWTarantool::Connection] a new connection instance.
 *
 * @raise [LWTarantool::ResolvError] destination host can't be resolved
 * @raise [LWTarantool::TimeoutError] connect timeout reached
 * @raise [LWTarantool::LoginError] incorrect login or password
 * @raise [LWTarantool::SystemError] connection failed
 * @raise [LWTarantool::UnknownError] unknown error
 */
static VALUE
lwt_conn_initialize(VALUE self, VALUE args) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  VALUE val;

  val = rb_mutex_new();
  rb_iv_set(self, "@mutex", val);

  if (TYPE(args) != T_HASH)
    rb_raise(rb_eArgError, "args must be a Hash");

  // handle recv_buf_size option
  val = rb_hash_aref(args, ID2SYM(rb_intern( "recv_buf_size")));
  if (TYPE(val) != T_NIL) {
    if (TYPE(val) != T_FIXNUM)
      rb_raise(rb_eArgError, "recv_buf_size must be an Integer");

    if (tnt_set(conn->tnt, TNT_OPT_RECV_BUF, rb_fix2uint(val)) != 0)
      rb_raise(rb_eArgError, "invalid recv_buf_size value");
  }

  // handle send_buf_size option
  val = rb_hash_aref(args, ID2SYM(rb_intern( "send_buf_size")));
  if (TYPE(val) != T_NIL) {
    if (TYPE(val) != T_FIXNUM)
      rb_raise(rb_eArgError, "send_buf_size must be an Integer");

    if (tnt_set(conn->tnt, TNT_OPT_SEND_BUF, rb_fix2uint(val)) != 0)
      rb_raise(rb_eArgError, "invalid send_buf_size value");
  }

  // handle url option
  val = rb_hash_aref(args, ID2SYM(rb_intern( "url")));
  if (TYPE(val) != T_STRING)
    rb_raise(rb_eArgError, "url must be a String");

  int url_len = RSTRING_LEN(val);
  char url[url_len+1];
  url[url_len] = '\0';
  strncpy(url, RSTRING_PTR(val), url_len);

  if (tnt_set(conn->tnt, TNT_OPT_URI, url) != 0)
    rb_raise(rb_eArgError, "invalid url value");

  lwt_conn_connect(self);

  return Qnil;
}

static VALUE
lwt_conn_call(VALUE self, VALUE func, VALUE args) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  if (TYPE(func) != T_STRING)
    rb_raise(rb_eArgError, "function name must be a String");

  if (TYPE(args) != T_STRING)
    rb_raise(rb_eArgError, "args must be a string with msgpack array");

  int func_len = RSTRING_LEN(func);
  char func_name[func_len+1];
  func_name[func_len] = '\0';
  strncpy(func_name, RSTRING_PTR(func), func_len);

  uint64_t reqid = conn->tnt->reqid;
  VALUE req;

  struct tnt_stream * data;
  data = tnt_object(NULL);
  if (data == NULL)
    rb_raise(rb_eNoMemError, "Can't create tnt_object");

  if (data->write(data, RSTRING_PTR(args), RSTRING_LEN(args)) < 0) {
    tnt_stream_free(data);
    rb_raise(rb_eNoMemError, "Can't store args");
  }

  if (tnt_call(conn->tnt, func_name, func_len, data) < 0) {
    tnt_stream_free(data);
    lwt_conn_raise_error(conn);
  }

  if (tnt_flush(conn->tnt) < 0) {
    tnt_stream_free(data);
    lwt_conn_raise_error(conn);
  }

  tnt_stream_free(data);

  req = lwt_request_create(self, reqid);
  st_insert( conn->requests, reqid, req);

  return req;
}

static VALUE
lwt_conn_read(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  VALUE req;
  struct tnt_reply *reply = tnt_reply_init(NULL);

  int rc = conn->tnt->read_reply(conn->tnt, reply);
  //printf("sync: %d, code: %d, err: %d, errno: %d, strerr: %s\n", rc, reply->sync, reply->code, tnt_error(conn->tnt), tnt_errno(conn->tnt), tnt_strerror(conn->tnt));

  if (rc == 1) {
    tnt_reply_free(reply);
    return Qnil;
  }

  if (rc == -1) {
    tnt_reply_free(reply);
    lwt_conn_raise_error(conn);
  }

  if (rc != 0) {
    tnt_reply_free(reply);
    rb_raise( lwt_eUnknownError, "read_reply() return code %d", rc);
  }

  if (st_delete(conn->requests, &reply->sync, &req) != 1) {
    int sync = reply->sync;
    tnt_reply_free(reply);
    rb_raise(lwt_eSyncError, "Bad sync id %lu in tarantool reply", sync);
  }

  lwt_request_add_reply( req, reply);

  return req;
}

/**
 * Document-class: LWTarantool::Connection
 *
 * Check if connection established.
 *
 * @example
 *   conn.connected?
 *
 * @return [Boolean]
 */
static VALUE
lwt_conn_is_connected(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  struct tnt_stream_net *sn = TNT_SNET_CAST(conn->tnt);

  if (sn->connected)
    return Qtrue;
  else
    return Qfalse;
}

static VALUE
lwt_conn_error(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  return rb_uint2inum(tnt_error(conn->tnt));
}

static VALUE
lwt_conn_errno(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  return rb_uint2inum(tnt_errno(conn->tnt));
}

static VALUE
lwt_conn_strerror(VALUE self) {
  lwt_conn_t * conn;
  Data_Get_Struct(self, lwt_conn_t, conn);

  return rb_str_new_cstr(tnt_strerror(conn->tnt));
}

void init_conn() {
  /*
   * Document-class: LWTarantool::Connection
   *
   * Class for work with Tarantool connections
   */
  VALUE cClass = rb_define_class_under( lwt_Class, "Connection", rb_cObject);

  rb_const_set( lwt_Class, rb_intern("TNT_EFAIL"), rb_uint2inum(TNT_EFAIL));
  rb_const_set( lwt_Class, rb_intern("TNT_EMEMORY"), rb_uint2inum(TNT_EMEMORY));
  rb_const_set( lwt_Class, rb_intern("TNT_ESYSTEM"), rb_uint2inum(TNT_ESYSTEM));
  rb_const_set( lwt_Class, rb_intern("TNT_EBIG"), rb_uint2inum(TNT_EBIG));
  rb_const_set( lwt_Class, rb_intern("TNT_ESIZE"), rb_uint2inum(TNT_ESIZE));
  rb_const_set( lwt_Class, rb_intern("TNT_ERESOLVE"), rb_uint2inum(TNT_ERESOLVE));
  rb_const_set( lwt_Class, rb_intern("TNT_ETMOUT"), rb_uint2inum(TNT_ETMOUT));
  rb_const_set( lwt_Class, rb_intern("TNT_EBADVAL"), rb_uint2inum(TNT_EBADVAL));
  rb_const_set( lwt_Class, rb_intern("TNT_ELOGIN"), rb_uint2inum(TNT_ELOGIN));

  rb_define_alloc_func(cClass, lwt_conn_alloc);
  rb_define_method(cClass, "initialize", lwt_conn_initialize, 1);
  rb_define_private_method(cClass, "_connect", lwt_conn_connect, 0);
  rb_define_private_method(cClass, "_disconnect", lwt_conn_disconnect, 0);
  rb_define_private_method(cClass, "_error", lwt_conn_error, 0);
  rb_define_private_method(cClass, "_errno", lwt_conn_errno, 0);
  rb_define_private_method(cClass, "_strerror", lwt_conn_strerror, 0);
  rb_define_private_method(cClass, "_call", lwt_conn_call, 2);
  rb_define_private_method(cClass, "_read", lwt_conn_read, 0);

  rb_define_method(cClass, "connected?", lwt_conn_is_connected, 0);
}
