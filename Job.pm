=head1 NAME

McFeely::Job - Perl extension to ease McFeely job queueing.

=head1 SYNOPSIS

  use McFeely::Job;
  $job = McFeely::Job->new;
  $job->add_tasks($task1, $task2, $task3, $task4);
  $job->add_dependencies(
        $task2->requires($task1);
        $task4->requires($task2);
  );
  $job->enqueue or die $job->errstr, "\n";

=head1 DESCRIPTION

The Perl extension encapsulates a McFeely job to make queueing easy.

=head1 METHODS

=over 4

=item new( [TASK, [TASK, ...]] )

Creates a C<McFeely::Job>.  Member tasks may be added now.  This is
equivalent to adding them with the separate add_tasks method.

=item fnot( ADDRESS )

Sets the failure notification address.

=item snot( ADDRESS )

Sets the success notification address.

=item desc( DESCRIPTION )

Sets the description.

=item add_tasks( TASK, [TASK, ...] )

Adds the listed C<McFeely::Task>s to the job.

=item list_tasks

Returns a list of all C<McFeely::Task>s contained in the job.

=item add_dependencies( REQUIREMENT, [REQUIREMENT, ...] )

A REQUIREMENT is produced by the requires method of a C<McFeely::Task>
or C<McFeely::Metatask>.  E.g.

  $job->add_dependencies($task1->requires($task2));

This tells McFeely that $task2 must be completed before $task1 may be
attempted.

=back

=head1 SEE ALSO

L<McFeely::Task>,
L<McFeely::Metatask>

=head1 AUTHOR

Matt Liggett, mml@pobox.com

=cut

package McFeely::Job;
use IO::Pipe;
use strict;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->add_tasks(@_);
    return $self;
}

sub fnot {
    my $self = shift;

    $self->{fnot} = shift;
}

sub snot {
    my $self = shift;

    $self->{snot} = shift;
}

sub desc {
    my $self = shift;

    $self->{desc} = shift;
}

sub add_tasks {
    my $self = shift;

    push @{$self->{tasks}}, @_;
}

sub list_tasks {
    my $self = shift;

    return @{$self->{tasks}};
}

sub add_dependencies {
    my $self = shift;

    push @{$self->{deps}}, @_;
}

sub _set_errstr {
    my $self = shift;

    $self->{errstr} = shift;
}

sub errstr {
    my $self = shift;

    $self->{errstr};
}

sub enqueue {
    my $self = shift;

    my $task;
    my $nbytes;
    my $pid;
    my $pipe0;
    my $pipe1;
    my $pipe2;
    my $code;

    # XXX: we probably shouldn't distort the object so much
    $self->_flatten;

    if (! $self->_is_completable) {
        $self->_set_errstr('dependency error');
        return undef;
    }
    $pipe0 = new IO::Pipe;
    $pipe1 = new IO::Pipe;
    $pipe2 = new IO::Pipe;
    if ($pid = fork) {
        # parent; just cascade through
        foreach ($pipe0, $pipe1, $pipe2) { $_->writer }
    } elsif ($pid == 0) {
        # child; fork and exec
        foreach ($pipe0, $pipe1, $pipe2) { $_->reader }
        open STDIN, "<&=" . $pipe0->fileno;
        open STDOUT, "<&=" . $pipe1->fileno;
        open STDERR, "<&=" . $pipe2->fileno;
        exec '/home/mliggett/mcfeely-test/bin/mcfeely-queue';
        die; # XXX: how to better report diagnostics here?
    } else {
        # error
        $self->_set_errstr("Couldn't fork: $!");
        return undef;
    }
    foreach $task ($self->list_tasks) {
        $nbytes = 0;
        foreach (@$task) { $nbytes += length($_) + 1 }
        $pipe0->print(pack 'L', $nbytes);
        foreach (@$task) { $pipe0->print($_, "\0") }
    }
    $pipe0->close;
    $self->_write_dependencies($pipe1);
    $pipe1->close;
    $pipe2->print($self->{'desc'}, "\0",
        $self->{'fnot'}, "\0", $self->{'snot'}, "\0");
    $pipe2->close;
    if (waitpid($pid, 0) == -1) {
        $self->_set_errstr('internal wait error');
        return undef;
    }
    $code = $? >> 8;
    if ($code != 0) {
        $self->_set_errstr("bad mcfeely-queue exit code: $code");
        return undef;
    }
    return 1;
}

sub _flatten {
    my $self = shift;
    my $dep;
    my $key;
    my @vals;
    my $val;
    my $task;
    my @tdeps;
    my @ndeps;
    my @nvals;
    my @ntasks;

    # 1. expand metatasks on the LHS of dependencies
    foreach $dep (@{$self->{deps}}) {
        ($key, @vals) = @$dep;
        if (ref($key) eq 'McFeely::Metatask') {
            foreach $task ($key->list_tasks) {
                push @tdeps, [$task, @vals];
            }
        } else {
            push @tdeps, $dep;
        }
    }

    # 2. expand metatasks on the RHS of dependencies
    foreach $dep (@tdeps) {
        ($key, @vals) = @$dep;
        @nvals = ();
        foreach $val (@vals) {
            if (ref($val) eq 'McFeely::Metatask') {
                push @nvals, $val->list_tasks;
            } else {
                push @nvals, $val;
            }
        }
        push @ndeps, [$key, @nvals];
    }

    $self->{deps} = [@ndeps];

    # 3. explode tasks from task list
    foreach $task ($self->list_tasks) {
        if (ref($task) eq 'McFeely::Metatask') {
            push @ntasks, $task->list_tasks;
        } else {
            push @ntasks, $task;
        }
    }

    # 4. incorporate deps from metatasks
    foreach $task ($self->list_tasks) {
        if (ref($task) eq 'McFeely::Metatask') {
            $self->add_dependencies(@{$task->{deps}});
        }
    }

    $self->{tasks} = [@ntasks];
}

sub _is_completable {
    my $self = shift;
    my %deps;
    my $dep;
    my $key;
    my @vals;
    my $did_some_work;
    my %new_deps;
    my $task;
    my %index;

    foreach $dep (@{$self->{deps}}) {
        ($key, @vals) = @$dep;
        push(@{$deps{$key}}, @vals);
    }

    do {
        $did_some_work = 0;
        foreach $task (keys %deps) {
            if (@{$deps{$task}} == 0) {
                delete $deps{$task};
                ++$did_some_work;
            }
        }

        %new_deps = ();

        foreach $task (keys %deps) {
            foreach $dep (@{$deps{$task}}) {
                if (exists $deps{$dep}) {
                    push(@{$new_deps{$task}}, $dep);
                } else {
                    ++$did_some_work; # the work is REMOVING this item
                }
            }
        }

        %deps = %new_deps;
    } while ($did_some_work);

    if ((keys %deps) == 0) {
        return 1;
    } else {
        return undef;
    }
}

sub _write_dependencies {
    my $self = shift;
    my $fh = shift;
    my %ndeps;
    my %waiters;
    my %index;
    my $dep;
    my $key;
    my @vals;
    my @tasks;
    my $task;
    my $waiter;
    my $i;

    foreach $dep (@{$self->{deps}}) {
        ($key, @vals) = @$dep;
        $ndeps{$key} += @vals;
        foreach $task (@vals) {
            push(@{$waiters{$task}}, $key);
        }
    }
    
    @tasks = $self->list_tasks;

    for ($i = 0; $i <= $#tasks; ++$i) { $index{$tasks[$i]} = $i }

    foreach $task (@tasks) {
        $fh->print(pack('CC', $ndeps{$task}, $#{$waiters{$task}}+1));
        foreach $waiter (@{$waiters{$task}}) {
            $fh->print(pack('C', $index{$waiter}));
        }
    }
}

1;
