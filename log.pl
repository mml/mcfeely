# write log message to stdout
sub plog(@) { print STDOUT @_, "\n" }

sub bail(@) { plog @_; exit 0 }

1;
