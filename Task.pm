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

=head1 NAME

McFeely::Task - Perl class that represents McFeely tasks.

=head1 SYNOPSIS

  use McFeely::Job;
  use McFeely::Task;
  $task1 = McFeely::Task->new($host1, $command1, @args1);
  $task2 = McFeely::Task->new($host2, $command2, @args2);
  $job = McFeely::Job->new($task1, $task2);
  $job->add_dependencies($task2->requires($task1));
  $job->enqueue or die $job->errstr, "\n";

  use McFeely::Task ':all';
  ...
  ok 'Task complete, exiting.';
  hard 'Task failed, don't try again.';
  soft 'Temporary failure, defer execution til later.';

=head1 DESCRIPTION

McFeely tasks.

=head1 METHODS

=over 4

=item new( HOST, COMMAND, ARGS )

Creates a C<McFeely::Task>.

New validates the HOST and COMMAND. The host is checked to see
that the string is there and if it is drives it back to a fully
qualified domain name. COMMAND is checked to be sure that the
string exists and has content. If either HOST or COMMAND are not
proper then new() will die. If you call new in an eval you can
trap the dies and process $@. $@ will begin with 'hostname:' if
the hostname is no good; 'comm:' if the COMMAND is no good.

=item comm

Return the name of the comm for this task. This does not assert
anything about the existence of or appropriateness of the comm itself,
just gives what is stored in this task.

=item requires( TASK, [TASK, ...] )

Returns a REQUIREMENT.  This requirement can then be fed to the
C<McFeely::Job> C<add_dependencies> method to add this requirement to
a given job.

=item hard ( [MESSAGE] )

Logs MESSAGE, if provided, then returns with the EXIT_HARD code,
meaning the task has suffered a permanent failure.

=item soft ( [MESSAGE] )

Logs MESSAGE, if provided, then returns with the EXIT_SOFT code,
meaning the task encountered a temporary problem and execution should
be retried later.

=item ok ( [MESSAGE] )

Logs MESSAGE, if provided, then returns with the EXIT_OK code.

=back

=head1 SEE ALSO

L<McFeely::Job>,
L<McFeely::Metatask>

=head1 AUTHORS

Matt Liggett E<lt>mml@pobox.comE<gt>, Adrian Hosey
E<lt>ahosey@systhug.comE<gt>, Chris Dent E<lt>cdent@kiva.netE<gt>

=cut

use lib '/home/cdent/src/mcfeely.hostcheck';
package McFeely::Task;
use McFeely;
use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

use constant HOST => 0;
use constant COMM => 1;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw ( EXIT_HARD EXIT_SOFT EXIT_OK hard soft ok plog );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

# comm exit codes used with hard(), soft(), and ok()
sub EXIT_HARD() { 100 }
sub EXIT_SOFT() {  99 }
sub EXIT_OK()   {   0 }

# create the object and return a reference to the
# the list that makes up the task
sub new {
    my $class = shift;
    my $self  = [ @_ ] ;
    bless $self, $class;

    # validate the input
    $self->_process_host();
    $self->_process_comm();

    return $self;

}

# _process_comm
# private method to make sure that a comm has been provided
# mostly a stub at this point
# <cdent@kiva.net>
sub _process_comm {
    my $self = shift;

    # make sure the comm is provided
    if ($self->[COMM] !~ /\w+/ || !defined($self->[COMM])) {
        die "comm: no comm provided\n";
    }
}


# _process_host
# private method to take the provide hostname and turn it
# into a fully qualified hostname. so hostnames are driven
# back to FQDN
# <cdent@kiva.net>
sub _process_host {
    my $self = shift;
    my $hostname;

    # make sure the hostname is provided
    if ($self->[HOST] !~ /\w+/ || !defined($self->[HOST])) {
        die "hostname: no hostname provided\n";
    }

    # make sure the hostname can resolve
    unless ( $hostname = (gethostbyname($self->[HOST]))[0] ) {
        die "hostname: unable to resolve hostname $self->[HOST]\n";
    }
    $self->[HOST] = $hostname;
}





# Return the name of the comm in this task.
sub comm { return @{$_}[1] }

# returns ref to list: (SELF, REQUIRED_TASK_1, REQUIRED_TASK_2, ...)
sub requires { [@_] }

# Send a message to STDOUT where it will (usually) be captured for logging.
sub plog(@) { print STDOUT @_, "\n" }

# Log a message if provided, then exit with the OK code.
sub ok(@) {
    &plog(@_) if @_;
    exit EXIT_OK;
}

# Log a message if provided, then exit with the HARD code.
sub hard(@) {
    &plog(@_) if @_;
    exit EXIT_HARD;
}

# Log a message if provided, then exit with the SOFT code.
sub soft(@) {
    &plog(@_) if @_;
    exit EXIT_SOFT;
}

1;
