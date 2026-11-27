/* run.config
   DEPS: entry_order_empty.is
   STDOPT: +"-nfr-ispec entry_order_empty.is" +"-nfr-check-calls" +"-nfr-external-call-order" +"-keep-unused-functions" +"all" +"-keep-unused-types"
   STDOPT: +"-nfr-ispec entry_order_empty.is" +"-nfr-check-calls" +"-nfr-external-call-order" +"-nfr-no-call-order-wp" +"-nfr-call-order-print" +"-keep-unused-functions" +"all" +"-keep-unused-types"
*/

void empty_a(void) {
}

void empty_b(void) {
}
