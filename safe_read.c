#include <unistd.h>

void
safe_read(fd, buf, count)
int fd;
void *buf;
size_t count;
{
    if (read(fd, buf, count) != count) _exit(1);
}
