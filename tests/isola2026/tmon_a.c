#include "sensors.h"
#include "warnings.h"
#include "utils.h"

static int timer;

void tmon_init(void){
  timer = 5; 
  tmon_sens_create();
  tmon_warn_create();
}

void tmon_step(void){
  int s = tmon_sens_read();
  timer = update_sat(s,timer,0,10);
  if (timer == 10) { 
    // activate warning
    tmon_warn_write(1);
  } else if (timer == 0) { 
    // deactivate warning
    tmon_warn_write(0);
  } else {
    // do nothing
  }
}
