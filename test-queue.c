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

#include <sys/types.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
extern char** environ;

void
main(void)
{
    int pid;
    int st;
    unsigned int nbytes;

    int pipe0[2];
    int pipe1[2];
    int pipe2[2];

    pipe(pipe0);
    pipe(pipe1);
    pipe(pipe2);

    pid = fork();

    switch(pid) {
        case 0:
            close(pipe0[1]);
            if (dup2(pipe0[0], 0) == -1) perror("dup2 0");
            close(pipe1[1]);
            if (dup2(pipe1[0], 1) == -1) perror("dup2 1");
            close(pipe2[1]);
            if (dup2(pipe2[0], 2) == -1) perror("dup2 2");
            /* execlp("mcfeely-queue", "mcfeely-queue"); */
            execve("./mcfeely-queue", 0, environ);
            _exit(errno);
            break;

        case -1:
            _exit(2);
            break;

        default:
            close(pipe0[0]);
            close(pipe1[0]);
            close(pipe2[0]);
            nbytes = 18;
            write(pipe0[1], &nbytes, sizeof(nbytes));
            write(pipe0[1], "sherrill\0test\0baz\0", 18);
            nbytes = 19;
            write(pipe0[1], &nbytes, sizeof(nbytes));
            write(pipe0[1], "sherrill\0test\0quux\0", 19);
            close(pipe0[1]);
            write(pipe1[1], "\x01" "\x00" "\x00" "\x01" "\x00", 5);
            close(pipe1[1]);
            write(pipe2[1], "Your mom.\0", 10);
            write(pipe2[1], "mliggett@kiva.net\0", 18);
            write(pipe2[1], "mliggett@kiva.net\0", 18);
            close(pipe2[1]);
            break;

    }

    pid = wait(&st);

    _exit(WEXITSTATUS(st));
}
