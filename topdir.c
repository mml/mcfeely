#include <stdio.h>

#include "mcfeely.h"

void
main(void)
{
    printf("%s\n", mcfeely_topdir);
    fflush(stdout);
    _exit(0);
}
