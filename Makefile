# vi:ts=4:sw=4:noet:wm=0

# mcfeely        Asynchronous remote task execution.
# Copyright (C) 1999 Kiva Networking
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# You may contact the maintainer at <mcfeely-maintainer@systhug.com>.

PROJECT	= mcfeely

SOURCES	= attempt_tasks.pl do_select.pl files.pl jobs.pl log.pl \
	mcfeely-manage mcfeely-queue.c mcfeely.h \
	read_results.pl safe_to_exit.pl tasks.pl hostport.c hostport.h \
	mcfeely-ttpc.c exit-codes.h make-mcfeely-pm.c make-chdir-pl.c \
	make-internal-pm.c snooze.c secretmaker.c

OBJECTS = mcfeely-queue.o trigger.o fn.o pid.o copy_to_null.o \
	copy_bytes.o safe_read.o safe_write.o mcfeely-ttpc.o hostport.o \
	make-mcfeely-pm.o mcfeely-ttpd.o make-chdir-pl.o make-internal-pm.o \
	topdir.o

TARGETS	= mcfeely-queue test-queue mcfeely-ttpc mcfeely-ttpd make-mcfeely-pm \
	McFeely.pm topdir mcfeely.h chdir.pl Internal.pm snooze \
	secretmaker 

HTML	 	= Metatask.html Job.html Task.html	
HOWTO		= HOWTO TODO

ROOTUSER 	= $(shell cat ROOTUSER)
MCUSER   	= $(shell cat MCUSER)
MCGROUP  	= $(shell cat MCGROUP)
QGROUP   	= $(shell cat QGROUP)

CC			= gcc

# use these for building fast production binaries
#CFLAGS  	= -Wall -O6
#LDFLAGS 	= -s

# use this for building debuggable binaries
CFLAGS   	= -g -Wall

RPMDIR		= $(shell rpm --showrc |\
			    perl -n -e \
			    '/topdir(?:\s+|\s+:\s+)(\/.*$)/ && \
				print "$$1\n";')

VERSION		= $(shell cat version)
EVERYTHING	= $(shell cat MANIFEST)
DIST		= $(PROJECT)-$(VERSION)
TARFILE		= $(DIST).tar.gz
SPECFILE	= $(PROJECT).spec
RPMFILE		= $(RPMDIR)/RPMS/i386/$(PROJECT)-common-$(VERSION)-1.i386.rpm \
			  $(RPMDIR)/RPMS/i386/$(PROJECT)-client-$(VERSION)-1.i386.rpm \
			  $(RPMDIR)/RPMS/i386/$(PROJECT)-server-$(VERSION)-1.i386.rpm
SRPMFILE	= $(RPMDIR)/SRPMS/$(DIST)-1.src.rpm
FTPLOC		= sysftp.kiva.net:~ftp/pub/kiva
WWWLOC		= www.systhug.com:~systhug/www/mcfeely

.PHONY: all install rpminstall dist rpm ftp clean
.INTERMEDIATE: $(SPECFILE) PERLDIR make-internal-pm make-chdir-pl
.SUFFIXES: .pm .html

all: $(TARGETS) 

install: all PERLDIR
	for i in '' /bin /comm /control /lib /lib/perl; do \
		install -o $(ROOTUSER) -g $(MCGROUP) -m 0755 -d `./topdir`$$i ; \
	done

	install -o $(MCUSER) -g $(MCGROUP) -m 0700 -d `./topdir`/control/secrets
	install -o $(MCUSER) -g $(QGROUP) -m 4510 mcfeely-queue `./topdir`/bin

	for i in mcfeely-start mcfeely-qread mcfeely-manage mcfeely-spawn \
		mcfeely-ttpc mcfeely-ttpd snooze secretmaker; do \
		install -o $(ROOTUSER) -g $(MCGROUP) -m 0550 $$i `./topdir`/bin ; \
	done

	install -o $(ROOTUSER) -g $(MCGROUP) -m 0550 test_comm `./topdir`/comm

	cd $(ROOT)/`./topdir`/bin ;ln -sf mcfeely-qread mcfeely-qwatch

	for i in '' /pid /task /info /desc /newj /job /fnot /snot /rep; do \
		install -o $(MCUSER) -g $(MCGROUP) -m 0750 -d `./topdir`/queue$$i ; \
	done
	mkfifo `./topdir`/queue/trigger

	install -o $(ROOTUSER) -g $(QGROUP) -m 0444 McFeely.pm `cat PERLDIR`
	install -o $(ROOTUSER) -g $(QGROUP) -m 0755 -d `cat PERLDIR`/McFeely

	for i in Job.pm Task.pm Metatask.pm Internal.pm; do \
		install -o $(ROOTUSER) -g $(QGROUP) -m 0444 $$i \
			`cat PERLDIR`/McFeely ;\
	done

	for i in attempt_tasks.pl const.pl files.pl log.pl safe_to_exit.pl \
		chdir.pl do_select.pl jobs.pl read_results.pl tasks.pl; do \
		install -o $(ROOTUSER) -g $(MCGROUP) -m 0644 $$i \
			`./topdir`/lib/perl; \
	done

rpminstall: all PERLDIR
	for i in '' /bin /comm /control /lib /lib/perl; do \
		install -m 0755 -d $(ROOT)/`./topdir`$$i ;\
	done

	install -m 0700 -d $(ROOT)/`./topdir`/control/secrets

	install -m 4510 mcfeely-queue $(ROOT)/`./topdir`/bin

	for i in mcfeely-start mcfeely-qread mcfeely-manage mcfeely-spawn \
	  mcfeely-ttpc mcfeely-ttpd snooze secretmaker hostcheck.pl \
	  serverslam.pl; do \
		install -m 0550 $$i $(ROOT)/`./topdir`/bin ;\
	done

	install -m 0550 test_comm $(ROOT)`./topdir`/comm

	cd $(ROOT)/`./topdir`/bin ;ln -sf mcfeely-qread mcfeely-qwatch

	for i in '' /pid /task /info /desc /newj /job /fnot /snot /rep; do \
		install -m 0750 -d $(ROOT)/`./topdir`/queue$$i ;\
	done
	mkfifo $(ROOT)/`./topdir`/queue/trigger

	# this line because the perl dir won't be there during rpm install
	install -d $(ROOT)/`cat PERLDIR`

	install -m 0444 McFeely.pm $(ROOT)/`cat PERLDIR`
	install -m 0755 -d $(ROOT)/`cat PERLDIR`/McFeely

	for i in Job.pm Task.pm Metatask.pm Internal.pm; do \
		install -m 0444 $$i $(ROOT)/`cat PERLDIR`/McFeely ;\
	done

	for i in attempt_tasks.pl const.pl files.pl log.pl safe_to_exit.pl \
		chdir.pl do_select.pl jobs.pl read_results.pl tasks.pl; do \
		install -m 0644 $$i $(ROOT)/`./topdir`/lib/perl; \
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

ftp: $(RPMFILE) $(SRPMFILE)
	chmod 644 $(RPMFILE) $(SRPMFILE) $(TARFILE)
	scp $(RPMFILE) $(FTPLOC)/RPMS/i386
	scp $(SRPMFILE) $(FTPLOC)/SRPMS

www: $(RPMFILE) $(TARFILE) $(SRPMFILE) $(HTML) $(HOWTO)
	chmod 644 $(RPMFILE) $(SRPMFILE) $(TARFILE) $(HTML) $(HOWTO)
	scp $(RPMFILE) $(WWWLOC)/dist
	scp $(SRPMFILE) $(WWWLOC)/dist
	scp $(TARFILE) $(WWWLOC)/dist
	scp $(HTML) $(WWWLOC)
	scp $(HOWTO) $(WWWLOC)

update: ftp www


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

make-internal-pm.o: mcfeely.h

Internal.pm: make-internal-pm
	./make-internal-pm > Internal.pm

topdir.o: mcfeely.h

mcfeely.h: mcfeely.h.in TOPDIR
	perl -pe 's[\@(\S+)\@] \
	           [open F, $$1 or die; $$x = join "", <F>; chomp $$x; $$x]ge' \
	    < $< > $@

PERLDIR:
	perl -MConfig -e 'print $$Config{sitelib}, "\n"' | \
		perl -p -e 's/\/[\d\.]+$$//' > $@

tags: *.c *.h
	ctags *.c *.h

clean:
	rm -f $(TARGETS) $(OBJECTS) tags

print:
	nenscript -1R $(SOURCES)

createtestdir: McFeely.pm Internal.pm chdir.pl
	-mkdir McFeely
	cd McFeely && ln -sf ../Job.pm && ln -sf ../Task.pm && \
		ln -sf ../Metatask.pm && ln -sf ../Internal.pm

.pm.html: Metatask.pm Job.pm Task.pm
	pod2html $< > $*.html
