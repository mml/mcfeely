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
