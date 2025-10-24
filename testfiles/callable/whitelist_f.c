#include "extern_defs.h"

static void internal_func(void);
static void internal_int_func(int x);
static int g;

void main() {
    foo();
    bar();
    internal_func();
    internal_int_func(bar());

    //Illegal stuff
    snd_foo();
    g = 3 + snd_bar();
    int v = snd_bar();
    internal_int_func(snd_bar());
}