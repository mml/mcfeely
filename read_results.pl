# mcfeely        Asynchronous remote task execution.
# Copyright (C) 1999 Kiva Networking
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# You may contact the maintainer at <mcfeely-maintainer@systhug.com>.

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
    }
    close JOB;
    foreach (qw(fnot snot rep desc job)) {
        unlink "$_/$job->[$JOB_INO]" or plog "Could not unlink $_/$job->[$JOB_INO]: $!";
    }

    plog "$job->[$JOB_INO] end job";

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
    sysseek($info, 2, 0) or do {
        plog "Cannot seek info/$ino: $!";
        return undef;
    };

    while ($info->sysread($waitino, 4) == 4) {
        $waitino = unpack 'L', $waitino;
        $waiter = task_lookup $waitino;
        walk_waiters($thunk, $waiter, $depth);
    }
    $info->close;
}

# Harmless side effect: completed tasks have NDEPS set to -1.
# see walk_waiters for more details
sub decrement_waiters($) { walk_waiters { shift->[$TASK_NDEPS]-- } $_[0], 1 }

# Harmless side effect: failed tasks are marked DEFUNCT.
# see walk_waiters for more details
sub defunct_waiters($) {
    my $job = $_[0]->[$TASK_JOB];

    walk_waiters {
        my $task = shift;
        my $job = $task->[$TASK_JOB];
        unless ($task->[$TASK_DEFUNCT]) {
            $task->[$TASK_DEFUNCT] = 1;
            --$job->[$JOB_NTASKS];
            report $job->[$JOB_INO],
                "task $task->[$TASK_INO]: defuncted due to failure of dependent task";
        }
    } $_[0], -1;
}

sub task_flag_done($) {
    my $ino = shift;

    open INFO, "+< info/$ino" or do {
        plog "trouble: could not open info/$ino: $!";
        return;
    };
    print INFO pack('c', 1);
    close INFO;
}

# read the results from the spawner
sub read_results() {
    my $line;

    chomp($line = <SRR>);
    ($num, $code, $msg) = unpack 'LcA*', $line;
    $task = task_lookup $num;
    --$Tasks_in_progress;

    return unless defined $code;

    if ($code == $TASK_SUCCESS_CODE) {
        my $job = $task->[$TASK_JOB];

        plog "$job->[$JOB_INO]:$num success: $msg";
        task_flag_done $num;
        $task->[$TASK_NEEDS_DONE] = 0; # XXX: this is redundant, isn't it?
        report $job->[$JOB_INO], "task $num: success: $msg";
        decrement_waiters $task;
        $job->[$JOB_NTASKS]--;
        finish_job $job if ($job->[$JOB_NTASKS] == 0);
    } elsif ($code == $TASK_DEFERRAL_CODE) {
        my $job = $task->[$TASK_JOB];

        plog "$job->[$JOB_INO]:$num deferral: $msg";
        # exponential backoff stolen from djb
        $task->[$TASK_NEXT_TRY] =
            $task->[$TASK_BIRTH] +
              ((($task->[$TASK_NEXT_TRY] - $task->[$TASK_BIRTH]) ** 0.5)
               + 5) ** 2;
        task_enqueue $task;
    } elsif ($code == $TASK_FAILURE_CODE) {
        my $job = $task->[$TASK_JOB];

        plog "$job->[$JOB_INO]:$num failure: $msg";
        report $job->[$JOB_INO], "task $num: failure: $msg";
        defunct_waiters $task;
        $job->[$JOB_FAILED] = 1;
        finish_job $job if ($job->[$JOB_NTASKS] == 0);
    }
}

1;
