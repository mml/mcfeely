#include <stdio.h>
#include <knetstring.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>

#include "mcfeely.h"
#include "exit-codes.h"

int tube[2];

void
log(msg, len)
char *msg;
int len;
{
    if (write(2, msg, len) != len) _exit(0);
}

void
exit_read(void)
{
    log("read error", 10);
    _exit(0);
}

void
exit_write(void)
{
    log("write error", 11);
    _exit(0);
}

void
copy_tube(void)
{
    char *msg;
    int len;

    msg = (char *)malloc(4096);
    if (msg == 0) {
        log("out of memory", 13);
        write(1, "0:,", 3);
        return;
    }

    len = read(tube[0], msg, 4096);
    if (len < 0) {
        log("read error", 10);
        write(1, "0:,", 3);
        return;
    }
    if (knswrite(1, msg, len) == -1) log("write error", 11);
}

void
Z(msg, len)
char *msg;
int len;
{
    if (write(1, "Z", 1) != 1) exit_write();
    if (knswrite(1, msg, len) == -1) exit_write();
}

void
F(msg, len)
char *msg;
int len;
{
    if (write(1, "F", 1) != 1) exit_write();
    if (knswrite(1, msg, len) == -1) exit_write();
}

void
K_tube(void)
{
    if (write(1, "K", 1) != 1) exit_write();
    copy_tube();
}

void
Z_tube(void)
{
    if (write(1, "Z", 1) != 1) exit_write();
    copy_tube();
}

void
F_tube(void)
{
    if (write(1, "F", 1) != 1) exit_write();
    copy_tube();
}

int
secret_match(buf)
knsbuf_t buf;
{
    char *secret;
    int fd;
    int i;

    secret = (char *)malloc(buf.len);
    if (secret == 0) _exit(0);
    fd = open("control/mysecret", O_RDONLY);
    if (fd == -1) return 0;
    i = read(fd, secret, buf.len);
    if (i != buf.len) return 0;
    close(fd);
    for (i = 0; i < buf.len; ++i)
        if (((char *)buf.start)[i] != secret[i]) return 0;
    return 1;
}

void
check_safe(buf)
knsbuf_t buf;
{
    for ( ; *(char *)buf.start != '\0'; ++buf.start)
        if (*(char *)buf.start == '/') {
            F("unsafe comm", 11);
            _exit(0);
        }
}

void
find_nulls(buf, args)
knsbuf_t buf;
char *args[];
{
    int n;
    int i;
    char *s;

    /* XXX: I think maybe we can bum some instructions or variables here, but I
     * haven't analyzed it closely enough yet.  mml
     */
    n = 1;
    s = (char *)buf.start;
    for (i = 0; i < buf.len; ++i)
        if (((char *)buf.start)[i] == '\0') {
            args[n++] = s;
            s = (char *)buf.start + i + 1;
        }
}

void
main(void)
{
    knsbuf_t buf = {0,0,0};
    unsigned int tasknum;
    unsigned int junk;
    char *args[256];
    int status;

    if (chdir(mcfeely_topdir) == -1) _exit(0);
    if (pipe(tube) == -1) _exit(0);

    if (knsbread(0, &buf) == -1) _exit(0);
    if (! knsbuf_terminate(&buf)) _exit(0);
    if (! secret_match(buf)) _exit(0);
    if (read(0, &tasknum, 4) != 4) exit_read();
    fprintf(stderr, "task %d\n", tasknum);
    if (read(0, &junk, 4) != 4)    exit_read();
    if (read(0, &junk, 4) != 4)    exit_read();
    buf.len = 0;
    if (knsbread(0, &buf) == -1)   exit_read();
    check_safe(buf);
    args[0] = buf.start;
    find_nulls(buf, args);
    
    if (chdir("comm") == -1) _exit(0);

    switch (fork()) {
        case -1: _exit(0); break;

        case 0:
            close(0);
            close(tube[0]);
            dup2(tube[1], 1);
            execv(args[0], args);
            F("program not found", 17);
            break;
    }

    close(tube[1]);
    (void)wait(&status);

    fprintf(stderr, "exit status %d\n", WEXITSTATUS(status));
         if (! WIFEXITED(status))              Z("program abended", 15);
    else if (WEXITSTATUS(status) == 0)         K_tube();
    else if (WEXITSTATUS(status) == EXIT_SOFT) Z_tube();
    else                                       F_tube();
}
