# insert a job into a hash table
sub job_insert($) {
    my $job = shift;

    $Job{$job->[$JOB_INO]} = $job;
}

# scan a job directory (either job or newj) for jobs
sub scan_job($$) {
    my $dir = shift;
    my $log_new = shift;

    my $file;
    my $job;

    opendir JOBD, $dir or do {
        log "Could not open $dir: $!";
        return undef;
    };
    JOB: while (defined($file = files(JOBD))) {
        open JOB, "$dir/$file" or do {
            log "Could not open $dir/$file: $!\n";
            next JOB;
        };
        $job = McFeely::Job->new $JOB_INO => $file;
        read(JOB, $job->[$JOB_NTASKS], 1) or do {
            log "Could not read from job/$file: $!\n";
            next JOB;
        };
        job_insert $job;
        log "new job $file" if $log_new;
        log "info job $file: ", <JOB>;
        close JOB;
    }
    return 1;
}
