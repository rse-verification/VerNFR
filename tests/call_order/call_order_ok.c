/* run.config
   DEPS: devices.h call_order.is
   STDOPT: +"-nfr-ispec call_order.is" +"-nfr-check-calls" +"-nfr-external-call-order" +"-nfr-no-call-order-wp" +"-keep-unused-functions" +"all" +"-keep-unused-types"
*/

#include "devices.h"

void system_init(void) {
  power_on();
  configure();
  calibrate();
}

void system_run(void) {
  int value = sample();
  publish(value);
}

void system_shutdown(void) {
  power_off();
}
