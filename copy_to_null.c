#include <unistd.h>

void
copy_to_null(src, dest)
int src;
int dest;
{
    char c;

    while (read(src, &c, 1) == 1)
        if (c == '\0') return;
        else           write(dest, &c, 1);

    _exit(1);
}
