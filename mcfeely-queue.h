#include <sys/stat.h>
#include <unistd.h>

#define BUFSIZE 1024

char buf[BUFSIZE];
ino_t job_ino;
ino_t ino[256];
int ino_num;

