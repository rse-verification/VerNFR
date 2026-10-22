static int timer;

void tmon_init(void);

/*@
  requires 0 <= timer <= 10;
  ensures Req1: // no error detected by sensor
    rtdb_tmon_sens == 0 ==>
    timer == \max(0, \old(timer - 1));
  ensures Req2: // error detected by sensor
    rtdb_tmon_sens != 0 ==> 
    timer == \min(\old(timer + 1), 10);
  ensures Req3: // activate warning
    timer == 10 ==> rtdb_tmon_warn == 1;
  ensures Req4: // deactivate warning
    timer == 0 ==>  rtdb_tmon_warn == 0;
  ensures Req5: // keep warning
    0 < timer < 10 ==> 
    rtdb_tmon_warn == \old(rtdb_tmon_warn); 
*/
int tmon_step(void);
