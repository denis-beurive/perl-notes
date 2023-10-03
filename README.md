# Notes about Perl

## Standard initialisation

```perl5
#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
```

## Set the environment

This will set the module directory to the subdirectory `lib`.

```perl5
#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    use File::Spec ();
    sub __DIR__ () {
        my $level = shift || 0;
        my $file = (caller $level)[1];
        File::Spec->rel2abs(join '', (File::Spec->splitpath($file))[0, 1])
    }
    use lib File::Spec->catfile(__DIR__, 'lib');
}
# Below this point you can import modules that are located under "lib".
```

> Please note that you can use [this module](examples/Bootstrap.pm). 

# Constants

```perl5
use constant CONSTANT1  => 'constant1';
use constant CONSTANT2  => 'constant2';
use constant CONF       => { path => '/tmp/toto' }; # can be a reference
```

Then, you prefix the identifiers used to declare the constants by `&` (these constants are functions that return a value).

Ex:

```perl
use constant CONSTANT1  => 'constant1';

printf("value: %s\n", &CONSTANT1);

# or:
printf("value: %s\n", &CONSTANT1()); # because this is a function
```

# Define a class

See [this example](examples/lib/namespace/MyClass.pm). This module defines the class `namespace::MyClass`.

To use this class, see [this script](examples/test_classes.pl).

# Use inheritance

See [This example](examples/lib/namespace/MyDerivedClass.pm). This module defines the class `namespace::MyDerivedClass`
that inherits from the class `namespace::MyClass` (see [this module](examples/lib/namespace/MyClass.pm)).

To use this class, see [this script](examples/test_inheritance.pl).

# Define a class outside a module

Did you know that you can define a class outside a module (`.pm` file) ?

You can even define 2 or more classes with the same `.pl` file.

This can be pretty handy if you need a "single file script" with no dependencies.

The trick is to define a class within a `BEGIN{...}` block. _Please note that you can write as many of these blocks in a single file_.

Please see [this example](examples/log-parser.pl) that implements a parser for Log4J generated LOG files.

# Print JSON with sorted keys

Showing sorted keys makes things much easier to read !

Easy ! Look at [this](examples/sorted-json.pl).

# HTTP requests

See [this example](examples/Mailjet.pm).

# Imap and Pop3

* [imap.pl](examples/imap.pl)
* [pop3.pl](examples/pop3.pl)

# Date and time

See [this example](examples/datetime.pl).

# Links

* [One liners](https://github.com/denis-beurive/linux-notes/blob/master/perl.md)

