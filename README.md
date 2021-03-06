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
```

> Please note that you can use [this module](examples/Bootstrap.pm). 

# Constants

```perl5
use constant CONSTANT1  => 'constant1';
use constant CONSTANT2  => 'constant2';
```

# Define a class

See [this example](examples/lib/namespace/MyClass.pm). This module defines the class `namespace::MyClass`.

To use this class, see [this script](examples/test_classes.pl).

# Use inheritance

See [This example](examples/lib/namespace/MyDerivedClass.pm). This module defines the class `namespace::MyDerivedClass`
that inherits from the class `namespace::MyClass` (see [this module](examples/lib/namespace/MyClass.pm)).

To use this class, see [this script](examples/test_inheritance.pl).

# Links

* [One liners](https://github.com/denis-beurive/linux-notes/blob/master/perl.md)
