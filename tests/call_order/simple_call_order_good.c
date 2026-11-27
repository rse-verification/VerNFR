/* run.config
   DEPS: extern_defs.h simple_call_order.is
   STDOPT: +"-nfr-ispec simple_call_order.is" +"-nfr-check-calls" +"-nfr-external-call-order" +"-nfr-no-call-order-wp" +"-keep-unused-functions" +"all" +"-keep-unused-types"
*/

#include "extern_defs.h"

void f_init(void) {
  foo();
  bar();
}

void f_main(void) {
  bar();
  foo(); 
  /* shouldnt care if foo called after bar, only care if bar is 
    ever called before first invocation of foo */
}
