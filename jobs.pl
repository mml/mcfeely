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
# You may contact the author at <mml@pobox.com>.

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
        plog "$file new job" if $log_new;
        open DESC, "desc/$file" or do {
            plog "Could not open desc/$file: $!";
            next JOB;
        };
        plog "$file info: ", <DESC>;
        close DESC;
        $job = job_new_job $JOB_INO => $file;
        open JOB, "$dir/$file" or do {
            plog "Could not open $dir/$file: $!\n";
            next JOB;
        };
        seek JOB, 1, 1; #XXX: does this belong abstracted?
        TASK: while (job_read_task(JOB, $tasknum)) {
            $task = task_new_task_from_file $tasknum;
            next TASK unless defined $task;
            $task->[$TASK_JOB] = $job;

            # if we got a task back, we can assume it NEEDS_DONE
            # see also sub task_new_task_from_file
            task_insert $task;
            task_enqueue $task;
            $job->[$JOB_NTASKS]++;

            $task{$tasknum} = $task;
        }
        close JOB;
        rename "$dir/$file", "job/$file" if $log_new;
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
