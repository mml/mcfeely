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

#include "mcfeely-queue.h"
#include <errno.h>

void
copy_bytes(num, src, dest)
int num;
int src;
int dest;
{
    int want;
    int got_read;
    int got_write;
    char copy_buf[BUFSIZE];

    /* get data from the pipe about a particular single task
       try and effectively deal with the PIPE not necessarily
       being friendly nor helpful in the way it is providing 
       us data -cjd 2000.0717 */

    want = BUFSIZE;

    /* read in a chunk of data until there's none left to read
       or we get an error. I think we are going to loop forever
       here if get an EOF, but how are we going to get that? 
       XXX */
    while (num) {
        if (num < BUFSIZE) want = num;
        got_read = read(src, &copy_buf, want);
        if (got_read < 0) {
            if (errno != EAGAIN) {
                /* could print errors here but there's nowhere
                   for them to go, we are already using STDERR
                   -cjd */
                _exit(1);
            }
        } else {
            want = got_read; 
            got_write = write(dest, &copy_buf, want);
            if (got_write != want) {
                /* could print errors here but there's nowhere
                   for them to go, we are already using STDERR
                   -cjd */
                _exit(1);
            }
            num -= got_read;
        }
    }

}

