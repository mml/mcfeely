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

# scan a task directory (either newt or task) for tasks
sub scan_task($$) {
    my $dir = shift;
    my $log_new = shift;

    my $file;
    my $task;
    my $job;

    opendir TASKD, $dir or do {
        log "Could not open $dir: $!";
        return undef;
    };
    TASK: while (defined($file = files(TASKD))) {
        open INFO, "info/$file" or do {
            log "Could not open info/$file: $!\n";
            next TASK;
        };
        $task = McFeely::Task->new $TASK_INO => $file, $TASK_NEXT_TRY => time;
        read(INFO, $task->[$TASK_NDEPS], 1) or do {
            log "Could not read from info/$file: $!\n";
            next TASK;
        };
        read(INFO, $job, 4) == 4 or do {
            log "Could not read from info/$file: $!\n";
            next TASK;
        };
        task_insert $task;
        task_enqueue $task;
        $job = unpack 'L', $job;
        log "new task $file" if $log_new;
        log "info task $file job $job";
        close INFO;
    }
    return 1;
}
