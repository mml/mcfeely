# wait on the trigger and other filehandles
sub do_select() {
    sysopen(TRIGGER, 'trigger', O_RDONLY|O_NONBLOCK)
        or plog "Cannot open trigger: $!";
    fcntl(TRIGGER, F_SETFL, fcntl(TRIGGER, F_GETFL, 0) & O_NONBLOCK)
        or plog "Cannot fcntl trigger: $!";
    select($rout=$rin, undef, undef, SLEEPYTIME);
    close(TRIGGER);
}

1;
