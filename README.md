# NAME

Shell::Bash - Execute bash commands

# SYNOPSIS

```perl
    use Shell::Bash;
    
    $Shell::Bash::debug = 1;

    my ($input, $output);

    # input and output, status check
    $input = 'fed to cmd';
    bash 'cat', $output, $input or warn('bash failed');
    print "output is '$output'\n";
    
    # no input
    bash 'echo hello', $output;
    print "output is '$output'\n";
    
    # use shell variable
    bash 'echo $foo', $output, undef, foo => 'var from env';
    print "output is '$output'\n";

    # use bashism
    bash 'cat <(echo $foo)', $output, undef, foo => 'var from file';
    print "output is '$output'\n";
```

# DESCIPTION
The `Shell::Bash` module provides an alternative interface for executing
shell commands in addition to 

- `qx{cmd}`
- `system('cmd')`
- `open CMD, '|-', 'cmd'`
- `open CMD, '-|', 'cmd'`

While these are convenient for simple commands, at the same
time they lack support for some advanced shell features.

Here is an example for something rather simple within bash that cannot
be done straightforward with perl:

```
    export passwd=secret
    key="$(openssl pkcs12 -nocerts -nodes -in somecert.pfx \
            -passin env:passwd)"
    signdata='some data to be signed'
    signature="$(echo -n "$signdata" | \
            openssl dgst -sha256 -sign <(echo "key") -hex"
    echo "$signature"
```

As there are much more openssl commands available on shell level
than via perl modules, this is not so simple to adopt.
One had to write the private key into a temporary file and feed
this to openssl within perl.
Same with input and output from/to the script: one has to be
on file while the other may be written/read to/from a pipe.

Other things to consider:

- `bash` might not be the default shell on the system.
- There is no way to specify by which interpreter `qx{cmd}` is executed.
- The default shell might not understand constructs like `<(cmd)`.
- perl variables are not accessible from the shell.

Another challenge consists in feeding the called command
with input from the perl script and capturing the output at
the same time.

The module `Shell::Bash` tries to merge the possibilities of the
above named alternatives into one. I.e.:

- use a specific command interpreter, `/bin/bash` as default
- provide the command to execute as a single string, like in `system()`
- give access to the full syntax of the command interpreter
- enable feeding of standard input and capturing standard output
of the called command 
- enable access to perl variables within the called command

Using the `Shell::Bash` module, the above given shell script example
might be implemented this way in perl:

```perl
    my $passwd = 'secret'
    my $key;
    bash 'openssl pkcs12 -nocerts -nodes -in demo.pfx \
            -passin env:passwd', $key, undef, passwd => $passwd;
    my $signdata = 'some data to be signed';
    my $signature;
    bash 'openssl dgst -sha256 -sign <(echo "$key") -hex',
             $signature, $signdata, key => $key;
    print $signature;
Quite similar, isn't it?
```

Actually, the a call to `openssl dgst` as above was the very reason
to create this module.

Commands given to `bash` are execute via `/bin/bash -c`
by default.
This might be modified by assigning another interpreter
to `@Shell::Bash::shell`.

Debugging output can be enabled by setting `$Shell::Bash::debug` to true.

# BUGS AND LIMITATIONS

There seems to be some race condition when the called script
closes its input file prior to passing all provided input
data to it.
Sometimes a SIGPIPE is caught and sometimes `syswrite`
returns an error.
It is not clear if all situations are handled correctly.

Best efford has been made to avoid blocking situations
where neither reading output from the script
nor writing input to it is possible.
However, under some circumstance such blocking might occur.

# AUTHOR

Jörg Sommrey

# LICENCE AND COPYRIGHT

Copyright (c) 2019, Jörg Sommrey. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
