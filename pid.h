extern struct stat pidst;
extern char *pidfn;
extern int pidfd;

void pidfnmake(void);
void pidopen(void);
void pidstat(void);
void pidrename(void);
