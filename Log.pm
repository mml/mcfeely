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

package McFeely::Log;

use vars qw(@ISA @EXPORT);

require Exporter;
@ISA =    qw (Exporter);
@EXPORT = qw (plog bail);

# write log message to stdout
sub plog(@) { 
    print STDOUT @_;    
    print STDOUT "\n" unless (substr($_[-1], -1, 1) eq "\n");
}

sub bail(@) { plog @_; exit 0 }

1;
