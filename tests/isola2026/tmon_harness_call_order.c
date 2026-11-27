/* run.config
   DONTRUN:
*/

#include "sensors.h"
#include "warnings.h"
#include "utils.h"

static int timer;

//@ ghost int call_tmon_sens_create = 0;
//@ ghost int call_tmon_warn_create = 0;

/*@
  ensures call_tmon_sens_create == \old(call_tmon_sens_create);
  ensures call_tmon_warn_create == \old(call_tmon_warn_create);
*/
int tmon_sens_read(void);
/*@
  ensures call_tmon_sens_create == \old(call_tmon_sens_create);
  ensures call_tmon_warn_create == \old(call_tmon_warn_create);
*/
void tmon_sens_create(void);

/*@
  ensures call_tmon_sens_create == \old(call_tmon_sens_create);
  ensures call_tmon_warn_create == \old(call_tmon_warn_create);
*/
void tmon_warn_create(void);
/*@
  ensures call_tmon_sens_create == \old(call_tmon_sens_create);
  ensures call_tmon_warn_create == \old(call_tmon_warn_create);
*/
void tmon_warn_write(int);


void tmon_init(void){
  timer = 5;
  tmon_sens_create();
  //@ ghost call_tmon_sens_create = 1;

  tmon_warn_create();
  //@ ghost call_tmon_warn_create = 1;
}

void tmon_step(void){
  int s = tmon_sens_read();

  //@ assert(call_tmon_sens_create == 1);
  timer = update_sat(s,timer,0,10);
  if (timer == 10) {
    // activate warning
    tmon_warn_write(1);
    //@ assert(call_tmon_warn_create == 1);
  } else if (timer == 0) {
    // deactivate warning
    tmon_warn_write(0);
    //@ assert(call_tmon_warn_create == 1);
  } else {
    // do nothing
  }
}

void harness(void) {
  tmon_init();
  tmon_step();
}
