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

Matt Liggett <mml@pobox.com>, Adrian Hosey <ahosey@systhug.com>

=cut

package McFeely::Task;
use McFeely;
use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw ( EXIT_HARD EXIT_SOFT EXIT_OK hard soft ok plog );
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub EXIT_HARD() { 100 }
sub EXIT_SOFT() {  99 }
sub EXIT_OK()   {   0 }

sub new {
    my $class = shift;

    return(bless [@_], $class);
}

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
