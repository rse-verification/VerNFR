/* run.config
   DEPS: utils.h
   FILTER: sed -E 's/\([0-9]+ms(-[0-9]+ms)*\)//g'
   FILTER: sed -E 's/Alt-Ergo [0-9]+\.[0-9]+\.[0-9]+/Alt-Ergo/g'
   OPT: -wp -wp-rte
*/
#include "limits.h"
#include "utils.h"

int update_sat(int cond, int timer, int min, int max) {
  int res = timer;
  if (cond) {res += 1;} else {res -= 1;}
  if (res > max) res = max;
  if (res < min) res = min; 
  return res;
}
