# NAME

Shell::Run - Execute shell commands using specific shell

# SYNOPSIS

        use Shell::Run;
        
        my $bash = Shell::Run->new(name => 'bash');

        my ($input, $output);

        # input and output, status check
        $input = 'fed to cmd';
        $bash->run('cat', $output, $input) or warn('bash failed');
        print "output is '$output'\n";
        
        # no input
        $bash->run('echo hello', $output);
        print "output is '$output'\n";
        
        # use shell variable
        $bash->run('echo $foo', $output, undef, foo => 'var from env');
        print "output is '$output'\n";

        # use bash feature
        $bash->run('cat <(echo $foo)', $output, undef, foo => 'var from file');
        print "output is '$output'\n";

# DESCIPTION
The `Shell::Run` class provides an alternative interface for executing
shell commands in addition to 

- `qx{cmd}`
- `system('cmd')`
- `open CMD, '|-', 'cmd'`
- `open CMD, '-|', 'cmd'`
- `IPC::Run`

While these are convenient for simple commands, at the same
time they lack support for some advanced shell features.

Here is an example for something rather simple within bash that cannot
be done straightforward with perl:

        export passwd=secret
        key="$(openssl pkcs12 -nocerts -nodes -in somecert.pfx \
                -passin env:passwd)"
        signdata='some data to be signed'
        signature="$(echo -n "$signdata" | \
                openssl dgst -sha256 -sign <(echo "$key") -hex"
        echo "$signature"

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
While this last item is perfectly solved by `IPC::Run`,
the latter is rather complex and even requires some special setup to
execute code by a specific shell.

The class `Shell::Run` tries to merge the possibilities of the
above named alternatives into one. I.e.:

- use a specific command interpreter e.g. `bash` (or `sh` as default
which does not make too much sense).
- provide the command to execute as a single string, like in `system()`
- give access to the full syntax of the command interpreter
- enable feeding of standard input and capturing standard output
of the called command 
- enable access to perl variables within the called command

Using the `Shell::Run` class, the above given shell script example
might be implemented this way in perl:

        my $bash = Shell::Run->new(name => 'bash');

        my $passwd = 'secret';
        my $key;
        $bash->run('openssl pkcs12 -nocerts -nodes -in demo.pfx \
                -passin env:passwd', $key, undef, passwd => $passwd);
        my $signdata = 'some data to be signed';
        my $signature;
        $bash->run('openssl dgst -sha256 -sign <(echo "$key") -hex',
                 $signature, $signdata, key => $key);
        print $signature;

Quite similar, isn't it?

Actually, the call to `openssl dgst` as above was the very reason
to create this class.

Commands run by `$sh->run` are by default executed via the `-c` option
of the specified shell.
This behaviour can be modified by providing other arguments in the
constructor `Shell::Run->new`.

Debugging output can be enabled in a similar way.

# METHODS

## Constructor

### Shell::Run->new(\[name => _shell_,\] \[exe => _path_,\] \[args => _arguments_,\] \[debug => _debug_\])

- _shell_

    The name of the shell interpreter to be used by the
    created instance.
    The executable is searched for in the `PATH` variable.

    This value is ignored if _path_ is given and defaults to `sh`.

- _path_

    The fully specified path to an executable to be used by
    the created instance.

- _arguments_

    If _arguments_ is provided, it shall be a reference to an array
    specifying arguments that are passed to the specified shell.

    The default is `-c`.
    Use a reference to an empty array to avoid this.

- _debug_

    When _debug_ is set to true, calls to the `run` method will print
    debugging output to STDERR.

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
