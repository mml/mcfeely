#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "fn.h"

struct stat pidst;
char pidfn[15]; /* 3(pid) + 1(/) + 10(the number) + 1(NULL) */
int pidfd;

void
pidfnmake(void)
{
    strcpy(pidfn, "pid/");
    snprintf(pidfn+4, 10, "%d", getpid());
}

void
pidopen(void)
{
    pidfd = creat(pidfn, 0644);
    if (pidfd == -1) _exit(1);
}

void
pidstat(void)
{
    if (fstat(pidfd, &pidst) == -1) _exit(1);
}

void
pidrename(void)
{
    if (rename(pidfn, fn) == -1) _exit(1);
}
