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

sub task_new_task(@) {
    my $key;
    my $val;
    my $task = [];

    while (@_) {
        $key = shift;
        $val = shift;
        $task->[$key] = $val;
    }

    return $task;
}

# return a new task IF APPROPRIATE
# IOW, don't return one if it doesn't NEED_DONE
sub task_new_task_from_file($) {
    my $ino = shift;
    my $data;
    my $task = [];
    my $waiters = [];

    open INFO, "info/$ino" or do {
        plog "Cannot open info/$ino: $!";
        return undef;
    };

    read INFO, $task->[$TASK_NEEDS_DONE], 1;
    $task->[$TASK_NEEDS_DONE] = ! unpack 'c', $task->[$TASK_NEEDS_DONE];
    if (! $task->[$TASK_NEEDS_DONE]) {
        close INFO;
        return undef;
    }
    read INFO, $task->[$TASK_NDEPS], 1;
    $task->[$TASK_NDEPS] = unpack 'c', $task->[$TASK_NDEPS];
    while ((read INFO, $data, 4) == 4) {
        $data = unpack 'L', $data;
        push @$waiters, $data;
    }
    $task->[$TASK_BIRTH] = (stat INFO)[10];
    close INFO;
    $task->[$TASK_WAITERS] = $waiters;
    $task->[$TASK_INO] = $ino;

    open TASK, "task/$ino" or do {
        plog "trouble: cannot open task/$ino: $!";
        return undef;
    };
    ($task->[$TASK_HOST] = <TASK>) =~ s,\0.*,,g;
    close TASK;

    return $task;
}

# insert a task into a hash table
sub task_insert($) {
    my $task = shift;

    $Task{$task->[$TASK_INO]} = $task;
}

# lookup a task in the hash table
sub task_lookup($) {
    my $ino = shift;

    $Task{$ino};
}
    
# insert a task into a priority queue
sub task_enqueue($) {
    my $task = shift;

    for ($i = 0; $i <= $#Tasks; ++$i) {
        if ($task->[$TASK_NEXT_TRY] <= $Tasks[$i]->[$TASK_NEXT_TRY]) {
            splice @Tasks, $i, 0, $task;
            return;
        }
    }
    push @Tasks, $task;
}

1;
