/* run.config
   DEPS: entry_order_cycle.is
   STDOPT: +"-nfr-ispec entry_order_cycle.is" +"-nfr-check-calls" +"-nfr-external-call-order" +"-nfr-no-call-order-wp" +"-keep-unused-functions" +"all" +"-keep-unused-types"
*/

void cycle_a(void) {
}

void cycle_b(void) {
}
