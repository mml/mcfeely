#!/usr/bin/perl

# checking to see if isa() checking in Job::add_tasks will work.
# cdent

use lib '/home/cdent/src/mcfeely.isa';
use strict;
use McFeely;

my $job = McFeely::Job->new();
$job->desc('testing bad task add');
my $task1 = 'foobar';
#my $task1 = McFeely::Task->new('www.kiva.net', 'test_comm', 'arg1');
my $task2 = McFeely::Task->new('www.kiva.net', 'test_comm', 'arg2');
my $task3 = McFeely::Metatask->new($task1, $task2);
my $task4 = McFeely::Task->new('www.kiva.net', 'test_comm', 'arg4');

my @taskrefs;
push(@taskrefs, $task1, $task4);

eval {
    $job->add_tasks(@taskrefs);
} or do {
    die "$@";
};
