# NAME

LWPx::UserAgent::Cached - Subclass of LWP::UserAgent that caches HTTP GET requests

# VERSION

version 0.011

# SYNOPSIS

    use LWPx::UserAgent::Cached;
    use CHI;

    my $ua = LWPx::UserAgent::Cached->new(
        cache => CHI->new(
            driver => 'File', root_dir => '/tmp/cache', expires_in => '1d',
        ),
    );
    $ua->get('http://www.perl.org/');

# DESCRIPTION

This module borrows the caching logic from
[`WWW::Mechanize::Cached`](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ACached) but
without inheriting from
[`WWW::Mechanize`](https://metacpan.org/pod/WWW%3A%3AMechanize); instead it is just
a direct subclass of
[`LWP::UserAgent`](https://metacpan.org/pod/LWP%3A%3AUserAgent).

## HTTP/1.1 cache operation

Full HTTP/1.1 cache compliance is a work in progress. As of version 0.006 we
have limited support for HTTP/1.1 `ETag`/`If-None-Match` headers, as well as
`no-cache` and `no-store` `Cache-Control` directives (both on request and
response) and the `Pragma: no-cache` request header.

# ATTRIBUTES

## cache

Settable at construction, defaults to using
[`CHI::Driver::RawMemory`](https://metacpan.org/pod/CHI%3A%3ADriver%3A%3ARawMemory) with
an instance-specific hash datastore and a namespace with the current
package name. You can use your own caching object here as long as it has
`get` and `set` methods.

## is\_cached

Read-only accessor that indicates if the current request is cached or not.

## cache\_undef\_content\_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the HTTP `Content-Length` header is missing or
undefined. Defaults to false.

## cache\_zero\_content\_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the HTTP `Content-Length` header is zero. Defaults to
false.

## cache\_mismatch\_content\_length

Settable at construction or anytime thereafter, indicates whether we should
cache content even if the length of the data does not match the HTTP
`Content-Length` header. Defaults to true.

## ref\_in\_cache\_key

Settable at construction or anytime thereafter, indicates whether we should
store the HTTP referrer in the cache key. Defaults to false.

## positive\_cache

Settable at construction or anytime thereafter, indicates whether we should
only cache positive responses (HTTP response codes from `200` to `300`
inclusive) or cache everything. Defaults to true.

## ignore\_headers

Settable at construction or anytime thereafter, indicates whether we should
ignore `Cache-Control: no-cache`, `Cache-Control: no-store`, and
`Pragma: no-cache` HTTP headers when deciding whether to cache a response.
Defaults to false.

**Important note:** This option is potentially dangerous, as it ignores the
explicit instructions from the server and thus can lead to returning stale
content.

# REQUIRES

- [CHI](https://metacpan.org/pod/CHI)
- [HTTP::Status](https://metacpan.org/pod/HTTP%3A%3AStatus)
- [Moo](https://metacpan.org/pod/Moo)
- [Types::Standard](https://metacpan.org/pod/Types%3A%3AStandard)
- [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean)

# SEE ALSO

- [`LWP::UserAgent`](https://metacpan.org/pod/LWP%3A%3AUserAgent)

    Parent of this class.

- [`WWW::Mechanize::Cached`](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ACached)

    Inspiration for this class.

# HANDLERS

This module works by adding `request_send`, `response_done` and
`response_header` [handlers](https://metacpan.org/pod/LWP%3A%3AUserAgent#Handlers)
that run on successful HTTP `GET` requests.
If you need to modify or remove these handlers you may use LWP::UserAgent's
[handler-related methods](https://metacpan.org/pod/LWP%3A%3AUserAgent#Handlers).

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc LWPx::UserAgent::Cached

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/LWPx-UserAgent-Cached](https://metacpan.org/release/LWPx-UserAgent-Cached)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/LWPx-UserAgent-Cached](http://cpants.cpanauthors.org/dist/LWPx-UserAgent-Cached)

- CPAN Testers

    The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/L/LWPx-UserAgent-Cached](http://www.cpantesters.org/distro/L/LWPx-UserAgent-Cached)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=LWPx-UserAgent-Cached](http://matrix.cpantesters.org/?dist=LWPx-UserAgent-Cached)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=LWPx::UserAgent::Cached](http://deps.cpantesters.org/?module=LWPx::UserAgent::Cached)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
[https://github.com/mjgardner/LWPx-UserAgent-Cached/issues](https://github.com/mjgardner/LWPx-UserAgent-Cached/issues).
You will be automatically notified of any progress on the
request by the system.

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/mjgardner/LWPx-UserAgent-Cached](https://github.com/mjgardner/LWPx-UserAgent-Cached)

    git clone git://github.com/mjgardner/LWPx-UserAgent-Cached.git

# AUTHOR

Mark Gardner <mjgardner@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
