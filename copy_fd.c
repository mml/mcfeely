#include <unistd.h>

#include "mcfeely-queue.h"

void
copy_fd(src, dest)
int src;
int dest;
{
    int got;

    do {
        got = read(src, &buf, BUFSIZE);
        if (write(dest, &buf, got) != got) _exit(1);
    } while (got == BUFSIZE);
}
