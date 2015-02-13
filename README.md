# NAME

LWPx::UserAgent::Cached - Subclass of LWP::UserAgent that caches HTTP GET requests

# VERSION

version 0.004

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
[WWW::Mechanize::Cached](https://metacpan.org/pod/WWW::Mechanize::Cached) but without
inheriting from [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize);
instead it is just a direct subclass of
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent).

# ATTRIBUTES

## cache

Settable at construction, defaults to using
[CHI::Driver::RawMemory](https://metacpan.org/pod/CHI::Driver::RawMemory) with an
instance-specific hash datastore and a namespace with the current package name.
You can use your own caching object here as long as it has `get` and
`set` methods.

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

# SEE ALSO

- [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)

    Parent of this class.

- [WWW::Mechanize::Cached](https://metacpan.org/pod/WWW::Mechanize::Cached)

    Inspiration for this class.

# HANDLERS

This module works by adding `request_send` and `response_done`
[handlers](https://metacpan.org/pod/LWP::UserAgent#Handlers) method that run on successful
HTTP `GET` requests. If you need to modify or remove these handlers you may
use [LWP::UserAgent's `handlers`](https://metacpan.org/pod/LWP::UserAgent#Handlers) method.

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc LWPx::UserAgent::Cached

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [http://metacpan.org/release/LWPx-UserAgent-Cached](http://metacpan.org/release/LWPx-UserAgent-Cached)

- Search CPAN

    The default CPAN search engine, useful to view POD in HTML format.

    [http://search.cpan.org/dist/LWPx-UserAgent-Cached](http://search.cpan.org/dist/LWPx-UserAgent-Cached)

- AnnoCPAN

    The AnnoCPAN is a website that allows community annotations of Perl module documentation.

    [http://annocpan.org/dist/LWPx-UserAgent-Cached](http://annocpan.org/dist/LWPx-UserAgent-Cached)

- CPAN Ratings

    The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

    [http://cpanratings.perl.org/d/LWPx-UserAgent-Cached](http://cpanratings.perl.org/d/LWPx-UserAgent-Cached)

- CPAN Forum

    The CPAN Forum is a web forum for discussing Perl modules.

    [http://cpanforum.com/dist/LWPx-UserAgent-Cached](http://cpanforum.com/dist/LWPx-UserAgent-Cached)

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/LWPx-UserAgent-Cached](http://cpants.cpanauthors.org/dist/LWPx-UserAgent-Cached)

- CPAN Testers

    The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

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

This software is copyright (c) 2015 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
