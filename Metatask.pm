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

McFeely::Metatask - Treat a group of McFeely::Task objects as a single task.

=head1 SYNOPSIS

  use McFeely::Job;
  use McFeely::Task;
  use McFeely::Metatask;

  $task1 = McFeely::Task->new($host1, $command1, @args1);
  $task2 = McFeely::Task->new($host2, $command2, @args2);
  $task3 = McFeely::Task->new($host3, $command3, @args3);
  $meta = McFeely::Metatask->new($task2, $task3);
  $job = McFeely::Job->new($task1, $meta);
  $job->add_dependencies(
      $meta->requires($task1);
  );
  $job->enqueue or die $job->errstr, "\n";

=head1 DESCRIPTION

See above.

=head1 METHODS

=over 4

=item new( TASK, [TASK, ...] )

Creates a C<McFeely::Metatask>.  This acts exactly like (and in fact
C<ISA>) a C<McFeely::Task> and supports all the rest of the latter's
methods.

=item add_tasks ( TASK, [TASK, ...] )

This acts exactly like the method of the same name in C<McFeely::Job>.
See the documentation in L<McFeely::Job> for more information.

=item add_dependencies( REQUIREMENT, [REQUIREMENT, ...] )

This acts exactly like the method of the same name in C<McFeely::Job>
and supports setting up intra-metatask dependencies.  See the
documentation in L<McFeely::Job> for more information.

=back

=head1 SEE ALSO

L<McFeely::Job>,
L<McFeely::Task>

=head1 AUTHOR

Matt Liggett, E<lt>mml@pobox.comE<gt>

=cut

package McFeely::Metatask;
use McFeely;

@ISA = qw( McFeely::Job McFeely::Task );

1;
