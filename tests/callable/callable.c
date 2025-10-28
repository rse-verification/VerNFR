/* run.config
   DEPS: extern_defs.h callable_spec.is
   STDOPT: +"-nfr-ispec callable_spec.is" 
*/

#include "extern_defs.h"

static void internal_func(void);

void main() {
    foo();
    int x = bar();
    internal_func();
}