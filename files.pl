# usage: files(DIRHANDLE)
# returns files like readdir, but it skips . and ..
sub files(*) {
    my $glob = shift;

    return(grep { !/^\.\.?$/ } readdir $$glob) if wantarray;
    while ($_ = readdir $$glob) { return $_ unless /^\.\.?$/ }
    return undef;
}

1;
