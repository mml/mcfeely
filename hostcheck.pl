#!/usr/bin/perl
# vi:sw=4:ts=4:wm=0:ai:sm:et

# $Id: hostcheck.pl,v 1.4 2000/07/06 00:16:28 cdent Exp $

# mcfeely-task-test
# inject a single task
# demo code

# adjust to locacation of McFeely.pm
#use lib '/home/cdent/src/mcfeely.spawner';

use McFeely;
use strict;

# initialize some variables we'll use later
my $host = $ARGV[0];
my $comm = $ARGV[1];
my @args = $ARGV[2];


# fill those variables
$host   = get_hostname(\$host);
$comm   = get_comm(\$comm);
@args   = get_comm_args(\@args);

my $job = new McFeely::Job;

# set the desc, snot and fnot for the job
$job->desc('single task inject');
$job->snot(scalar getpwuid($<));
$job->fnot(scalar getpwuid($<));

# make a task, testing the inputs and trying again until we get
# right
my $task;
make_task(\$task, \$host, \$comm, \@args);

# add the task to the job
eval { $job->add_tasks($task);
} || do {
    die "$@";
};

# enqueue the job
$job->enqueue() ||
    die "unable to enqueue job: ", $job->errstr, "\n";

exit;

sub get_hostname {
    my $hostref = shift;
    my $response;

    print "Hostname? [$$hostref] ";
    $response = <STDIN>;
    chomp $response;

    if ($response eq '') {
        return $$hostref;
    } else {
        return $response;
    }
}

sub get_comm {
    my $commref = shift;
    my $response;

    print "Comm? [$$commref] ";
    $response = <STDIN>;
    chomp $response;

    if ($response eq '') {
        return $$commref;
    } else {
        return $response;
    }
}

sub get_comm_args {
    my $argref = shift;
    my $response;

    print "Args? [@$argref] ";
    $response = <STDIN>;
    chomp $response;

    if ($response eq '') {
        return (@$argref);
    } else {
        return (split(' ', $response));
    }

}


sub make_task {
    my $taskref = shift;
    my $hostref = shift;
    my $commref = shift;
    my $argref  = shift;

    # try
    eval { $$taskref   = McFeely::Task->new($$hostref,
                                           $$commref,
                                           @$argref,
                                   );
    } || do {
    # catch
        if ($@ =~ /^hostname:/) {
            print "$@\n";
            $$hostref = get_hostname($hostref);
            $$commref = get_comm($commref);
            @$argref  = get_comm_args($argref);
            make_task($taskref, $hostref, $commref, $argref);
        } elsif ($@ =~ /^comm:/) {
            print "$@\n";
            $$hostref = get_hostname($hostref);
            $$commref = get_comm($commref);
            @$argref  = get_comm_args($argref);
            make_task($taskref, $hostref, $commref, $argref);
        } else {
            die "error: $@\n";
        }
    };

}
