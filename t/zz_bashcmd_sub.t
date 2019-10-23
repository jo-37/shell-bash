#!perl
use strict;
use warnings;

use Shell::Run (as => 'run_sh');
use Test2::V0;
use Test2::Tools::Class;

my $output;

# no input
run_sh 'echo hello', $output;
is $output, "hello\n", 'capture output';

done_testing;
