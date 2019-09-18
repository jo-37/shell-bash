#!perl
use strict;
use warnings;

use Shell::Bash;
use Test2::V0;

my $output;
my $rc;

# no input
$rc = bash 'echo hello', $output;
is $output, "hello\n", 'capture output';
is $rc, T(), 'retcode ok';

# copy input to output
my $input = <<EOF;
first line
second line
third line
EOF
$rc = bash 'cat', $output, $input;
is $output, $input, 'pipe input';
is $rc, T(), 'retcode ok';

# cmd fails
$rc = bash 'false', $output;
is $rc, F(), 'retcode fail';

# provide env var
$rc = bash 'echo $foo', $output, undef, foo => 'var from env';
is $output, "var from env\n", 'var from env';
is $rc, T(), 'retcode ok';

# special bash feature
$rc = bash 'cat <(echo -n "$foo")', $output, undef, foo => $input;
is $output, $input, 'special bash feature';
is $rc, T(), 'retcode ok';

done_testing;
