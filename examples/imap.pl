#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Net::IMAP::Simple;
use Email::MIME::Attachment::Stripper;
use File::Spec;
use File::Basename;
use DateTime;
use Data::Dumper;

use constant VERBOSE => 1;
use constant DEBUG => 0;
use constant IMAP_URI => 'your.server.url';
use constant IMAP_PORT => 7993;
use constant IMAP_USER => 'your-login';
use constant IMAP_PASSWORD => 'your-password';
use constant MAILBOXES => { INBOX => undef };
use constant OUTPUT_MESSAGE_DIR => File::Spec->catfile(File::Spec->rootdir(), 'tmp', 'messages');

#@type Net::IMAP::Simple
my $imap = undef;
my $messages_count;
my %mailboxes_hash;
my $index;

# Initialise the Perl environment, so this script does not rely on external configuration.
BEGIN {
    sub __DIR__ () {
        my $level = shift || 0;
        my $file = (caller $level)[1];
        File::Spec->rel2abs(join '', (File::Spec->splitpath($file))[0, 1])
    }
    sub DIRECTORY_SEPERATOR {
        return $^O eq "MSWin32" ? '\\' : '/';
    }
    use lib File::Spec->catfile(&__DIR__, 'modules');
}
use SFile;

# Set the termination callback.
END {
    print("Close the connection to the IMAP server\n") if &VERBOSE;
    $imap->quit() if defined($imap);
}

# Print a message associated with a fatal error and exit.
# @param $message The message to print.
sub log_fatal {
    my ($message) = @_;
    printf("ERROR: %s\n", $message);
    exit(1);
}

# Print a message associated with a warning.
# @param $message The message to print.
sub log_warning {
    my ($message) = @_;
    printf("WARNING: %s\n", $message);
}

# ---------------------------------------------------------------------
# Sanity checks.
# ---------------------------------------------------------------------

if (! -d &OUTPUT_MESSAGE_DIR) {
    log_fatal(sprintf('directory "%s" does not exist!', &OUTPUT_MESSAGE_DIR));
}

# ---------------------------------------------------------------------
# Open the connection to the IMAP server
# ---------------------------------------------------------------------

printf("Connect to the IMAP server whose URI is \"%s\" as \"%s\" (password: \"%s\")\n",
        &IMAP_URI,
        &IMAP_USER,
        defined(&IMAP_PASSWORD) ? &IMAP_PASSWORD : '') if &VERBOSE;

$imap = Net::IMAP::Simple->new(&IMAP_URI,
    port    => &IMAP_PORT,
    use_ssl => 1,
    timeout => 5,
    debug   => &DEBUG ? 1 : 0) ||
    log_fatal("unable to connect to the IMAP server: " . $Net::IMAP::Simple::errstr);

$imap->login(&IMAP_USER, &IMAP_PASSWORD) ||
    log_fatal("login to the IMAP server failed: " . $imap->errstr);

print("Successfully connected!\n") if &VERBOSE;

# ---------------------------------------------------------------------
# Get the list of mailboxes and make sure that the necessary ones exist
# ---------------------------------------------------------------------

%mailboxes_hash = map { $_ => undef } $imap->mailboxes();
printf("List of mailboxes:\n%s\n", join("\n", map { sprintf("   - %s", $_) } (sort keys %mailboxes_hash))) if (&VERBOSE);

foreach my $mailbox (sort keys %{&MAILBOXES}) {
    if (!exists($mailboxes_hash{$mailbox})) {
        log_fatal(sprintf('the mailbox "%s" does not exist on the IMAP server!', $mailbox));
    }
    $messages_count = $imap->select($mailbox);
    printf("Number of messages in mailbox \"%s\": %d\n", $mailbox, $messages_count) if &VERBOSE;
}

# ---------------------------------------------------------------------
# List the message stored in INBOX.
# ---------------------------------------------------------------------

$messages_count = $imap->select('INBOX');

$index = 0;
foreach my $id (1 .. $messages_count) {
    my $text;
    my $path_id;
    my $attachment_dir;
    my $path;
    my $file;
    my $stripper;
    my @attachments;
    my $datetime;

    # Retrieve the message from the mailbox.
    $index += 1;
    $text = $imap->get($id);
    log_fatal(sprintf("cannot get the message which ID is %d - index:%d (from mailbox \"INBOX\")!", $id, $index)) unless defined($text);
    $text =~ s/\r//g; # WARNING: we need to remove the characters "carriage return", otherwise the parsing of the emails fails (at least on Windows).

    # Save the entire message into a file.
    $datetime = DateTime->now();
    $path_id = sprintf("message-%04d%02d%02d-%02d%02d%02d.%09d.%s",
        $datetime->year,
        $datetime->month,
        $datetime->day,
        $datetime->hour,
        $datetime->minute,
        $datetime->second,
        $datetime->nanosecond,
        $id);
    $path = File::Spec->catfile(&OUTPUT_MESSAGE_DIR, "${path_id}.mess");
    printf("Save email id:\"%s\" into file \"%s\"\n", $id, $path) if &VERBOSE;
    $file = SFile->new($path);
    log_fatal($file->lastError()) if (! $file->writeBinary($text));

    # Extract all attached files from the previously retrieved message.
    $stripper = Email::MIME::Attachment::Stripper->new($text);
    @attachments = $stripper->attachments;
    $attachment_dir = File::Spec->catfile(&OUTPUT_MESSAGE_DIR, $path_id);

    foreach my $attachment (@attachments) {
        my $filename = $attachment->{filename};
        my $payload = $attachment->{payload};
        my $content_type = $attachment->{content_type};
        my $file_path;

        next if (0 == length($filename));

        if (! -d  $attachment_dir) {
            mkdir($attachment_dir) or log_fatal(sprintf('cannot create the directory "%s": %s', $path_id, $!));
        }
        $file_path = File::Spec->catfile(&OUTPUT_MESSAGE_DIR, $path_id, $filename);
        printf("Save attachment into \"%s\"\n", $file_path);
        $file = SFile->new($file_path);
        log_fatal($file->lastError()) if (! $file->writeBinary($payload));
    }
}

