/* $Id: hostport.c,v 1.2 1999/07/29 20:25:26 mliggett Exp $
** vi:ts=4:sw=4:sm:ai:
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
