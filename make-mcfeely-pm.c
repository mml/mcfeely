#include <stdio.h>

#include "mcfeely.h"

void
main(void)
{
    printf("package McFeely;\n\n");
    printf("use McFeely::Task;\n");
    printf("use McFeely::Metatask;\n");
    printf("use McFeely::Job;\n\n");
    printf("$TOPDIR = \"%s\";\n\n", mcfeely_topdir);
    printf("1;\n");
    fflush(stdout);
    _exit(0);
}
