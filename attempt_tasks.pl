# send instructions to the spawner
sub write_to_spawner($) {
    my $ino = shift;

    print SIW "$ino\n";
}

# attempt all tasks whose times have come
sub attempt_tasks() {
    my $i;
    my $task;
    my $now = time;
    my @ntasks;

    TASK: for ($i = 0; $i <= $#Tasks; ++$i) {
        $task = $Tasks[$i];

        # Since the tasks are sorted by NEXT_TRY time, if this one is in the
        # future, so are all the rest, so let's just cut to the chase.  In the
        # process, we recreate @Tasks, but don't include any of the tasks we've
        # just attempted.  When the results come back from the spawner, they'll
        # either be removed from the action or reinserted into the queue.
        if ($task->[$TASK_NEXT_TRY] > $now) {
            push @ntasks, @Tasks[$i..$#Tasks];
            last TASK;
        }

        if ($task->[$TASK_NDEPS] > 0) {
            push @ntasks, $task;
        } else {
            plog "starting transfer task $task->[$TASK_INO]: job $task->[$TASK_JOB]->[$JOB_INO] on $task->[$TASK_HOST]";
            write_to_spawner $task->[$TASK_INO];
            $task->[$TASK_NEXT_TRY] = $now;
            ++$Tasks_in_progress;
        }
    }

    @Tasks = @ntasks;
}

1;
