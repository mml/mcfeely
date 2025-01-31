/* mcfeely        Asynchronous remote task execution.
** Copyright (C) 1999 Kiva Networking
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public License
** as published by the Free Software Foundation; either version 2
** of the License, or (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
**
** You may contact the maintainer at <mcfeely-maintainer@systhug.com>.
*/

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


int
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
    if (s == -1) soft("cannot open socket", 18);


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

    /* this right here deserves a comment because although
       it isn't immediately clear, this is the crux of the
       biscuit, this takes the entire contents of STDIN and
       writes it to the socket */
    if (knsfwrite(s, 0) == -1)       soft_write();

    /* recv: response */
    if (read(s, &code, 1) != 1)  soft_read();
    if (knsbread(s, &buf) == -1) soft_read();

    switch (code) {
        case 'K': ok(buf.start, buf.len);   break;
        case 'Z': soft(buf.start, buf.len); break;
        case 'F': hard(buf.start, buf.len); break;
        default:  hard("garbled report", 14);
    }
    /* shouldn't be able to reach here, but it shuts up a warning */
    exit(0);
}
