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

Matt Liggett, mml@pobox.com

=cut

1;
