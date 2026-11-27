/* run.config
   DEPS: extern_defs.h simple_call_order.is
   STDOPT: +"-nfr-ispec simple_call_order.is" +"-nfr-check-calls" +"-nfr-external-call-order" +"-nfr-no-call-order-wp" +"-keep-unused-functions" +"all" +"-keep-unused-types"
*/

#include "extern_defs.h"

void f_init(void) {
  bar();
}

void f_main(void) {
  foo();
}
