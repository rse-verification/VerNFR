#include "rtdb.h"

void tmon_warn_create(void);

/*@ ensures rtdb_tmon_warn == v; */
void tmon_warn_write(int v);

void xmon_warn_write(int v);
