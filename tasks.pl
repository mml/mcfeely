sub task_new_task(@) {
    my $key;
    my $val;
    my $task = [];

    while (@_) {
        $key = shift;
        $val = shift;
        $task->[$key] = $val;
    }

    return $task;
}

sub task_new_task_from_file($) {
    my $ino = shift;
    my $data;
    my $task = [];
    my $waiters = [];

    open INFO, "info/$ino" or do {
        plog "Cannot open info/$ino: $!";
        return undef;
    };

    read INFO, $task->[$TASK_NEEDS_DONE], 1;
    read INFO, $task->[$TASK_NDEPS], 1;
    while ((read INFO, $data, 4) == 4) {
        $data = unpack 'L', $data;
        push @$waiters, $data;
    }
    close INFO;
    $task->[$TASK_WAITERS] = $waiters;
    $task->[$TASK_BIRTH] = (stat INFO)[10];
    $task->[$TASK_INO] = $ino;

    return $task;
}

# insert a task into a hash table
sub task_insert($) {
    my $task = shift;

    $Task[$task->$TASK_INO] = $task;
}
    
# insert a task into a priority queue
sub task_enqueue($) {
    my $task = shift;

    for ($i = 0; $i <= $#Tasks; ++$i) {
        if ($task->[$TASK_NEXT_TRY] <= $Tasks[$i]->[$TASK_NEXT_TRY]) {
            splice @Tasks, $i, 0, $task;
            return;
        }
    }
    push @Tasks, $task;
}
