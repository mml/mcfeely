#include <unistd.h>
#include <fcntl.h>

/* open the trigger, write a byte, close it -- all nonblocking */
void
pull_trigger(void)
{
    int fd;

    fd = open("trigger", O_WRONLY | O_NDELAY);
    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
    write(fd, "", 1);
    close(fd);
}
