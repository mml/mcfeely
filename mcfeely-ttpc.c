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

#define HOST (argv[1])
#define TASKID (argv[2])

void   ok(char *m, int l) { write(1, m, l); exit(  0); }
void soft(char *m, int l) { write(1, m, l); exit( 99); }
void hard(char *m, int l) { write(1, m, l); exit(100); }

void soft_write(void) { soft("write failure", 13); }
void soft_read(void)  { soft("read failure",  12); }

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

void
main(argc, argv)
int argc;
char *argv[];
{
    int pfd;
    int tfd;
    knsbuf_t buf = {0, 0, 0};
    char *realhost;
    int realport;
    int s;
    struct hostent *ent;
    struct protoent *tcp;
    struct sockaddr_in sin;
    unsigned int tasknum;
    char code;

    bzero(&sin, sizeof(sin));

    /* open secret file */
    pfd = open("control/secret", O_RDONLY);
    if (pfd == -1) soft("cannot open control/secret", 26);

    /* open task file */
    tfd = task_open(TASKID);
    if (tfd == -1) soft("cannot open task", 16);

    /* tcp socket */
    tcp = getprotobyname("tcp");
    s = socket(AF_INET, SOCK_STREAM, tcp->p_proto);

    /* get real hostname and port */
    if (! hostport(&realhost, &realport, HOST))
        soft("cannot find host in control/hosts", 33);

    /* lookup in DNS */
    ent = gethostbyname(realhost);
    if (!ent) soft("cannot find host", 16);
    if (!ent->h_addr) soft("host has no address", 19);

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
    if (knsfwrite(s, tfd) == 1)       soft_write();

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
