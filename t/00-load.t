#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Shell::Bash' ) || print "Bail out!\n";
}

diag( "Testing Shell::Bash $Shell::Bash::VERSION, Perl $], $^X" );
