#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>

char *fn = 0;
unsigned int fnsize = 0;
int fnfd;

void
fnsize_atleast(size)
int size;
{
    if (fnsize < size) {
        free(fn);
        fn = malloc(size);
        if (fn == 0) _exit(1);
    }
}

void
fnmake_int(one, two)
char *one;
int two;
{
    int size;

    size = strlen(one);
    fnsize_atleast(size+11);
    strcpy(fn, one);
    snprintf(fn+size, 10, "%d", two);
}

void
fncreat(void)
{
    fnfd = creat(fn, 0644);
    if (fnfd == -1) _exit(1);
}
