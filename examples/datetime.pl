#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use DateTime;
use DateTime::Duration;

use constant DATE_FROM => '2022-01-01 00:00:00';
use constant DATE_TO => '2022-06-01 00:00:00';

sub date_to_string {
    my (#@type DateTime
        $date) = @_;
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $date->year, $date->month, $date->day, $date->hour, $date->minute, $date->second);
}

sub string_to_date {
    my ($string) = @_;
    if ($string =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        return DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6
        )
    }
    return(undef);
}

my $d_from;
my $d_to;
my $window = DateTime::Duration->new(hours => 1);

$d_from = string_to_date(&DATE_FROM);
defined($d_from) or die(sprintf('invalid date "%s"', &DATE_FROM));
$d_to = string_to_date(&DATE_TO);
defined($d_to) or die(sprintf('invalid date "%s"', &DATE_TO));
DateTime->compare($d_from, $d_to) <= 0 or die(sprintf('"%s" > "%s"', &DATE_FROM, &DATE_TO));

while (DateTime->compare($d_from, $d_to) < 0) {
    my $d_window = $d_from->clone()->add_duration($window);
    printf("%s;%s;%s\n", $d_from->day_name(), date_to_string($d_from), date_to_string($d_window));
    $d_from->add_duration($window);
}
