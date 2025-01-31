# vi:sw=4:ts=4:wm=0:ai:sm:et
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

use McFeely::Log;
use McFeely::Const;

sub report($@) {
    my $job = shift;

    open REP, ">> rep/$job" or do {
        plog "could not open rep/$job: $!";
        return;
    };
    print REP @_;
    print REP "\n" unless (substr($_[-1], -1, 1) eq "\n");
    close REP;
}

sub mail_report($$) {
    my $job = shift;
    my $failed = shift;
    my $whom;
    my $subject;
    my $desc;

    # get the description for use in the message
    open DESC, "desc/$job" or do {
        plog "Could not open desc/$job: $!";
        return;
    };
    while (defined($_ = <DESC>)) {
        chomp;
        $desc .= "$_ ";
    }
    close DESC;

    # figure out if we are failing or succeeding and produce 
    if (! $failed) {
        # success
        open SNOT, "snot/$job" or do {
            plog "Could not open snot/$job: $!";
            return;
        };
        $whom = <SNOT>;
        close SNOT;
        $subject = "job $job success";
    } else {
        # failure
        open FNOT, "fnot/$job" or do {
            plog "Could not open fnot/$job: $!";
            return;
        };
        $whom = <FNOT>;
        $subject = "job $job failure";
        close FNOT;
    }

    # add the desc to the subject
    $subject .= ":  $desc";

    # okay, if we've got somebody to send some mail to
    # let's put it in a pipe
    if ($whom) {

        # get our mailer XXX
        # this should be abstracted out to a mail function so we
        # don't have to rely on /bin/mail
        open MAIL, "| mail -s '$subject' $whom";

        # get the report text
        open REP, "rep/$job" or do {
            plog "Could not open rep/$job: $!";
            return;
        };

        # print the message
        print MAIL "job $job report:\n";
        print MAIL <REP>;
        print MAIL "\nDescription:\n$desc";

        close REP;
        close MAIL;
    }
}

# mail reports, log completion, delete the job files and the task files and
# remove all data structures
sub finish_job($) {
    my $job = shift;
    my $tasknum;

    my $jobhandle = new IO::File;

    mail_report $job->[$JOB_INO], $job->[$JOB_FAILED];

    $jobhandle->open("job/$job->[$JOB_INO]") or
        plog "Could not open job/$job->[$JOB_INO]: $!";
    # XXX: wait, if we fail here on this open we don't want to then
    #      seek, something else needs to happen. what? cjd 2000.0621
    seek $jobhandle, 1, 1;
    while (job_read_task($jobhandle, \$tasknum)) {
        foreach (qw(task info)) {
            unlink "$_/$tasknum" or plog "Could not unlink $_/$tasknum: $!";
        }
    }
    close $jobhandle;
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

    my ($waitino, $waiter);
    while ($info->sysread($waitino, 4) == 4) {
        $waitino = unpack 'L', $waitino;
        $waiter = task_lookup $waitino;
        walk_waiters($thunk, $waiter, $depth);
    }
    $info->close();
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
	        "task $task->[$TASK_INO] ($task->[$TASK_COMM]) ",
            "to $task->[$TASK_HOST]: ",
	        "defuncted due to failure of dependent task";
        }
    } $_[0], -1;
}

sub task_flag_done($) {
    my $ino = shift;

    my $info = new IO::File;

    $info->open("+< info/$ino") or do {
        plog "trouble: could not open info/$ino: $!";
        return;
    };
    $info->print(pack('c', 1));
    $info->close();
}

# read the results from the spawner
sub read_results() {
    my $line;
    my $old_sep;
    my $read_count;

    my $stage;
    my $buf;
    my $ok;
    my @lines;

    # read all the data from the pipe
    $stage .= $buf while
        (defined($ok = $srr->read($buf, 1024)) and $ok > 0);

    # add any saved data from the last read to the front of the
    # data
    $stage = $Srr_readbuffer . $stage;

    # turn the incoming data into a list of lines
    (@lines) = split(pack('c', 0x4), $stage);

    # we don't want to do anything if we have no data
    return if (scalar(@lines) == 0);

    # if the data is incomplete on the last line, we need to save it
    # for the next read
    if ($lines[$#lines] !~ /\0$/) {
        $Srr_readbuffer = pop(@lines);
    } else {
    # otherwise clear out that buffer
        $Srr_readbuffer = '';
    }

    # process each line
    foreach $line (@lines) {
        my ($num, $code, $msg);
        chomp($line);
        ($num, $code, $msg) = split('\0', $line);

        # this is a hack! if we get 0 as the task identifier
        # that means we are having some kind of bad error from
        # mcfeely-spawn
        if ($num == 0) {
            die "Got an error from mcfeely-spawn: $msg";
        }

        my $task = task_lookup $num;
        next unless defined $task;
        next unless defined $code;

        --$Tasks_in_progress;

        # take the \0 off the end of msg, it was a handy little
        # marker but we need it no more
        $msg =~ s/\0$//;

        # proces the task
        if ($code == $TASK_SUCCESS_CODE) {
            my $job = $task->[$TASK_JOB];

            plog "$job->[$JOB_INO]:$num ($task->[$TASK_COMM]) success: $msg";
            task_flag_done $num;
            $task->[$TASK_NEEDS_DONE] = 0; # XXX: this is redundant, isn't it?
            report $job->[$JOB_INO], "task $num ($task->[$TASK_COMM]) ",
                                 "to $task->[$TASK_HOST]: success: $msg";
            decrement_waiters $task;
            $job->[$JOB_NTASKS]--;
            finish_job $job if ($job->[$JOB_NTASKS] == 0);
        } elsif ($code == $TASK_DEFERRAL_CODE) {
            my $job = $task->[$TASK_JOB];

            plog "$job->[$JOB_INO]:$num ($task->[$TASK_COMM]) deferral: $msg";
            # exponential backoff stolen from djb
            $task->[$TASK_NEXT_TRY] =
                $task->[$TASK_BIRTH] +
                  ((($task->[$TASK_NEXT_TRY] - $task->[$TASK_BIRTH]) ** 0.5)
                   + 5) ** 2;
            task_enqueue $task;
        } elsif ($code == $TASK_FAILURE_CODE) {
            my $job = $task->[$TASK_JOB];

            plog "$job->[$JOB_INO]:$num ($task->[$TASK_COMM]) failure: $msg";
            report $job->[$JOB_INO], "task $num ($task->[$TASK_COMM]) ",
                                 "to $task->[$TASK_HOST]: failure: $msg";
            defunct_waiters $task;
            $job->[$JOB_FAILED] = 1;
            finish_job $job if ($job->[$JOB_NTASKS] == 0);
        } else {
            # something really unexpected happened
            my $job = $task->[$TASK_JOB];

            plog "$job->[$JOB_INO]:$num ($task->[$TASK_COMM]) failure: ",
                 "unknown code $code with $msg";
            report $job->[$JOB_INO], "task $num ($task->[$TASK_COMM]) ",
                                 "to $task->[$TASK_HOST]: failure: ",
                                 "unknown code $code with $msg";
            defunct_waiters $task;
            $job->[$JOB_FAILED] = 1;
            finish_job $job if ($job->[$JOB_NTASKS] == 0);
        }
    }
        
}

1;
