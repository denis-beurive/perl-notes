package namespace::MyDerivedClass;
use strict;
use warnings FATAL => 'all';

use base ('namespace::MyClass');
use strict;
use warnings;
use namespace::MyClass;

# See http://search.cpan.org/~toddr/Exporter-5.72/lib/Exporter.pm#Good_Practices
our @EXPORT = qw(method);
our %EXPORT_TAGS = (all => \@EXPORT);
our @EXPORT_OK = @EXPORT;

sub new {
 	my ($inClassName, , $inP1, $inP2, $inP3) = @_;
 	my $self = $inClassName->SUPER::new($inP1, $inP2);
 	$self->{property} = $inP3;
	bless $self, $inClassName;
	return $self;
}

# Note: you should not override methods. This is considered bad practice in Perl.
#       If you really want to do so, then replace remove the line "use warnings FATAL => 'all';".

sub method() {
    my ($self) = @_;
    print("property1 = " . $self->{property1} . "\n");
    print("property2 = " . $self->{property2} . "\n");
    print("property  = " . $self->{property} . "\n");
}

1;
