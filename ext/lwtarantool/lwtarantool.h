#include <ruby.h>
#include <tarantool/tnt_reply.h>
#include <tarantool/tnt_stream.h>

extern VALUE lwt_Class;

extern VALUE lwt_eError;
extern VALUE lwt_eLoginError;
extern VALUE lwt_eResolvError;
extern VALUE lwt_eSyncError;
extern VALUE lwt_eSystemError;
extern VALUE lwt_eTimeoutError;
extern VALUE lwt_eUnknownError;


typedef struct {
    VALUE mutex;
    struct tnt_stream *tnt;
    st_table *requests;
} lwt_conn_t;

typedef struct {
    VALUE conn;
    uint64_t id;
    struct tnt_reply *reply;
} lwt_request_t;

VALUE lwt_request_create( VALUE conn, uint64_t id);
void lwt_request_add_reply( VALUE self, struct tnt_reply *reply);

void init_conn();
void init_request();
void init_errors();
