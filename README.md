# NAME

Shell::Run - Execute shell commands using specific shell

# SYNOPSIS

## Procedural Interface

```perl
    use Shell::Run 'sh';
    my ($input, $output);

    # no input
    sh 'echo -n hello', $output;
    print "output is '$output'\n";
    # gives "output is 'hello'"

    # input and output, status check
    $input = 'fed to cmd';
    sh 'cat', $output, $input or warn 'sh failed';
    print "output is '$output'\n";
    # gives "output is 'fed to cmd'"
    
    # insert shell variable
    sh 'echo -n $foo', $output, undef, foo => 'var from env';
    print "output is '$output'\n";
    # gives "output is 'var from env'"

    # special bash feature
    use Shell::Run 'bash';
    bash 'cat <(echo -n $foo)', $output, undef, foo => 'var from file';
    print "output is '$output'\n";
    # gives "output is 'var from file'"

    # change export name
    use Shell::Run 'sea-shell.v3' => {as => 'seash3'};
    seash3 'echo hello', $output;

    # specify program not in PATH
    use Shell::Run sgsh => {exe => '/opt/shotgun/shell'};
    sgsh 'fire', $output;

    # not a shell
    use Shell::Run sed => {args => ['-e']};
    sed 's/fed to/eaten by/', $output, $input;
    print "output is '$output'\n";
    # gives "output is 'eaten by cmd'"

    # look behind the scenes
    use Shell::Run sh => {debug => 1, as => 'sh_d'};
    sh_d 'echo', $output;
    # gives:
    ## using shell: /bin/sh -c
    ## executing cmd:
    ## echo -n
    ##
    ## closing output from cmd
    ## cmd exited with rc=0

    # remove export
    no Shell::Run qw(seash3 sgsh);
    # from here on seash3 and sgsh are no longer known
    # use aliased name (seash3) if provided!
```

## OO Interface

```perl
    use Shell::Run;

    my $bash = Shell::Run->new(name => 'bash');

    my ($input, $output);

    # input and output, status check
    $input = 'fed to cmd';
    $bash->run('cat', $output, $input) or warn('bash failed');
    print "output is '$output'\n";
    
    # everything else analogous to the procedural interface
    
```

# DESCIPTION

The Shell::Run module provides an alternative interface for executing
shell commands in addition to 

- `qx{cmd}`
- `system('cmd')`
- `open CMD, '|-', 'cmd'`
- `open CMD, '-|', 'cmd'`
- [IPC::Run](https://metacpan.org/pod/IPC::Run)

While these are convenient for simple commands, at the same
time they lack support for some advanced shell features.

Here is an example for something rather simple within bash that cannot
be done straightforward with perl:

```sh
    export passwd=secret
    key="$(openssl pkcs12 -nocerts -nodes -in somecert.pfx \
            -passin env:passwd)"
    signdata='some data to be signed'
    signature="$(echo -n "$signdata" | \
            openssl dgst -sha256 -sign <(echo "$key") -hex"
    echo "$signature"
```

As there are much more openssl commands available on shell level
than via perl modules, this is not so simple to adopt.
One had to write the private key into a temporary file and feed
this to openssl within perl.
Same with input and output from/to the script: one has to be
on file while the other may be written/read to/from a pipe.

Other things to consider:

- There is no way to specify by which interpreter `qx{cmd}` is executed.
- The default shell might not understand constructs like `<(cmd)`.
- perl variables are not accessible from the shell.

Another challenge consists in feeding the called command
with input from the perl script and capturing the output at
the same time.
While this last item is perfectly solved by [IPC::Run](https://metacpan.org/pod/IPC::Run),
the latter is rather complex and even requires some special setup to
execute code by a specific shell.

The module Shell::Run tries to merge the possibilities of the
above named alternatives into one. I.e.:

- use a specific command interpreter e.g. `bash`.
- provide the command to execute as a single string, like in `system()`
- give access to the full syntax of the command interpreter
- enable feeding of standard input and capturing standard output
of the called command 
- enable access to perl variables within the called command

Using the Shell::Run module, the above given shell script example
might be implemented this way in perl:

```perl
    use Shell::Run 'bash';

    my $passwd = 'secret';
    my $key;
    bash 'openssl pkcs12 -nocerts -nodes -in demo.pfx \
            -passin env:passwd', $key, undef, passwd => $passwd;
    my $signdata = 'some data to be signed';
    my $signature;
    bash 'openssl dgst -sha256 -sign <(echo "$key") -hex',
             $signature, $signdata, key => $key;
    print $signature;
```

Quite similar, isn't it?

Actually, the call to `openssl dgst` as above was the very reason
to create this module.

Commands run by Shell::Run are by default executed via the `-c` option
of the specified shell.
This behaviour can be modified by providing other arguments in the
`use` statement or the constructor `Shell::Run->new`.

Debugging output can be enabled in a similar way.

# USAGE

The procedural interface's behaviour can be configured by arguments given
to the `use` statement:

- use Shell::Run qw(_name_...)

    Searches every given _name_ in `PATH` and exports a subroutine of the
    same name for each given argument into the caller for accessing the
    specified external programs.

- use Shell::Run _name_ => _options_, ...

    Export a subroutine into the caller for accessing an external program.
    Unless otherwise specified in _options_, search for an executable
    named _name_ in `PATH` and export a subroutine named _name_

    _options_ must be a hash reference as follows:

    - exe => _executable_

        Use _executable_ as the path to an external program.
        Disables a `PATH` search.

    - args => _arguments_

        Call the specified external program with these arguments.
        Must be a reference to an array.

        Default: `['-c']`.

    - as => _export_

        Use _export_ as the name of the exported subroutine.

    - debug => _debug_

        Provide debugging output to `STDERR` if _debug_ has a true value.

# FUNCTIONS

- _name_ _cmd_, _output_, \[_input_, \[_key_ => _value_,...\]\]

    Call external program configured as _name_.

    - _cmd_

        The code that is to be executed by this command.

    - _output_

        A scalar that will receive STDOUT from _cmd_.
        The content of this variable will be overwritten by `$sh->run` calls.

    - _input_

        An optional scalar holding data that is fed to STDIN of _cmd_

    - _key_ => _value_, ...

        A list of key-value pairs that are set in the environment of the
        called shell.

# METHODS

## Constructor

### Shell::Run->new(\[_options_\])

_options_ (if provided) must be a hash as follows:

- name => _name_

    Searches _name_ in `PATH` for an external program to be used.

    This value is ignored if _executable_ is given and defaults to `sh`.

- exe => _executable_

    Use _executable_ as the path to an external program.
    Disables a `PATH` search.

- args => _arguments_

    Call the specified external program with these arguments.
    Must be a reference to an array.

    Default: `['-c']`.

- debug => _debug_

    Provide debugging output to `STDERR` if _debug_ has a true value.

## Methods

### $sh->run(_cmd_, _output_, \[_input_, \[_key_ => _value_, ...\]\])

- _cmd_

    The code that is to be executed by this shell.

- _output_

    A scalar that will receive STDOUT from _cmd_.
    The content of this variable will be overwritten by `$sh->run` calls.

- _input_

    An optional scalar holding data that is fed to STDIN of _cmd_

- _key_ => _value_, ...

    A list of key-value pairs that are set in the environment of the
    called shell.

# BUGS AND LIMITATIONS

There seems to be some race condition when the called script
closes its input file prior to passing all provided input
data to it.
Sometimes a SIGPIPE is caught and sometimes `syswrite`
returns an error.
It is not clear if all situations are handled correctly.

Best effort has been made to avoid blocking situations
where neither reading output from the script
nor writing input to it is possible.
However, under some circumstance such blocking might occur.

# SEE ALSO

For more advanced interaction with background processes see [IPC::Run](https://metacpan.org/pod/IPC::Run).

# AUTHOR

Jörg Sommrey

# LICENCE AND COPYRIGHT

Copyright (c) 2019, Jörg Sommrey. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
