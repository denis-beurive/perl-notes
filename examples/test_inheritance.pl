#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

BEGIN {
    # Set the environment.
    use File::Spec ();
    sub __DIR__ () {
        my $level = shift || 0;
        my $file = (caller $level)[1];
        File::Spec->rel2abs(join '', (File::Spec->splitpath($file))[0, 1])
    }
    use lib File::Spec->catfile(__DIR__, 'lib');
}

use namespace::MyDerivedClass;

my $object = namespace::MyDerivedClass->new(1, 2, 3);
$object->method();
