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
** You may contact the author at <mml@pobox.com>.
*/

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
