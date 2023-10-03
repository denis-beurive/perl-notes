#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Mail::POP3Client;
use Email::MIME::Attachment::Stripper;
use File::Spec;
use File::Basename;
use DateTime;

use constant VERBOSE => 1;
use constant POP_PORT => 7110;
use constant POP_URI => 'your.server.url';
use constant POP_USER => 'your-login';
use constant POP_PASSWORD => 'your-password';
use constant OUTPUT_MESSAGE_DIR => File::Spec->catfile(File::Spec->rootdir(), 'tmp', 'messages');

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

#@type Mail::POP3Client
my $pop;

# Set the termination callback.
END {
    print("Close the connection to the POP3 server\n") if &VERBOSE;
    $pop->Close() if defined($pop);
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

printf("Connect to POP3 server \"%s\" on port %d (user: %s, password: %s)\n", &POP_URI, &POP_PORT, &POP_USER, &POP_PASSWORD);

$pop = new Mail::POP3Client( USER     => &POP_USER,
                             PASSWORD => &POP_PASSWORD,
                             HOST     => &POP_URI,
                             PORT     => &POP_PORT,
                             TIMEOUT  => 5,
                             USESSL   => 0,
                             DEBUG    => 0);
log_fatal('cannot open connection to POP server') if (!defined($pop));
printf("Is connection alive ? %s\n", $pop->Alive() ? 'yes' : 'no') if &VERBOSE;
log_fatal('cannot open connexion to POP server (connection is dead)') if ('DEAD' eq $pop->State());

printf("Number of messages: %d\n", $pop->Count()) if &VERBOSE;
for (my $id = 1; $id <= $pop->Count(); $id++) {
    my $text;
    my $path_id;
    my $attachment_dir;
    my $path;
    my $file;
    my $stripper;
    my @attachments;
    my $datetime;

    $text = $pop->Retrieve($id);
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

print("Done!\n");

$pop->Close();
