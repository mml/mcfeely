# vi:ts=8:sw=8:noet:

PROJECT	= mcfeely

SOURCES	= attempt_tasks.pl do_select.pl files.pl jobs.pl log.pl \
	  mcfeely-manage mcfeely-queue.c mcfeely.h \
	  read_results.pl safe_to_exit.pl tasks.pl hostport.c hostport.h \
	  mcfeely-ttpc.c exit-codes.h make-mcfeely-pm.c

OBJECTS = mcfeely-queue.o trigger.o fn.o pid.o copy_to_null.o \
	  copy_bytes.o safe_read.o safe_write.o mcfeely-ttpc.o hostport.o \
	  make-mcfeely-pm.o mcfeely-ttpd.o make-chdir-pl.o

TARGETS	= mcfeely-queue test-queue mcfeely-ttpc mcfeely-ttpd make-mcfeely-pm \
	  McFeely.pm topdir mcfeely.h make-chdir-pl chdir.pl

ROOTUSER = $(shell cat ROOTUSER)
MCUSER   = $(shell cat MCUSER)
MCGROUP  = $(shell cat MCGROUP)
QGROUP   = $(shell cat QGROUP)

CC	= gcc

# use these for building fast production binaries
#CFLAGS  = -Wall -O6
#LDFLAGS = -s

# use this for building debuggable binaries
CFLAGS   = -g -Wall

RPMDIR      = $(shell \
		perl -e \
			'for $$f (@ARGV) { \
				next unless open F, $$f; \
				while (<F>) { \
					chomp; \
					($$k, $$v) = split /\s*:\s+/, $$_ ,2; \
					$$t = $$v if $$k eq "topdir"; \
				} \
			} \
			print"$$t\n"' \
			/usr/lib/rpmrc /usr/lib/rpm/rpmrc /etc/rpmrc $$HOME/.rpmrc)
VERSION		= $(shell cat version)
EVERYTHING	= $(shell cat MANIFEST)
DIST		= $(PROJECT)-$(VERSION)
TARFILE		= $(DIST).tar.gz
SPECFILE	= $(PROJECT).spec
RPMFILE		= $(RPMDIR)/RPMS/i386/$(DIST)-1.i386.rpm
SRPMFILE	= $(RPMDIR)/SRPMS/$(DIST)-1.src.rpm
FTPLOC		= sysftp.kiva.net:~ftp/pub/kiva/RPMS/i386

.PHONY: all install rpminstall dist rpm ftp clean
.INTERMEDIATE: $(SPECFILE) PERLDIR

all: $(TARGETS)

install: all PERLDIR
	for i in '' /bin /comm /control; do \
		install -o $(ROOTUSER) -g $(MCGROUP) -m 0755 -d `./topdir`$$i ;\
	done

	install -o $(MCUSER) -g $(QGROUP) -m 4510 mcfeely-queue `./topdir`/bin

	for i in mcfeely-manage mcfeely-spawn mcfeely-ttpc mcfeely-ttpd; do \
		install -o $(ROOTUSER) -g $(MCGROUP) -m 0550 $$i `./topdir`/bin ;\
	done

	for i in '' /pid /task /info /desc /newj /job /fnot /snot /rep; do \
		install -o $(MCUSER) -g $(MCGROUP) -m 0750 -d `./topdir`/queue$$i ;\
	done

	install -o $(ROOTUSER) -g $(QGROUP) -m 0440 McFeely.pm `cat PERLDIR`
	install -o $(ROOTUSER) -g $(QGROUP) -m 0750 -d `cat PERLDIR`/McFeely

	for i in Job.pm Task.pm Metatask.pm; do \
		install -o $(ROOTUSER) -g $(QGROUP) -m 0440 $$i `cat PERLDIR`/McFeely ;\
	done

rpminstall: all PERLDIR
	for i in '' /bin /comm /control; do \
		install -m 0755 -d $(ROOT)/`./topdir`$$i ;\
	done

	install -m 4510 mcfeely-queue $(ROOT)/`./topdir`/bin

	for i in mcfeely-manage mcfeely-spawn mcfeely-ttpc mcfeely-ttpd; do \
		install -m 0550 $$i $(ROOT)/`./topdir`/bin ;\
	done

	for i in '' /pid /task /info /desc /newj /job /fnot /snot /rep; do \
		install -m 0750 -d $(ROOT)/`./topdir`/queue$$i ;\
	done

	# this line because the perl dir won't be there during rpm install
	install -d $(ROOT)/`cat PERLDIR`

	install -m 0440 McFeely.pm $(ROOT)/`cat PERLDIR`
	install -m 0750 -d $(ROOT)/`cat PERLDIR`/McFeely

	for i in Job.pm Task.pm Metatask.pm; do \
		install -m 0440 $$i $(ROOT)/`cat PERLDIR`/McFeely ;\
	done

dist: $(TARFILE)

$(TARFILE): $(EVERYTHING)
	rm -fr $(DIST)
	rm -f $(TARFILE)
	mkdir $(DIST)
	perl -ne 'chomp; symlink "../$$_", "$(DIST)/$$_" or die $$!' MANIFEST
	tar cfhz $(TARFILE) $(DIST)
	rm -r $(DIST)

rpm: $(RPMFILE) $(SRPMFILE)

$(RPMFILE): do-rpm

$(SRPMFILE): do-rpm

do-rpm: $(TARFILE) $(SPECFILE)
	cp $(SPECFILE) $(RPMDIR)/SPECS/
	cp $(TARFILE) $(RPMDIR)/SOURCES/
	rpm -ba $(RPMDIR)/SPECS/$(SPECFILE)

ftp: $(RPMFILE)
	scp $(RPMFILE) $(FTPLOC)

$(SPECFILE): $(SPECFILE).in version BLURB TOPDIR ROOTUSER MCUSER MCGROUP \
	QGROUP PERLDIR

	perl -pe 's[\@(\S+)\@] \
	           [open F, $$1 or die; $$x = join "", <F>; chomp $$x; $$x]ge' \
	    < $< > $@

test:
	perl -cw mcfeely-manage

mcfeely-queue: mcfeely-queue.o trigger.o fn.o pid.o copy_to_null.o \
	copy_bytes.o safe_read.o safe_write.o

mcfeely-queue.o: trigger.h fn.h copy_to_null.h mcfeely-queue.h \
	copy_bytes.h safe_read.h safe_write.h mcfeely.h

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

make-chdir-pl.o: mcfeely.h

chdir.pl: make-chdir-pl
	./make-chdir-pl > chdir.pl

topdir.o: mcfeely.h

mcfeely.h: mcfeely.h.in TOPDIR
	perl -pe 's[\@(\S+)\@] \
	           [open F, $$1 or die; $$x = join "", <F>; chomp $$x; $$x]ge' \
	    < $< > $@

PERLDIR:
	perl -MConfig -e 'print $$Config{sitelib}, "\n"' > $@


tags: *.c *.h
	ctags *.c *.h

clean:
	rm -f $(TARGETS) $(OBJECTS) tags

print:
	nenscript -1R $(SOURCES)
