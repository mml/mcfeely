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

=back

=head1 SEE ALSO

L<McFeely::Job>,
L<McFeely::Metatask>

=head1 AUTHOR

Matt Liggett, mml@pobox.com

=cut

package McFeely::Task;
use McFeely;
use strict;

sub new {
    my $class = shift;

    return(bless [@_], $class);
}

# returns ref to list: (SELF, REQUIRED_TASK_1, REQUIRED_TASK_2, ...)
sub requires { [@_] }

1;
