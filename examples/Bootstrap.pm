package Bootstrap;
use strict;
use warnings FATAL => 'all';
use base qw(Exporter);
use File::Spec ();

our @EXPORT = qw(__DIR__);

sub __DIR__ () {
	my $level = shift || 0;
	my $file = (caller $level)[1];
	File::Spec->rel2abs(join '', (File::Spec->splitpath($file))[0, 1])
}

use lib File::Spec->catfile(__DIR__, 'lib', 'provate');
use lib File::Spec->catfile(__DIR__, 'lib', 'public');

1;