#!/usr/bin/env perl

use Modern::Perl '2011';
use English '-no_match_vars';
use Const::Fast;
use HTTP::Status qw(HTTP_OK HTTP_NOT_MODIFIED);
use Test::More tests => 1;
use Test::Fake::HTTPD;
use LWPx::UserAgent::Cached;

my $httpd = Test::Fake::HTTPD->new( $PERLDB ? ( timeout => undef ) : () );
$httpd->run(
    sub {
        [   HTTP_OK,
            [   'Content-Type'  => 'text/plain',
                'Cache-Control' => 'no-store',
            ],
            ['Hello world!'],
        ];
    },
);

my $user_agent = LWPx::UserAgent::Cached->new;
note "Response:\n" => $user_agent->get( $httpd->endpoint )->dump;

my $response = $user_agent->get( $httpd->endpoint );
note "Response:\n" => $response->dump;
is( $user_agent->is_cached, 0, 'still uncached' );
