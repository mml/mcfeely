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

$TASK_NEXT_TRY = 0;
$TASK_NDEPS = 1;
$TASK_INO = 2;
$TASK_JOB = 3;
$TASK_WAITERS = 4;
$TASK_NDEPS = 5;
$TASK_DEFUNCT = 6;
$TASK_BIRTH = 7;
$TASK_NEEDS_DONE = 8;
$TASK_HOST = 9;

$JOB_INO = 0;
$JOB_NTASKS = 1;
$JOB_FAILED = 2;
$JOB_NDEPS = 3;

$TASK_SUCCESS_CODE = 0;
$TASK_DEFERRAL_CODE = 99;
$TASK_FAILURE_CODE = 100;

$TASK_NUM_LENGTH = length pack 'L', 0;
$TASK_CODE_LENGTH = length pack 'c', ' ';

sub SLEEPYTIME() { 60 }

1;
