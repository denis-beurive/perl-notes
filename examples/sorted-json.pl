use strict;
use warnings FATAL => 'all';
use JSON;

sub json_beautify {
    my ($data) = @_;

    my $json = JSON->new();
    return $json->canonical->pretty->ascii->encode($data);
}

my $hash = {
	ghi => 3,
	def => 2,
	abc => 1
};

printf("Sorted hash is:\n\n%s\n\n", json_beautify($hash));

# Result:
#
# {
#   "abc" : 1,
#   "def" : 2,
#   "ghi" : 3
# }

