/SCA/sca_gtm/64Bit/extcall/htm.sl
scinit: void sch_init(I:xc_int_t,I:xc_int_t,I:xc_int_t,I:xc_int_t,I:xc_int_t,IO:xc_char_t *,IO:xc_int_t *)
scsndmsg: void sch_send_message(I:xc_char_t *,IO:xc_char_t *,IO:xc_int_t *)
scgetmsg: void sch_get_message(IO:xc_char_t *,IO:xc_int_t *)
scstat: void sch_status(IO:xc_char_t *,IO:xc_int_t *)
scclose: void sch_close(IO:xc_int_t *)
scbufdat: void sch_buffer_data(I:xc_int_t,O:xc_int_t *,O:xc_int_t *,O:xc_int_t *,IO:xc_char_t *,IO:xc_int_t *)
scshtdwn: void sch_shutdown(IO:xc_int_t *)
thclose: void thread_close(IO:xc_int_t *)
thcnnct: void thread_connect(I:xc_char_t *,IO:xc_int_t *)
thgetmsg: void thread_get_message(IO:xc_char_t *,IO:xc_int_t *)
threply: void thread_reply(I:xc_char_t *,IO:xc_int_t *)
