/* run.config
   DEPS: utils.h sensors.h warnings.h tmon.is
   STDOPT: +"-nfr-ispec" +"tmon.is" +"-nfr-check-calls" +"-nfr-fun-ptrs" +"-nfr-no-fun-defs" +"-nfr-all-entries-defined" +"-nfr-only-entries" +"-nfr-static-vars" +"-nfr-proper-init" +"-nfr-check-ptr-literals" +"-nfr-typedefs"
*/
#include "sensors.h"
#include "warnings.h"
#include "utils.h"

int timer;

void tmon_init(void){
  tmon_sens_create();
}

static void tmon_step(void){
  int s = tmon_sens_read();
  timer = update_sat(s,timer,0,10);
  if (timer == 10) { 
    // activate warning
    tmon_warn_write(1);
  } else if (timer == 0) { 
    // deactivate warning
    xmon_warn_write(0);
  }
}

int get_tmon_timer(void) {
  return timer;
}
