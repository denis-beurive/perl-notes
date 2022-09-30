#!/usr/bin/perl

# Usages:
#
#     perl log.pl --help
#     perl log.pl
#     perl log.pl --verbose
#     perl log.pl --path=log.txt
#     perl log.pl --path=log.txt --level=INFO
#     perl log.pl --path=log.txt --action=linearize
#     perl log.pl --path=log.txt --action=beautify
#     perl log.pl --path=log.txt --action=beautify --level=INFO

use strict;
use warnings FATAL => 'all';
use Getopt::Long;

BEGIN {
    use File::Spec ();
    sub __DIR__ () {
        my $level = shift || 0;
        my $file = (caller $level)[1];
        File::Spec->rel2abs(join '', (File::Spec->splitpath($file))[0, 1])
    }
}

BEGIN {
    # The class that represents a LOG boundary.
    package Message;
    sub new {
        my $class = shift;
        my $self = {
            year    => undef,
            month   => undef,
            day     => undef,
            hour    => undef,
            minute  => undef,
            second  => undef,
            level   => undef,
            session => undef,
            thread  => undef,
            module  => undef,
            payload => []
        };
        bless $self, $class;
        return $self;
    }
    sub set_year    { my ($self, $v) = @_; $self->{year} = $v }
    sub set_month   { my ($self, $v) = @_; $self->{month} = $v }
    sub set_day     { my ($self, $v) = @_; $self->{day} = $v }
    sub set_hour    { my ($self, $v) = @_; $self->{hour} = $v }
    sub set_minute  { my ($self, $v) = @_; $self->{minute} = $v }
    sub set_second  { my ($self, $v) = @_; $self->{second} = $v }
    sub set_level   { my ($self, $v) = @_; $self->{level} = $v }
    sub set_session { my ($self, $v) = @_; $self->{session} = $v }
    sub set_thread  { my ($self, $v) = @_; $self->{thread} = $v }
    sub set_module  { my ($self, $v) = @_; $self->{module} = $v }
    sub year        { my ($self) = @_; return $self->{year} }
    sub month       { my ($self) = @_; return $self->{month} }
    sub day         { my ($self) = @_; return $self->{day} }
    sub hour        { my ($self) = @_; return $self->{hour} }
    sub minute      { my ($self) = @_; return $self->{minute} }
    sub second      { my ($self) = @_; return $self->{second} }
    sub level       { my ($self) = @_; return $self->{level} }
    sub session     { my ($self) = @_; return $self->{session} }
    sub thread      { my ($self) = @_; return $self->{thread} }
    sub module      { my ($self) = @_; return $self->{module} }
    sub payload     { my ($self) = @_; return $self->{payload} }
    sub add_payload { my ($self, $v) = @_; push(@{$self->{payload}}, $v) }
}

use constant LINE_BOUNDARY  => 0;
use constant LINE_TEXT      => 1;

use constant STATUS_SUCCESS => 1;
use constant STATUS_ERROR   => 0;

use constant false          => 0;
use constant true           => 1;

# Example of line to parse:
# 2022-08-17 10:38:37.466  INFO 11481 --- [  nia-80-exec-2] o.apache.coyote.http11.Http11Processor : payload
use constant COL_DATE      => 0;
use constant COL_HOUR      => 1;
use constant COL_LEVEL     => 2;
use constant COL_SESSION   => 3;
use constant COL_SEP       => 4;
use constant COL_THREAD    => 5;
use constant COL_MODULE    => 6;
use constant COL_COLON     => 7;
use constant COL_MESSAGE   => 8;

# Useful links:
# https://logging.apache.org/log4j/log4j-2.2/manual/customloglevels.html
use constant LEVEL_FATAL => 'FATAL';
use constant LEVEL_ERROR => 'ERROR';
use constant LEVEL_WARN  => 'WARN';
use constant LEVEL_INFO  => 'INFO';
use constant LEVEL_DEBUG => 'DEBUG';
use constant LEVEL_TRACE => 'TRACE';
use constant LEVEL_ALL   => 'ALL';

my %LEVELS = (
    &LEVEL_FATAL => 0,
    &LEVEL_ERROR => 1,
    &LEVEL_WARN  => 2,
    &LEVEL_INFO  => 3,
    &LEVEL_DEBUG => 4,
    &LEVEL_TRACE => 5,
    &LEVEL_ALL   => 6
);
my $DEFAULT_LOG = File::Spec->catfile(__DIR__, 'log', 'app.log');

# CLI arguments.
use constant ACTION_BEAUTIFY => 'beautify';
use constant ACTION_LINEARIZE => 'linearize';


# Parse a line extracted from the LOG file.
#
# Example of line:
#     2022-08-17 10:38:37.466  INFO 11481 --- [  nia-80-exec-2] o.apache.coyote.http11.Http11Processor : payload
#     2022-08-17 10:38:37.466  INFO 11481 --- [nia-8888-exec-2] o.apache.coyote.http11.Http11Processor : payload
#
# @param $line The to parse.
# @return The function returns a couple of values (<type>, <data>).
#         <type>: the type of line:
#                 - LINE_BOUNDARY: a boundary that marks the start of a new message.
#                 - LINE_TEXT: a line of arbitrary text.
#         <data>: depending on the type of line, the data may be:
#                 - if type is LINE_BOUNDARY: an instance of Boundary.
#                 - if type is LINE_TEXT: a string that represents the text.

sub parse_line {
    my ($line) = @_;

    my $message = Message->new();

    chomp($line);
    # You can have "[  nio-80-exec-2] o.apache.coyote.http11.Http11Processor :"
    # We remove the spaces after the character "[".
    $line =~ s/\[\s*([^]]+)\](\s+[^:]+:)/[$1]$2/;

    my @fields = split /\s+/, $line, 9;
    return(LINE_TEXT, $line) if (int(@fields) < 8);
    return(LINE_TEXT, $line) if ($fields[COL_SEP] ne '---');
    return(LINE_TEXT, $line) if ($fields[COL_COLON] ne ':');

    if ($fields[COL_DATE] =~ m/(\d{4})\-(\d{2})\-(\d{2})/) {
        $message->set_year($1);
        $message->set_month($2);
        $message->set_day($3);
    } else { return(LINE_TEXT, $line) }

    if ($fields[COL_HOUR] =~ m/(\d{2}):(\d{2}):(\d{2})\.(\d+)/) {
        $message->set_hour($1);
        $message->set_minute($2);
        $message-> set_second($3);
    } else { return(LINE_TEXT, $line) }

    $message->set_level($fields[COL_LEVEL]);
    $message->set_session($fields[COL_SESSION]);
    $message->set_thread($fields[COL_THREAD]);
    $message->set_module($fields[COL_MODULE]);
    $message->add_payload($fields[COL_MESSAGE]);
    return (LINE_BOUNDARY, $message);
}

# Linearize a multi-line text.
#
# Replace:
#   - "\\" by "\\\\".
#   - "\n" by "\\n".
#   - "\r" by "\\r".
#
# Please note that this implementation is trivial. It may be optimized.
#
# @param $message The message to linearize.
# @return The linearized message.

sub linearize {
    my ($message) = @_;
    my $result = '';

    foreach my $char (split '', $message) {
        if ('\\' eq $char) { $result .= '\\\\'; next }
        if ("\n" eq $char) { $result .= '\\n'; next }
        if ("\r" eq $char) { $result .= '\\r'; next }
        $result .= $char;
    }
    return $result;
}

# Delinearize a previously linearized message.
#
# Please note that this implementation is trivial. It may be optimized.
#
# @param $message the linearized message.
# @return A list of 2 values.
#         - The first value indicates whether the operation is successful or not.
#           The value STATUS_SUCCESS means that the operation is successful.
#           The value STATUS_ERROR means that the operation is not successful.
#         - The signification of the second value depends on the status of the operation.
#           If the operation succeeds, then this value represents the delinearized message.
#           If the operation fails, then this value represents an error message.

sub delinearize {
    my ($message) = @_;
    my $result = '';
    my $start = false;
    my $position = 0;

    foreach my $char (split '', $message) {
        $position += 1;
        if (!$start && '\\' eq $char) { $start = true; next }
        if ($start) {
            $start = false;
            if ('\\' eq $char) { $result .= '\\'; next }
            if ('n' eq $char)  { $result .= "\n"; next }
            if ('r' eq $char)  { $result .= "\r"; next }
            return STATUS_ERROR, "Invalid character at position ${position}";
        }
        $result .= $char;
    }
    if (!$start) {
        return STATUS_ERROR, "Invalid character at position ${position}";
    }

    return STATUS_SUCCESS, $result;
}

sub beautify_payload {
    my ($payload, $session) = @_;
    return join "\n", map { sprintf('   # %s # %s', $session, $_) } @{$payload};
}

# Generate a string that represents a line of LOG from an instance of Message.
#
# @param $message An instance of Message.
# @param $action The action: ACTION_BEAUTIFY or ACTION_LINEARIZE
# @return A string that represents a line of LOG.

sub dump_log {
    my Message $message = shift;
    my $action = shift;

    printf("%s-%s-%s %s:%s:%s %s %s %s %s",
        $message->year(),
        $message->month(),
        $message->day(),
        $message->hour(),
        $message->minute(),
        $message->second(),
        $message->level(),
        $message->session(),
        $message->thread(),
        $message->module()
    );

    if (ACTION_LINEARIZE eq $action) {
        my $linearized = 0;
        my $payload = join("\n", @{$message->payload});
        if (int(@{$message->payload}) > 1) {
            $payload = linearize($payload);
            $linearized = 1;
        }
        printf(" %s %s\n", $linearized ? 'L' : 'R', $payload);
    } else {
        my $payload = beautify_payload($message->payload, $message->session);
        printf("\n%s\n", $payload);
    }
}

# Print the help.

sub help {
    my @levels = (sort { $LEVELS{$a} <=> $LEVELS{$b} } keys %LEVELS);
    print("Manage API LOG file.\n\n");
    print("Filter messages based on their criticality level (INFO, WARN, ERROR...).\n\n");
    print("Beautify (easier to read) or linearize (easier to parse) the messages.\n\n");
    print("perl log.pl --help\n");
    printf("perl log.pl [--verbose] [--path=<path to the LOG file>] [--action=(beautify|linearize)] [--level=(%s)]\n\n",
        join('|', @levels));
    printf("Default LOG file: \"%s\"\n", $DEFAULT_LOG);
    printf("Default action: \"%s\"\n", ACTION_BEAUTIFY);
    printf("Default level name: \"%s\"\n\n", LEVEL_ALL);
    printf("        %s name\n", 'level');
    printf("%s\n\n", join("\n", map {sprintf("         %4d %s", $LEVELS{$_}, $_)} @levels));
    print("If you specify the level which name is \"LEVEL,\" with the level L, then all LOGs with a level X, such as X is lesser or equal to L is printed. Other LOGs are discarded.\n\n");
}

# Parse the command line.
my $fd;
my $cli_log_path = $DEFAULT_LOG;
my $cli_level = LEVEL_ALL;
my $cli_action = ACTION_BEAUTIFY;
my $cli_verbose = undef;
my $cli_help = undef;
if (! GetOptions (
    'path=s'    => \$cli_log_path,
    'level=s'   => \$cli_level,
    'action=s'  => \$cli_action,
    'help'      => \$cli_help,
    'verbose'   => \$cli_verbose)) {
    print("Invalid command line!\n\n");
    help();
    exit(1);
}
$cli_action = lc($cli_action);

# Sanity checks.
if (defined($cli_help)) {
    help();
    exit(0);
}
if (! exists($LEVELS{$cli_level})) {
    my @levels = (sort { $LEVELS{$a} <=> $LEVELS{$b} } keys %LEVELS);
    printf("invalid LOG level \"%s\". Valid levels are: %s\n\n",
        $cli_level, join(', ', @levels));
    help();
    exit(1);
}
if ((ACTION_BEAUTIFY ne $cli_action) && (ACTION_LINEARIZE ne $cli_action)) {
    printf("Unexpected action \"%s\". Valid actions are: \"%s\", \"%s\"\n\n",
        $cli_action, ACTION_LINEARIZE, ACTION_BEAUTIFY);
    help();
    exit(1);
}

# Initialisation
printf("Open LOG file \"%s\" for %s\n", $cli_log_path, ACTION_BEAUTIFY eq $cli_action ?
    'beautification': 'linearization') if defined($cli_verbose);
if (! open($fd, '<', $cli_log_path)) {
    printf("Cannot open the LOG file \"%s\": %s\n", $cli_log_path, $!);
    exit(1);
}

my Message $message = undef;

# First, we skip junk lines. At the end of the loop, the variable $message is set.
my $status = undef;
while (<$fd>) {
    ($status, my $data) = parse_line($_);
    if (LINE_BOUNDARY == $status) { $message = $data; last }
}

# Parse the remaining of the file.
while (<$fd>) {
    ($status, my $data) = parse_line($_);
    if (LINE_TEXT == $status) { $message->add_payload($data); next }

    # We found a new boundary. We dump the previous one (that is, $message).
    dump_log($message, $cli_action) if $LEVELS{$message->level} <= $LEVELS{$cli_level};
    $message = $data;
}

# We need to dump the last message (if it is defined).
if (defined($message)) {
    dump_log($message, $cli_action) if $LEVELS{$message->level} <= $LEVELS{$cli_level};
}

