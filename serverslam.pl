#!/usr/bin/perl
# vi:sw=4:ts=4:wm=0:ai:sm:et

# $Id: serverslam.pl,v 1.1.2.1 2000/06/21 22:21:22 cdent Exp $

# A tool for beating the piss out of a mcfeely-server client combo
# initially just does one one server and one client
# with one type of comm.
#
# could be exanded to include null tasks, no args, all kinds of stuff 
# like that.
# 
# we'll do that later


use McFeely;
use strict;

# initialize some variables we'll use later
my $host            = $ARGV[0];
my $comm            = $ARGV[1];
my $job_iterations  = $ARGV[2];
my $task_iterations = $ARGV[3];
my $mail            = $ARGV[4];

defined($job_iterations) or
    die "three args required: host, comm, job_iterations\n";

$task_iterations ||= 1;

my $count;
my %job;
foreach $count (1 .. $job_iterations) {
    $job{$count} = new McFeely::Job;

    $job{$count}->desc("slamserver job $count");
    $job{$count}->snot($mail);
    $job{$count}->fnot($mail);

    my $taskcount;
    my %task;
    foreach $taskcount (1 .. (int(rand($task_iterations)) + 1)) {
        $task{$taskcount} = new McFeely::Task($host, $comm, $taskcount);
        $job{$count}->add_tasks($task{$taskcount});
    }
}

foreach $count (1 .. $job_iterations) {
    $job{$count}->enqueue() || die "unable to enqueue job:",
        $job{$count}->errstr, "\n";
}

