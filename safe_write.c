#include <unistd.h>

void
safe_write(fd, buf, count)
int fd;
const void *buf;
size_t count;
{
    if (write(fd, buf, count) != count) _exit(1);
}
