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

#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

#include "mcfeely-queue.h"
#include "mcfeely.h"
#include "trigger.h"
#include "fn.h"
#include "pid.h"
#include "copy_to_null.h"
#include "copy_bytes.h"
#include "safe_read.h"
#include "safe_write.h"

void
get_hcas(void)
{
    unsigned int bytes;

    while (read(0, &bytes, sizeof(bytes)) == sizeof(bytes)) {
        pidopen();
        pidstat();
        copy_bytes(bytes, 0, pidfd);
        close(pidfd);
        fnmake_int("task/", pidst.st_ino);
        pidrename();
        ino[ino_num++] = pidst.st_ino;
    }
    close(0);
}

void
get_info(void)
{
    int i;
    char num;

    for (i = 0; i < ino_num; ++i) {
        fnmake_int("info/", ino[i]);
        fncreat();
        safe_write(fnfd, "", 1);                      /* write flag byte */
        safe_read(1, &buf, 1);                        /* read ndeps byte */
        safe_write(fnfd, &buf, 1);                    /* write ndeps byte */
        for (safe_read(1, &num, 1); num > 0; --num) { /* write waiters */
            safe_read(1, &buf, 1);
            if (buf[0] >= ino_num) _exit(1);
            safe_write(fnfd, &(ino[(int)buf[0]]), sizeof(ino_t));
        }
        close(fnfd);
    }
    close(1);
}

void
get_desc(void)
{
    pidopen();
    pidstat();
    job_ino = pidst.st_ino;
    copy_to_null(2, pidfd);
    close(pidfd);
    fnmake_int("desc/", job_ino);
    pidrename();
}

void
get_snot(void)
{
    fnmake_int("snot/", job_ino);
    fncreat();
    copy_to_null(2, fnfd);
    close(fnfd);
}

void
get_fnot(void)
{
    fnmake_int("fnot/", job_ino);
    fncreat();
    copy_to_null(2, fnfd);
    close(fnfd);
}

void
write_job(void)
{
    int i;

    pidopen();
    safe_write(pidfd, "", 1);
    for (i = 0; i < ino_num; ++i)
        safe_write(pidfd, &(ino[i]), sizeof(ino_t));
    fnmake_int("newj/", job_ino);
    pidrename();
}

void
main(void)
{
    umask(033);
    if (chdir(mcfeely_topdir) == -1) _exit(1);
    if (chdir("queue") == -1) _exit(1);

    pidfnmake();

    get_hcas();
    get_info();
    get_desc();
    get_fnot();
    get_snot();
    close(2);
    write_job();
    pull_trigger();
    _exit(0);
}
