#include "mcfeely-queue.h"

void
copy_bytes(num, src, dest)
int num;
int src;
int dest;
{
    int want;
    int got;

    want = BUFSIZE;
    while (num) {
        if (num < BUFSIZE) want = num;
        got = read(src, &buf, want);
        if (got != want) _exit(1);
        got = write(dest, &buf, want);
        if (got != want) _exit(1);
        num -= got;
    }
}

