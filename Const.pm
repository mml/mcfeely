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

package McFeely::Const;
use strict;

use vars qw(@ISA @EXPORT
$TASK_NEXT_TRY $TASK_NDEPS $TASK_INO $TASK_JOB $TASK_WAITERS 
$TASK_DEFUNCT $TASK_BIRTH $TASK_NEEDS_DONE $TASK_HOST $TASK_COMM 
$JOB_INO $JOB_NTASKS $JOB_FAILED $JOB_NDEPS 
$TASK_SUCCESS_CODE $TASK_DEFERRAL_CODE $TASK_FAILURE_CODE  
$TASK_NUM_LENGTH $TASK_CODE_LENGTH  );

require Exporter;
@ISA =    qw (Exporter);
# oughta be an easier way
@EXPORT = qw (
$TASK_NEXT_TRY $TASK_NDEPS $TASK_INO $TASK_JOB $TASK_WAITERS 
$TASK_DEFUNCT $TASK_BIRTH $TASK_NEEDS_DONE $TASK_HOST $TASK_COMM 

$JOB_INO $JOB_NTASKS $JOB_FAILED $JOB_NDEPS 

$TASK_SUCCESS_CODE $TASK_DEFERRAL_CODE $TASK_FAILURE_CODE 
$TASK_NUM_LENGTH $TASK_CODE_LENGTH 

SLEEPYTIME

);


$TASK_NEXT_TRY = 0;
$TASK_NDEPS = 1;
$TASK_INO = 2;
$TASK_JOB = 3;
$TASK_WAITERS = 4;
$TASK_DEFUNCT = 5;
$TASK_BIRTH = 6;
$TASK_NEEDS_DONE = 7;
$TASK_HOST = 8;
$TASK_COMM = 9;

$JOB_INO = 0;
$JOB_NTASKS = 1;
$JOB_FAILED = 2;
$JOB_NDEPS = 3;

$TASK_SUCCESS_CODE = 0;
$TASK_DEFERRAL_CODE = 99;
$TASK_FAILURE_CODE = 100;

$TASK_NUM_LENGTH = length pack 'L', 0;
$TASK_CODE_LENGTH = length pack 'c', 0;

sub SLEEPYTIME() { 60 }

1;
