package Mailjet;
use strict;
use warnings FATAL => 'all';
use LWP::UserAgent ();
use HTTP::Request::Common;
use URI;
use JSON qw(decode_json);
use base qw(Exporter);

use constant DEFAULT_TIMEOUT => 60;

use constant MJ_URL_GET_MESSAGES => 'https://api.mailjet.com/v3/REST/message';
use constant MJ_URL_GET_CONTACT => 'https://api.mailjet.com/v3/REST/contact';

use constant MJ_MESSAGE_STATUS_PROCESSED => 0;
use constant MJ_MESSAGE_STATUS_QUEUED => 1;
use constant MJ_MESSAGE_STATUS_SENT => 2;
use constant MJ_MESSAGE_STATUS_OPENED => 3;
use constant MJ_MESSAGE_STATUS_CLICKED => 4;
use constant MJ_MESSAGE_STATUS_BOUNCED => 5;
use constant MJ_MESSAGE_STATUS_SPAM => 6;
use constant MJ_MESSAGE_STATUS_UNSUB => 7;
use constant MJ_MESSAGE_STATUS_BLOCKED => 8;
use constant MJ_MESSAGE_STATUS_SOFT_BOUNCE => 9;
use constant MJ_MESSAGE_STATUS_HARD_BOUNCE => 10;
use constant MJ_MESSAGE_STATUS_DEFERRED => 11;

sub new {
    my ($inClassName, $inApiPublicKey, $inApiPrivateKey, %inOptions) = @_;
    my $verbose = exists($inOptions{verbose}) ? ($inOptions{verbose} ? 1 : 0) : 0;
    my $timeout = exists($inOptions{timeout}) ? $inOptions{timeout} : &DEFAULT_TIMEOUT;
    my $self = {
        public_key  => $inApiPublicKey,
        private_key => $inApiPrivateKey,
        verbose     => $verbose,
        timeout     => $timeout,
        error       => undef,
        response    => undef
    };
    bless $self, $inClassName;
    return $self;
}

sub error {
    my ($self)  = @_;
    return($self->{error});
}

sub response {
    my ($self) = @_;
    return($self->{response});
}

sub reset {
    my ($self)  = @_;
    $self->{error} = undef;
    $self->{response} = undef;
}

sub enable_verbose {
    my ($self)  = @_;
    $self->{verbose} = 1;
}

sub disable_verbose {
    my ($self)  = @_;
    $self->{verbose} = 0;
}

sub dump_request {
    my (#@type HTTP::Request
        $request) = @_;
    #@type HTTP::Headers
    my $headers = $request->headers;
    my %h = $headers->flatten();
    printf("Url: %s\n", $request->url());
    printf("Method: %s\n", $request->method());
    printf("Headers:\n");
    foreach my $name (keys %h) {
        printf("  %s: %s\n", $name, $h{$name});
    }
}

# @param Parameters can be:
# - ShowSubject (default value: 1 - true)
# - ShowContactAlt (default value: 1 - true)
# - timeout (default value: the default timeout set during the object instantiation)
# - Offset
# - Limit
# - from_date
# - to_date
# @return On success: a reference to a HASH that represents the response.
#         In failure: undef.

sub messages {
    my ($self, %params)  = @_;
     #@type URI
    my $url;
    #@type LWP::UserAgent
    my $user_agent;
    #@type HTTP::Response
    my $response;
    #@type HTTP::Request
    my $request;
    my $show_subject = exists($params{ShowSubject}) ? ($params{ShowSubject} ? 1 : 0) : 1;
    my $show_contact_alt = exists($params{ShowContactAlt}) ? ($params{ShowContactAlt} ? 1 : 0) : 1;
    my $timeout = exists($params{timeout}) ? $params{timeout} : $self->{timeout};

    $self->reset();
    $url = URI->new(MJ_URL_GET_MESSAGES);
    $url->query_form($url->query_form, 'ShowSubject', $show_subject ? 'true' : 'false');
    $url->query_form($url->query_form, 'ShowContactAlt', $show_contact_alt ? 'true' : 'false');
    $url->query_form($url->query_form, 'Limit', $params{'Limit'}) if exists($params{'Limit'});
    $url->query_form($url->query_form, 'Offset', $params{'Offset'}) if exists($params{'Offset'});
    $url->query_form($url->query_form, 'from_date', $params{'from_date'}) if exists($params{'from_date'});
    $url->query_form($url->query_form, 'to_date', $params{'to_date'}) if exists($params{'to_date'});

    # See: https://perlmaven.com/basic-authentication-with-lwp-useragent-and-http-request-common
    $request = GET $url;
    $request->authorization_basic($self->{public_key}, $self->{private_key});
    $user_agent = LWP::UserAgent->new(timeout => $timeout);
    $response = $user_agent->request($request);
    dump_request($request) if ($self->{verbose});

    if ($response->is_success) {
        local $@;
        my $r;
        $self->{response} = $response->content;
        eval { $r = decode_json($response->content) };
        if ($@ ne '') {
            $self->{error} = sprintf('malformed response (not JSON): %s', $@);
            return(undef);
        }
        if (exists($r->{ErrorMessage})) {
            $self->{error} = $r->{ErrorMessage};
            return(undef);
        }
        return($r);
    }
    $self->{error} = 'unexpected error';
    return(undef);
}

use constant MJ_APIKEY_PUBLIC => 'your usrname';
use constant MJ_APIKEY_PRIVATE => 'your password';

my $mj = Mailjet->new(&MJ_APIKEY_PUBLIC, &MJ_APIKEY_PRIVATE, verbose => 1);
$mj->messages(Offset => 0, Limit => 5);

1;