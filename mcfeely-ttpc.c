#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <netdb.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <knetstring.h>

#include "hostport.h"

#define TASKID (argv[1])

void   ok(char *m, int l) { write(1, m, l); exit(  0); }
void soft(char *m, int l) { write(1, m, l); exit( 99); }
void hard(char *m, int l) { write(1, m, l); exit(100); }

void soft_write(void) { soft("write failure", 13); }
void soft_read(void)  { soft("read failure",  12); }

/* given a taskid as a string, open the file on fd */
int task_open(taskid)
char *taskid;
{
    char *it;
    int len;
    int fd;

    /* "queue/task/TASKID" -- TASKID+12 */
    len = strlen(taskid) + 12;
    it = (char *)malloc(len);
    if (! it) return 0;

    snprintf(it, len, "queue/task/%s", taskid);
    fd = open(it, O_RDONLY);
    free(it);
    return fd;
}

int
secret_open(fnam)
char *fnam;
{
    char *fn;

    fn = malloc(strlen(fnam)+17); /* "control/secrets/" == 16 */
    strcpy(fn, "control/secrets/");
    strcat(fn, fnam);

    return open(fn, O_RDONLY);
}


void
main(argc, argv)
int argc;
char *argv[];
{
    int pfd;
    knsbuf_t buf = {0, 0, 0};
    char host[1024];
    char *i;
    char *realhost;
    char *secretfile;
    int realport;
    int s;
    struct hostent *ent;
    struct protoent *tcp;
    struct sockaddr_in sin;
    unsigned int tasknum;
    char code;

    bzero(&sin, sizeof(sin));

    /* tcp socket */
    tcp = getprotobyname("tcp");
    s = socket(AF_INET, SOCK_STREAM, tcp->p_proto);

    i = host;
    do {
        if (read(0, i, 1) != 1) soft("unexpected eof", 14);
    } while (*i++ != '\0');

    /* get real hostname and port */
    if (! hostport(&realhost, &realport, &secretfile, host))
        soft("cannot find host in control/hosts", 33);

    /* lookup in DNS */
    ent = gethostbyname(realhost);
    if (!ent) soft("cannot find host", 16);
    if (!ent->h_addr) soft("host has no address", 19);
    
    /* open secret file */
    pfd = secret_open(secretfile);
    if (pfd == -1) soft("cannot open secret", 18);

    /* prepare sockaddr_in */
    bcopy(ent->h_addr, &sin.sin_addr, ent->h_length);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(realport);

    /* connect */
    if (connect(s, (struct sockaddr *)&sin, sizeof(sin)) == -1)
        soft("cannot connect", 14);

    /* send: auth, taskid, UID, GID, the task */
    if (knsfwrite(s, pfd) == -1)      soft_write();
    close(pfd);
    tasknum = strtoul(TASKID, 0, 10);
    if (write(s, &tasknum, 4) != 4)   soft_write();
    if (write(s, "\0\0\0\0", 4) != 4) soft_write();
    if (write(s, "\0\0\0\0", 4) != 4) soft_write();
    if (knsfwrite(s, 0) == 1)       soft_write();

    /* recv: response */
    if (read(s, &code, 1) != 1)  soft_read();
    if (knsbread(s, &buf) == -1) soft_read();

    switch (code) {
        case 'K': ok(buf.start, buf.len);   break;
        case 'Z': soft(buf.start, buf.len); break;
        case 'F': hard(buf.start, buf.len); break;
        default:  hard("garbled report", 14);
    }
}
