/* run.config
   DEPS: utils.h
   FILTER: sed -E -e 's/\([0-9]+ms(-[0-9]+ms)*\)//g' -e 's/^  Alt-Ergo[^:]*:/  Alt-Ergo:/' -e 's/^  ([A-Za-z][A-Za-z -]*[A-Za-z]):[[:space:]]+/  \1: /' -e 's/[[:space:]]+$//' -e '/^\[wp\] \[Cache\]/d'
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
