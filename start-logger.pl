#!/usr/bin/perl

# vi:ts=4:sw=4:noet:wm=0
# $Id: start-logger.pl,v 1.1.2.1 2000/07/20 21:34:10 jeremy Exp $
# $Source: /home/mml/Projects/mcfeely/scratch/mcfeely-mirror/Attic/start-logger.pl,v $

# Quick and dirty logger to take mcfeely-start information and pass
# it to syslog. This is invoked as part of the init script

use strict;
use Sys::Syslog;

my ($ident, $logopt, $facility, $priority);

$ident = "Mcfeely-start";
$logopt = "pid";
$facility = "local6";
$priority = "debug";

openlog($ident, $logopt, $facility);
syslog('$priority, $!');
closlog();

