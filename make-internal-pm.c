#include <stdio.h>

#include "mcfeely.h"

void
main(void)
{
    printf("package McFeely::Internal;\n\n");
    printf("require Exporter;\n\n");
    printf("@ISA = qw( Exporter );\n\n");
    printf("use lib '%s/lib/perl';\n\n", mcfeely_topdir);
    printf("1;\n");
    fflush(stdout);
    _exit(0);
}
