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

    TASK: for ($i = 0; $i <= $#Tasks; ++$i) {
        $task = $Tasks[$i];
        if ($task->[$TASK_NEXT_TRY] > $now) {
            @Tasks = @Tasks[$i..$#Tasks];
            last TASK;
        }
        next if $task->[$TASK_NDEPS] > 0;
        write_to_spawner $task->[$TASK_INO];
        $task->[$TASK_NEXT_TRY] = $now;
        ++$Tasks_in_progress;
    }
}
