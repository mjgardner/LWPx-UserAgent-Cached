package LWPx::UserAgent::Cached;

# ABSTRACT: Subclass of LWP::UserAgent that caches HTTP GET requests

use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use utf8;

## no critic (Bangs::ProhibitCommentedOutCode)

=head1 SYNOPSIS

    use LWPx::UserAgent::Cached;
    use CHI;

    my $ua = LWPx::UserAgent::Cached->new(
        cache => CHI->new(
            driver => 'File', root_dir => '/tmp/cache', expires_in => '1d',
        ),
    );
    $ua->get('http://www.perl.org/');

=head1 DESCRIPTION

This module borrows the caching logic from
L<WWW::Mechanize::Cached|WWW::Mechanize::Cached> but without
inheriting from L<WWW::Mechanize|WWW::Mechanize>;
instead it is just a direct subclass of
L<LWP::UserAgent|LWP::UserAgent>.
As of version 0.005 it has limited support for HTTP/1.1
C<ETag>/C<If-None-Match> cache control headers.

=head1 SEE ALSO

=over

=item L<LWP::UserAgent|LWP::UserAgent>

Parent of this class.

=item L<WWW::Mechanize::Cached|WWW::Mechanize::Cached>

Inspiration for this class.

=back

=cut

use CHI;
use HTTP::Status qw(HTTP_OK HTTP_MOVED_PERMANENTLY HTTP_NOT_MODIFIED);

# work around RT#43310
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
use List::Util 1.33 'any';
use Sereal qw(sereal_encode_with_object sereal_decode_with_object);
use Moo 1.004005;
use Sub::Quote 1.005000 'qsub';
use Types::Standard qw(Bool HasMethods HashRef InstanceOf Maybe);
use namespace::clean;
extends 'LWP::UserAgent';

=attr cache

Settable at construction, defaults to using
L<CHI::Driver::RawMemory|CHI::Driver::RawMemory> with an
instance-specific hash datastore and a namespace with the current package name.
You can use your own caching object here as long as it has C<get> and
C<set> methods.

=cut

has cache => (
    is      => 'lazy',
    isa     => HasMethods [qw(get set)],
    default => sub {
        CHI->new(
            driver    => 'RawMemory',
            datastore => $_[0]->_cache_datastore,
            namespace => __PACKAGE__,
        );
    },
);
has _cache_datastore =>
    ( is => 'lazy', isa => HashRef, default => sub { {} } );

=attr is_cached

Read-only accessor that indicates if the current request is cached or not.

=cut

has is_cached =>
    ( is => 'rwp', isa => Maybe [Bool], init_arg => undef, default => undef );

=attr cache_undef_content_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the HTTP C<Content-Length> header is missing or
undefined. Defaults to false.

=cut

has cache_undef_content_length => ( is => 'rw', isa => Bool, default => 0 );

=attr cache_zero_content_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the HTTP C<Content-Length> header is zero. Defaults to
false.

=cut

has cache_zero_content_length => ( is => 'rw', isa => Bool, default => 0 );

=attr cache_mismatch_content_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the length of the data does not match the HTTP
C<Content-Length> header. Defaults to true.

=cut

has cache_mismatch_content_length =>
    ( is => 'rw', isa => Bool, default => 1 );

=attr ref_in_cache_key

Settable at construction or anytime thereafter, indicates whether we should
store the HTTP referrer in the cache key. Defaults to false.

=cut

has ref_in_cache_key => ( is => 'rw', isa => Bool, default => 0 );

=attr positive_cache

Settable at construction or anytime thereafter, indicates whether we should
only cache positive responses (HTTP response codes from C<200> to C<300>
inclusive) or cache everything. Defaults to true.

=cut

has positive_cache => ( is => 'rw', isa => Bool, default => 1 );

for (qw(Encoder Decoder)) {
    has "_\l$_" => (
        is      => 'lazy',
        isa     => InstanceOf ["Sereal::$_"],
        default => qsub "Sereal::$_->new",
    );
}

=head1 HANDLERS

This module works by adding C<request_send> and C<response_done>
L<handlers|LWP::UserAgent/Handlers> method that run on successful
HTTP C<GET> requests. If you need to modify or remove these handlers you may
use L<LWP::UserAgent's C<handlers>|LWP::UserAgent/Handlers> method.

=for Pod::Coverage BUILD

=cut

sub BUILD {
    my $self = shift;

    $self->add_handler(
        request_send => $self->_closure_get_cache,
        ( m_method => 'GET' ),
    );
    $self->add_handler(
        response_done => $self->_closure_set_cache,
        ( m_method => 'GET', m_code => 2 ),
    );
    $self->add_handler(
        response_done => $self->_closure_not_modified,
        ( m_code => HTTP_NOT_MODIFIED ),
    );

    return;
}

# load from cache on each GET request
sub _closure_get_cache {
    my $self = shift;
    return sub {
        my ($request) = @_;
        $self->_set_is_cached(0);
        if ( not $self->ref_in_cache_key ) {
            my $clone = $request->clone;
            $clone->header( Referer => undef );
            $request = $clone->as_string;
        }

        my $response = $self->cache->get("$request");
        $response &&= sereal_decode_with_object( $self->_decoder, $response );
        return if not $response;

        my $etag;
        if ( $etag = $response->header('etag') ) {
            $_[0]->header( if_none_match => $etag );
        }

        return
               if $etag
            or $response->code < HTTP_OK
            or $response->code > HTTP_MOVED_PERMANENTLY;
        $self->_set_is_cached(1);
        return $response;
    };
}

# save to cache after successful GET
sub _closure_set_cache {
    my $self = shift;
    return sub {
        return if not my $response = shift;

        if (not( $response->header('client-transfer-encoding')
                and 'ARRAY' eq
                ref $response->header('client-transfer-encoding')
                and any { 'chunked' eq $_ }
                @{ $response->header('client-transfer-encoding') } )
            )
        {
            for ( $response->header('size') ) {
                return
                    if not defined and $self->cache_undef_content_length;
                return
                    if 0 == $_
                    and not $self->cache_zero_content_length;
                return
                    if $_ != length $response->content
                    and not $self->cache_mismatch_content_length;
            }
        }

        $response->decode;
        $self->cache->set( $response->request->as_string =>
                sereal_encode_with_object( $self->_encoder, $response ) );
        return;
    };
}

# handle HTTP 304 response, possibly from cache
sub _closure_not_modified {
    my $self = shift;
    return sub {
        my $request = $_[0]->request;
        $self->_set_is_cached(0);

        $request->header( if_none_match => undef );
        my $response = $self->cache->get( $request->as_string );
        $response &&= sereal_decode_with_object( $self->_decoder, $response );
        if ( not $response ) {
            $request->header( if_none_match => undef );
            $response = $self->request($request);
        }

        $self->_set_is_cached(1);
        $_[0] = $response;
    };
}

=for Pod::Coverage FOREIGNBUILDARGS

=cut

## no critic (Subroutines::RequireArgUnpacking)
sub FOREIGNBUILDARGS {
    shift;
    return 'HASH' eq ref $_[0] ? %{ $_[0] } : @_;
}

1;
