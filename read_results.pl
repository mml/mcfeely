sub report($@) {
    my $job = shift;

    open REP, ">> rep/$job" or do {
        plog "could not open rep/$job: $!";
        return;
    };
    print REP @_, "\n";
    close REP;
}

sub mail_report($$) {
    my $job = shift;
    my $success = shift;
    my $whom;

    open SNOT, "snot/$job" or do {
        plog "Could not open snot/$job: $!";
        return;
    };
    $whom = <SNOT>;
    close SNOT;

    if (! $success) {
        open FNOT, "fnot/$job" or do {
            plog "Could not open fnot/$job: $!";
            return;
        };
        $whom .= ' '.<FNOT>;
        close FNOT;
    }

    open MAIL, "| mail -s 'job $job' $whom";
    open REP, "rep/$job" or do {
        plog "Could not open rep/$job: $!";
        return;
    };
    print MAIL <REP>;
    close REP;
    close MAIL;
}

# mail reports, log completion, delete the job files and the task files and
# remove all data structures
sub finish_job($) {
    my $job = shift;
    my $tasknum;

    mail_report $job->[$JOB_INO], $job->[$JOB_FAILED];

    open JOB, "job/$job->[$JOB_INO]" or plog "Could not open job/$job: $!";
    seek JOB, 1, 1;
    while (job_read_task(JOB, $tasknum)) {
        foreach (qw(task info)) {
            unlink "$_/$tasknum" or plog "Could not unlink $_/$tasknum: $!";
        }
        foreach (qw(fnot snot rep desc job)) {
            unlink "$_/$job" or plog "Could not unlink $_/$job: $!";
        }
    }
    close JOB;

    plog "end job $job->[$JOB_INO]";

}

# walk the tree of tasks waiting on this task and do something (contained
# within $thunk) to each task
sub walk_waiters(&$$) {
    my $thunk = shift;
    my $task = shift;
    my $depth = shift;

    my $ino = $task->[$TASK_INO];
    my $info = IO::File->new;

    &$thunk($task);

    return if $depth == 0;

    --$depth;

    $info->open("info/$ino") or do {
        plog "Cannot open info/$ino: $!";
        return undef;
    };
    $info->seek(5, 0) or do {
        plog "Cannot seek info/$ino: $!";
        return undef;
    };

    while ($info->read($waitino, 4) == 4) {
        $waitino = unpack 'L', $waitino;
        $waiter = task_lookup $waitino;
        walk_waiters($thunk, $waiter, $depth);
    }
    $info->close;
}

# Harmless side effect: completed tasks have NDEPS set to -1.
# see walk_waiters for more details
sub decrement_waiters($) { walk_waiters { $task->[$TASK_NDEPS]-- } $_[0], 1 }

# Harmless side effect: failed tasks are marked DEFUNCT.
# see walk_waiters for more details
sub defunct_waiters($) {
    my $job = $_[0]->[$TASK_JOB];

    walk_waiters {
        $task->[$TASK_DEFUNCT] = 1;
        --$job->[$JOB_NDEPS];
    } $_[0], -1;
}

# read the results from the spawner
sub read_results() {
    my $line;

    chomp($line = <SRR>);
    ($num, $code, $msg) = unpack 'LcA*', $line;
    $task = task_lookup $num;
    --$Tasks_in_progress;

    if ($code eq $TASK_SUCCESS_CODE) {
        my $job = $task->[$TASK_JOB];

        plog "task $num: success: $msg";
        report $job->[$JOB_INO], "task $num: success: $msg";
        decrement_waiters $task;
        $job->[$JOB_NTASKS]--;
        finish_job $job if ($job->[$JOB_NTASKS] == 0);
    } elsif ($code eq $TASK_DEFERRAL_CODE) {
        plog "task $num: deferral: $msg";
        # exponential backoff stolen from djb
        $task->[$TASK_NEXT_TRY] =
            ( $task->[$TASK_BIRTH] +
              (($task->[$TASK_NEXT_TRY] - $task->[$TASK_BIRTH]) ** 0.5)
               + 20) ** 2;
        task_enqueue $task;
    } elsif ($code eq $TASK_FAILURE_CODE) {
        my $job = $task->[$TASK_JOB];

        plog "task $num: failure: $msg";
        report $job->[$JOB_INO], "task $num: failure: $msg";
        defunct_waiters $task;
        $job->[$JOB_FAILED] = 1;
        $job->[$JOB_NTASKS]--;
        finish_job $job if ($job->[$JOB_NTASKS] == 0);
    }
}

1;
