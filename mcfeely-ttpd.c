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

#include <stdio.h>
#include <knetstring.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <syslog.h>

#include "mcfeely.h"
#include "exit-codes.h"

int tube[2];

void
exit_read(void)
{
    syslog(LOG_ERR, "error reading from ttpc");
    _exit(0);
}

void
exit_write(void)
{
    syslog(LOG_ERR, "error writing to ttpc");
    _exit(0);
}

void
copy_tube(void)
{
    char *msg;
    int len;

    msg = (char *)malloc(4096);
    if (msg == 0) {
        syslog(LOG_ERR, "out of memory in copy_tube");
        write(1, "0:,", 3);
	free(msg);
        return;
    }

    len = read(tube[0], msg, 4096);
    if (len < 0) {
        syslog(LOG_ERR, "read error in copy_tube");
        write(1, "0:,", 3);
	free(msg);
        return;
    }
    if (knswrite(1, msg, len) == -1)
        syslog(LOG_ERR, "write error in copy_tube");
    free(msg);
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
    if (fd == -1) {
	    free(secret); 
	    return 0;
    }
    i = read(fd, secret, buf.len);
    if (i != buf.len) {
	    free(secret);
	    return 0;
    }
    close(fd);
    for (i = 0; i < buf.len; ++i)
        if (((char *)buf.start)[i] != secret[i]) {
		free(secret);
		return 0;
	}
    free(secret);
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
    char skipfirst = 1;
    char *s;

    /* XXX: I think maybe we can bum some instructions or variables here, but I
     * haven't analyzed it closely enough yet.  mml
     */
    n = 1;
    s = (char *)buf.start;
    for (i = 0; i < buf.len; ++i)
        if (((char *)buf.start)[i] == '\0') {
            if (skipfirst) {
                skipfirst = 0;
            } else {
                args[n++] = s;
            }
            s = (char *)buf.start + i + 1;
        }
    args[n] = NULL;
}

int
main(void)
{
    knsbuf_t buf = {0,0,0};
    unsigned int tasknum;
    unsigned int junk;
    char *args[256];
    int status;

    /* let's make the connection to syslog */
    openlog("mcfeely-ttpd", LOG_PID, LOG_DAEMON);

    if (chdir(mcfeely_topdir) == -1) {
        syslog(LOG_ERR, "unable to chdir %s", mcfeely_topdir);
        _exit(0);
    }

    if (pipe(tube) == -1) {
        syslog(LOG_ERR, "unable to create pipe");
        _exit(0);
    }

    if (knsbread(0, &buf) == -1) _exit(0);
    if (! knsbuf_terminate(&buf)) _exit(0);
    if (! secret_match(buf)) _exit(0);
    if (read(0, &tasknum, 4) != 4) exit_read();
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
            dup2(tube[1], 2);
            dup2(tube[1], 1);
            execv(args[0], args);
            write(1, "program not found", 17);
            _exit(EXIT_HARD);
    }

    close(tube[1]);
    (void)wait(&status);

    syslog(LOG_INFO, "tasknum:%d comm:%s exit:%d",
                      tasknum, args[0], WEXITSTATUS(status));

         if (! WIFEXITED(status))              Z("program abended", 15);
    else if (WEXITSTATUS(status) == 0)         K_tube();
    else if (WEXITSTATUS(status) == EXIT_SOFT) Z_tube();
    else                                       F_tube();

    /* quite warnings, be clean */
    exit(0);
}
