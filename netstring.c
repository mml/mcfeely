#include <unistd.h>

int
read_size(fd)
int fd;
{
    int size = 0;
    char c;

    for (;;) {
        if (read(fd, &c, 1) != 1) return -1;
        if (c == ':') return size;
        size = 10 * size + (c - '0');
    }
}

void
read_comma(fd)
int fd;
{
    char c;

    if (read(fd, &c, 1) != 1) _exit(1);
    if (c != ',') _exit(1);
}
