#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <unistd.h>

void
main(void)
{
    int pid;
    int st;

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
            write(pipe0[1], "12:foo\0bar\0baz\0,13:bar\0baz\0quux\0,", 33);
            close(pipe0[1]);
            /* XXX: my literals are broken here? */
            write(pipe1[1], "\x010:,\x001:\x00,", 9);
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
