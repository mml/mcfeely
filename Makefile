# vi:ts=8:sw=8:noet:


SOURCES	= attempt_tasks.pl do_select.pl files.pl jobs.pl log.pl \
	  mcfeely-manage mcfeely-queue.c mcfeely.h \
	  read_results.pl safe_to_exit.pl tasks.pl hostport.c hostport.h mcfeely-ttpc.c \
	  exit-codes.h make-mcfeely-pm.c

OBJECTS = mcfeely-queue.o trigger.o fn.o pid.o copy_to_null.o \
	  copy_bytes.o safe_read.o safe_write.o mcfeely-ttpc.o hostport.o \
	  make-mcfeely-pm.o mcfeely-ttpd.o

TARGETS	= mcfeely-queue test-queue mcfeely-ttpc mcfeely-ttpd make-mcfeely-pm McFeely.pm

CC	= gcc
#CFLAGS	= -Wall -O6
CFLAGS	= -g -Wall
#LDFLAGS	= -s

all: $(TARGETS)

test:
	perl -cw mcfeely-manage

mcfeely-queue: mcfeely-queue.o trigger.o fn.o pid.o copy_to_null.o \
	copy_bytes.o safe_read.o safe_write.o

mcfeely-queue.o: trigger.h fn.h copy_to_null.h mcfeely-queue.h \
	copy_bytes.h safe_read.h safe_write.h

pid.o: fn.h

copy_bytes.o: mcfeely-queue.h

mcfeely-ttpc: mcfeely-ttpc.o hostport.o
	$(CC) $(LDFLAGS) $^ -o $@ $(LOADLIBES) -lknetstring

mcfeely-ttpc.o: hostport.h

mcfeely-ttpd: mcfeely-ttpd.o
	$(CC) $(LDFLAGS) $^ -o $@ $(LOADLIBES) -lknetstring

mcfeely-ttpd.o: exit-codes.h mcfeely.h

make-mcfeely-pm.o: mcfeely.h

McFeely.pm: make-mcfeely-pm
	./make-mcfeely-pm > McFeely.pm

tags: *.c *.h
	ctags *.c *.h

clean:
	rm -f $(TARGETS) $(OBJECTS) tags

print:
	nenscript -1R $(SOURCES)
