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
    sysopen(TRIGGER, 'trigger', O_RDONLY|O_NONBLOCK)
        or plog "Cannot open trigger: $!";
    fcntl(TRIGGER, F_SETFL, fcntl(TRIGGER, F_GETFL, 0) & O_NONBLOCK)
        or plog "Cannot fcntl trigger: $!";
    fd_set(TRIGGER, $rin);
    select($rout=$rin, undef, undef, SLEEPYTIME);
    close(TRIGGER);
}


1;
