#include <unistd.h>

int main()
{
  /* Wake every 60 seconds and check for our parent. If we were
   * inherited by init our parent is gone so we can go too. We have to
   * do this because sshd puts us in our own session so we don't
   * automatically respond to the exit of our parent.  
   */
  for(;;) {
    sleep(60);
    if (getppid() == 1)      
      return 0;
  }
  /* We fell out of our loop! Shouldn't happen. */
  return 1;
}
