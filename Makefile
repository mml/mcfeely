# vi:ts=8:sw=8:noet:


SOURCES	= attempt_tasks.pl do_select.pl files.pl jobs.pl log.pl \
	  mcfeely-manage mcfeely-queue.c mcfeely.h \
	  read_results.pl safe_to_exit.pl tasks.pl

OBJECTS = mcfeely-queue.o trigger.o fn.o pid.o copy_to_null.o \
	  copy_bytes.o safe_read.o safe_write.o

TARGETS	= mcfeely-queue test-queue

CC	= gcc
LD	= gcc
FLAGS	= -Wall -g

all: $(TARGETS)

mcfeely-queue: $(OBJECTS)

mcfeely-queue.o: trigger.h fn.h copy_to_null.h mcfeely-queue.h \
	copy_bytes.h safe_read.h safe_write.h

pid.o: fn.h

copy_bytes.o: mcfeely-queue.h

tags: *.c *.h
	ctags *.c *.h

clean:
	rm -f $(TARGETS) $(OBJECTS) tags

print:
	nenscript -1R $(SOURCES)
