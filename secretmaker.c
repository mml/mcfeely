/** $Id: secretmaker.c,v 1.1.6.1 2000/06/21 22:21:22 cdent Exp $
 *  Create a 512-bit (64 byte) secret appropriate for use as a McFeely
 *  shared secret. The secret is written into "newsecret" in the
 *  current directory.
 **/

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int main() {
  int fd, random_byte, x;

  srandom( (int)time(NULL) );

  if ((fd = open("newsecret", O_WRONLY|O_CREAT|O_EXCL, 00600)) < 0) {
    perror("cannot create \"newsecret\"");
    return 2;
  }
  for (x = 0; x < 64; x++) {  
    random_byte = 1 + (int) (256.0 * random() / (RAND_MAX + 1.0));
    if (write(fd, &random_byte, 1) != 1) {
      perror("problem writing secret value to file");
      return 2;
    }
  }
  if (write(fd, "\n", 1) != 1) {
    perror("problem writing newline into the file?? ");
    return 2;
  }
  close(fd);

  return 0;
}
