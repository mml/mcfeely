# vi:sw=4:ts=4:wm=0:ai:sm:et
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

# wait on the trigger and other filehandles
sub do_select() {
    # $select is global in mcfeely-manage's name space

    my $trigger = new IO::File;
    my @hits;
    my $buf;

    # open the trigger without blocking
    $trigger->open('trigger', O_RDONLY|O_NONBLOCK)
        or plog "Cannot open trigger: $!";

    # once it is open, make it block
    # or maybe not
    # $trigger->blocking(1);

    # wait for activity
    $select->add($trigger);
    @hits = $select->can_read(SLEEPYTIME()) ;

    # read from the trigger so that the select knows we are 
    # paying attention
    foreach (@hits) {
        if ($_ == $trigger) {
            $trigger->read($buf, 1);
        }
    }

    $select->remove($trigger);
    close($trigger);
}

1;
