sub job_read_task(*\$) {
    my $fileref = shift;
    my $numref = shift;

    if ((read $$fileref, $$numref, 4) != 4) { return 0 }
    $$numref = unpack('L', $$numref);
    return 1;
}

sub job_new_job(@) {
    my $key; 
    my $val;
    my $job = [];

    while (@_) {
        $key = shift;
        $val = shift;
        $job->[$key] = $val;
    }

    return $job;
}

# scan a job directory (either job or newj) for jobs
sub scan_job($$) {
    my $dir = shift;
    my $log_new = shift;

    my $file;
    my $job;

    opendir JOBD, $dir or do {
        plog "Could not open $dir: $!";
        return undef;
    };
    JOB: while (defined($file = files(JOBD))) {
        plog "new job $file" if $log_new;
        open DESC, "desc/$file" or do {
            plog "Could not open desc/$file: $!";
            next JOB;
        };
        plog "info job $file: ", <DESC>;
        close DESC;
        $job = job_new_job $JOB_INO => $file;
        open JOB, "$dir/$file" or do {
            plog "Could not open $dir/$file: $!\n";
            next JOB;
        };
        seek JOB, 1, 1; #XXX: does this belong abstracted?
        while (job_read_task(JOB, $tasknum)) {
            $task = task_new_task_from_file $tasknum;
            $task->[$TASK_JOB] = $job;
            if ($task->[$TASK_NEEDS_DONE]) {
                task_enqueue $task;
                $job->[$JOB_NTASKS]++;
            }
            $task{$tasknum} = $task;
        }
        close JOB;
        foreach $task (keys %task) {
            for ($i = 0; $i <= $#{$task->[$TASK_WAITERS]}; ++$i) {
                splice @{$task->[$TASK_WAITERS]}, $i, 1,
                       $task{$task->[$TASK_WAITERS]->[$i]};
            }
        }
    }
    return 1;
}

1;
