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

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* match "host host port" in the control/hosts file */
int
hostport(realhost, realport, secretfile, matchme)
char **realhost;
int *realport;
char **secretfile;
char *matchme;
{
	FILE *file;
	char *buf;
	char *word;
	int i;

	buf = (char *)malloc(1024); /* oi!  we will fail if there are more than
	                               1024 characters in this line */

	file = fopen("control/hosts", "r");
	if (file == 0) return 0;
	while (fgets(buf, 1024, file)) {
		i = 0;
		word = strtok(buf, " \t");
		if (strcmp(word, matchme) == 0) {
			word = strtok(0, " \t");
			if (! word) return 0;
			*realhost = malloc(strlen(word)+1);
			if (! *realhost) return 0;
			strcpy(*realhost, word);
			word = strtok(0, " \t");
			if (! word) {
				free(*realhost);
				*realhost = 0;
				return 0;
			}
			*realport = atoi(word);
            word = strtok(0, " \t\n");
            if (! word) {
                free(*realhost);
                *realhost = 0;
                return 0;
            }
            *secretfile = malloc(strlen(word)+1);
            if (! *secretfile) return 0;
            strcpy(*secretfile, word);
			fclose(file);
			return 1;
		}
	}
	fclose(file);
	return 0;
}
