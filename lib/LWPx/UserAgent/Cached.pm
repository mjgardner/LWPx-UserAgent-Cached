package LWPx::UserAgent::Cached;

# ABSTRACT: Subclass of LWP::UserAgent that caches HTTP GET requests

use strict;
use warnings;
use utf8;
our $VERSION = '0.009';

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
L<C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached> but
without inheriting from
L<C<WWW::Mechanize>|WWW::Mechanize>; instead it is just
a direct subclass of
L<C<LWP::UserAgent>|LWP::UserAgent>.

=head2 HTTP/1.1 cache operation

Full HTTP/1.1 cache compliance is a work in progress. As of version 0.006 we
have limited support for HTTP/1.1 C<ETag>/C<If-None-Match> headers, as well as
C<no-cache> and C<no-store> C<Cache-Control> directives (both on request and
response) and the C<Pragma: no-cache> request header.

=head1 SEE ALSO

=over

=item L<C<LWP::UserAgent>|LWP::UserAgent>

Parent of this class.

=item L<C<WWW::Mechanize::Cached>|WWW::Mechanize::Cached>

Inspiration for this class.

=back

=cut

use CHI;
use HTTP::Status qw(HTTP_OK HTTP_MOVED_PERMANENTLY HTTP_NOT_MODIFIED);
use List::Util 1.33 'any';
use Moo 1.004005;
use Types::Standard qw(Bool HasMethods HashRef InstanceOf Maybe);
use namespace::clean;
extends 'LWP::UserAgent';

=attr cache

Settable at construction, defaults to using
L<C<CHI::Driver::RawMemory>|CHI::Driver::RawMemory> with
an instance-specific hash datastore and a namespace with the current
package name. You can use your own caching object here as long as it has
C<get> and C<set> methods.

=cut

has cache => (
    is      => 'lazy',
    isa     => HasMethods [qw(get set)],
    default => sub {
        CHI->new(
            serializer => 'Sereal',
            driver     => 'RawMemory',
            datastore  => $_[0]->_cache_datastore,
            namespace  => __PACKAGE__,
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

=head1 HANDLERS

This module works by adding C<request_send>, C<response_done> and
C<response_header> L<handlers|LWP::UserAgent/Handlers>
that run on successful HTTP C<GET> requests.
If you need to modify or remove these handlers you may use LWP::UserAgent's
L<handler-related methods|LWP::UserAgent/Handlers>.

=for Pod::Coverage BUILD

=cut

sub BUILD {
    my $self = shift;

    $self->add_handler( request_send => \&_get_cache, ( m_method => 'GET' ) );
    $self->add_handler(
        response_done => \&_set_cache,
        ( m_method => 'GET', m_code => 2 ),
    );
    $self->add_handler(
        response_header => \&_get_not_modified,
        ( m_method => 'GET', m_code => HTTP_NOT_MODIFIED ),
    );

    return;
}

# load from cache on each GET request
sub _get_cache {
    my ( $request, $self ) = @_;
    $self->_set_is_cached(0);

    my $clone = $request->clone;
    if ( not $self->ref_in_cache_key ) { $clone->header( Referer => undef ) }
    return if $self->_no_cache_header_directives($request);

    return if not my $response = $self->cache->get( $clone->as_string );
    return
        if $response->code < HTTP_OK
        or $response->code > HTTP_MOVED_PERMANENTLY;

    if ( $response->header('etag') ) {
        $clone->header( if_none_match => $response->header('etag') );
        $response = $self->request($clone);
    }
    return if $self->_no_cache_header_directives($response);

    $self->_set_is_cached(1);
    return $response;
}

sub _get_not_modified {
    my ( $response, $self ) = @_;
    $self->_set_is_cached(0);

    my $request = $response->request->clone;
    $request->remove_header(qw(if_modified_since if_none_match));

    my $cached_response = $self->cache->get( $request->as_string );
    $response->content( $cached_response->decoded_content );

    $self->_set_is_cached(1);
    return;
}

# save to cache after successful GET
sub _set_cache {
    my ( $response, $self ) = @_;
    return if not $response;

    if (not($response->header('client-transfer-encoding')
            and any { 'chunked' eq $_ }
            $response->header('client-transfer-encoding')
        )
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

    for my $message ( $response, $response->request ) {
        return if $self->_no_cache_header_directives($message);
    }

    $response->decode;
    $response->remove_content_headers;
    $self->cache->set( $response->request->as_string => $response );
    return;
}

sub _no_cache_header_directives {
    my ( $self, $message ) = @_;
    for my $header_name (qw(pragma cache_control)) {
        if ( my @directives = $message->header($header_name) ) {
            return 1 if any {/\A no- (?: cache | store ) /xms} @directives;
        }
    }
    return;
}

=for Pod::Coverage FOREIGNBUILDARGS

=cut

## no critic (Subroutines::RequireArgUnpacking)
sub FOREIGNBUILDARGS {
    shift;
    return 'HASH' eq ref $_[0] ? %{ $_[0] } : @_;
}

1;
