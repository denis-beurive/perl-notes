package SFile;
use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);

# See http://search.cpan.org/~toddr/Exporter-5.72/lib/Exporter.pm#Good_Practices
our @EXPORT = qw();
our %EXPORT_TAGS = (all => \@EXPORT);
our @EXPORT_OK = @EXPORT;

# Create a new File.
# @param $inPath Path to the file.
# @param $inVerbose Verbose flag (optional, default is 0).
#        - if 0: verbose mode is disabled.
#        - if 1: verbose mode is enabled.
#        - if not defined: verbose mode is disabled.

sub new {
    my ($inClassName, $inPath, $inVerbose) = @_;
    my $self = {
        path     => $inPath,
        verbose  => defined($inVerbose) ? $inVerbose : 0,
        error    => undef};

    bless $self, $inClassName;
    return $self;
}

# Write data into a file.
# @param $inData The data to write.
# @param $inBinary Flag that tells whether the data is a binary or not.
#        - 0: this is not binary.
#        - 1: this is binary.
# @return Upon successful completion, the function returns the value TRUE.
#         Otherwise, it returns the value FALSE.

sub write {
    my ($self, $inData, $inBinary) = @_;
    if (! defined($inData)) {
        $self->{error} = sprintf('no data to print into file "%s"', $self->{path});
        return(0);
    }

    my $fd = undef;
    if (! open($fd, '>', $self->{path})) {
        $self->{error} = sprintf('cannot open the file "%s" for writing (binary mode: %s): %s', $self->{path}, $inBinary ? 'yes' : 'no', $!);
        return(0);
    }
    binmode($fd) if (0 != $inBinary);
    print $fd $inData;
    close($fd);
    return(1);
}

sub writeBinary {
    my ($self, $inData) = @_;
    return($self->write($inData, 1));
}

sub writeText {
    my ($self, $inData) = @_;
    return($self->write($inData, 0));
}

# Read data from a file.
# @param $inBinary Flag that tells whether the data to read is a binary or not.
#        - 0: this is not binary.
#        - 1: this is binary.
# @return Upon successful completion, the function returns the data read from the file.
#         Otherwise, it returns the value undef.

sub read {
    my ($self, $inBinary) = @_;
    my $fd = undef;

    if (! open($fd, '<', $self->{path})) {
        $self->{error} = sprintf('cannot open the file "%s" for reading (binary node: %s): %s', $self->{path}, $inBinary ? 'yes' : 'no', $!);
        return(undef);
    }
    my $content;
    if (0 != $inBinary) {
        binmode($fd);
        while (1) {
            my $read_count = read $fd, $content, 100, length($content);
            if (!defined($read_count)) {
                $self->{error} = sprintf("an error occurred while reading the binary file: %s", $!);
                close($fd);
                return(undef);
            }
            last if 0 == $read_count;
        }
    } else {
        $content = do { local $/ = undef; <$fd> };
    }

    close($fd);
    return($content);
}

# Return the content of the file, assuming it contains only text.
# @return Upon successful completion, the method returns a string that represents the content of
#         the file. Otherwise, it returns the value undef.

sub readText {
    my ($self) = @_;
    return($self->read(0));
}

# Return the content of the file, assuming it contains binary.
# @return Upon successful completion, the method returns a binary data that represents the content of
#         the file. Otherwise, it returns the value undef.

sub readBinary {
    my ($self) = @_;
    return($self->read(1));
}

# Compare the content of this file against a given text.
# @param $text_to_compare_against The text against which the comparison is made.
# @return Upon successful completion, the method may return one of the following values:
#         - 1: the content of this file differs from the given text.
#         - 0: the content of this file is identical to the given text.
#         Otherwise, the method returns the value -1.

sub diff_text {
    my ($self, $text_to_compare_against) = @_;
    my $file_content = $self->readText();
    if (! defined($file_content)) {
        $self->{error} = sprintf("cannot compare the content of the file \"%s\" with the given text! %s",
            $self->{path}, ucfirst($self->{error}));
        return(-1);
    }

    return $file_content ne $text_to_compare_against ? 1 : 0;
}

# Rename this file:
# - the new name of the file is the old one appended by the date of the day (in the form: "-YYYYMMDD.HHMMSS").
# - the new file is located in the same directory than the original one.
# @return Upon successful completion, the function returns the path to the new file.
#         Otherwise, the function returns the value undef.

sub rename_with_timestamp {
    my ($self) = @_;
    my $now_string = strftime "%Y%m%d.%H%M%S", localtime;
    my $new_path = sprintf("%s-%s", $self->{path}, $now_string);
    unless (rename($self->{path}, $new_path)) {
        $self->{error} = sprintf("cannot rename the file \"%s\" into \"%s\": %s", $self->{path}, $new_path, $!);
        return(undef);
    }
    return($new_path);
}

# Test whether an error occurred during the last operation.
# @return If an error occurred, then the method returns the value TRUE.
#         Otherwise, it returns the value FALSE.

sub is_error {
    my ($self) = @_;
    return(defined($self->{error}));
}

# Return the last error.
# @return The method returns a message that describes the last error.

sub lastError {
    my ($self) = @_;
    return($self->{error});
}

1;