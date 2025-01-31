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

# send instructions to the spawner
sub write_to_spawner($) {
    my $ino = shift;

    my $buf = "$ino\n";
    my $length = length $buf;
    my $count;

    $count = $siw->syswrite($buf, $length);
    if ((!defined($count)) or ($count != $length)) {
        return 0;
    }
    return 1;
}

# attempt all tasks whose times have come
sub attempt_tasks() {
    my $i;
    my $task;
    my $now = time;
    my @ntasks;

    TASK: for ($i = 0; $i <= $#Tasks; ++$i) {
        $task = $Tasks[$i];

        # Since the tasks are sorted by NEXT_TRY time, if this one is in the
        # future, so are all the rest, so let's just cut to the chase.  In the
        # process, we recreate @Tasks, but don't include any of the tasks we've
        # just attempted.  When the results come back from the spawner, they'll
        # either be removed from the action or reinserted into the queue.
        if ($task->[$TASK_NEXT_TRY] > $now) {
            push @ntasks, @Tasks[$i..$#Tasks];
            last TASK;
        }

        if ($task->[$TASK_NDEPS] > 0) {
            push @ntasks, $task;
        } else {
            plog "$task->[$TASK_JOB]->[$JOB_INO]:$task->[$TASK_INO] " .
                 "($task->[$TASK_COMM]) starting transfer to " .
                 "$task->[$TASK_HOST]";

            # totally guessing here on this, what we are after
            # is if the write to the pipe fails we wanna do it
            # again later cjd 2000.0623
            if (write_to_spawner $task->[$TASK_INO]) {
                $task->[$TASK_NEXT_TRY] = $now;
                ++$Tasks_in_progress;
            } else {
                plog "$task->[$TASK_JOB]->[$JOB_INO]:$task->[$TASK_INO] " .
                 "($task->[$TASK_COMM]) writing_to_spawner failed " .
                 "$!";
                # push the task back on this to look at later
                #push @ntasks, $task;
                push @ntasks, @Tasks[$i..$#Tasks];
                last TASK;
            }
        }
    }

    @Tasks = @ntasks;
}

1;
