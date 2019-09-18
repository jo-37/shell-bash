use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Shell::Bash',
    AUTHOR           => q{Jörg Sommrey <git@sommrey.de>},
    VERSION_FROM     => 'lib/Shell/Bash.pm',
    ABSTRACT_FROM    => 'lib/Shell/Bash.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
		'Test2::V0' => 0,
    },
    PREREQ_PM => {
		'IPC::Open2' => 0,
		'IO::Select' => 0,
		'IO::String' => 0,
		'Carp'	=> 0,
		'Exporter' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Shell-Bash-*' },
);
