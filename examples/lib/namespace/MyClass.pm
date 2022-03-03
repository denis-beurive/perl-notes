package namespace::MyClass;
use strict;
use warnings FATAL => 'all';
use base qw(Exporter);

use constant CONSTANT1  => 'constant1';
use constant CONSTANT2  => 'constant2';

# See http://search.cpan.org/~toddr/Exporter-5.72/lib/Exporter.pm#Good_Practices
our @EXPORT = qw(method1 CONSTANT1 CONSTANT2);
our %EXPORT_TAGS = (all => \@EXPORT);
our @EXPORT_OK = @EXPORT;

sub new {
    my ($inClassName, $inP1, $inP2) = @_;
    my $self = {
        property1 => $inP1,
        property2 => $inP2
    };
    bless $self, $inClassName;
    return $self;
}


sub method1() {
    my ($self, $inParam1, $inParam2) = @_;
    if ($inParam1 != $self->{property1}) {
        $self->{property1} = $inParam1;
    }
    if ($inParam2 != $self->{property2}) {
        $self->{property2} = $inParam2;
    }
    return($inParam1 + $inParam2);
}

1;
