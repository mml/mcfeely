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

sub job_read_task($$) {
    my $fileref = shift;
    my $numref = shift;

    # read 4 bytes off the file
    my $return = $fileref->read($$numref, 4);

    # did we get what we wanted?
    return 0 if ($return != 4);

    # turn it into a long
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
    my $tasknum;

    # pre make handles for the opens down below
    my $dirhandle  = new IO::Dir;
    my $deschandle = new IO::File;
    my $jobhandle  = new IO::File;

    # open up the directory and scan for some jobs in there
    $dirhandle->open($dir) or do {
        plog "Could not open $dir: $!";
        return undef;
    };

    # for each job in there, take a look at it
    GET_JOB: while (defined($file = files($dirhandle))) {
        plog "$file new job" if $log_new;

        # get the description so we can log it
        $deschandle->open("desc/$file") or do {
            plog "Could not open desc/$file: $!";
            next GET_JOB;
        };
        plog "$file info: ", <$deschandle>;
        $deschandle->close();

        # open the job to get out the task number
        $job = job_new_job $JOB_INO => $file;
        $jobhandle->open("$dir/$file") or do {
            plog "Could not open $dir/$file: $!\n";
            next GET_JOB;
        };
        $jobhandle->seek(1, 1); #XXX: does this belong abstracted?
        TASK: while (job_read_task($jobhandle, \$tasknum)) {
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
        $jobhandle->close();
        rename "$dir/$file", "job/$file" if $log_new;

        # For each task, $task->[$TASK_WAITERS] is a list of task
        # numbers. Look up those numbers in %task and replace them
        # with the actual task references.
        foreach $task (keys %task) {
            my $i;
            for ($i = 0; $i <= $#{$task->[$TASK_WAITERS]}; ++$i) {
                splice @{$task->[$TASK_WAITERS]}, $i, 1,
                       $task{$task->[$TASK_WAITERS]->[$i]};
            }
        }
    }
    $dirhandle->close();
    return 1;
}

1;
