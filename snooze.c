#include <unistd.h>

void main(void)
{
	pause(); /* suspend self until killed by almost any signal
                 ** see signal(7)
                 */
}
