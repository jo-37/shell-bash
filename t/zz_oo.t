#!perl
use strict;
use warnings;

use Shell::Run;
use Test2::V0;
use Test2::Tools::Class;

my $output;
my $rc;

my $bash = Shell::Run->new(name => 'bash');
isa_ok($bash, ['Shell::Run'], 'got blessed object');

# run test
$rc = $bash->run('echo hello', $output);
is $output, "hello\n", 'capture output';
is $rc, T(), 'retcode ok';

done_testing;
