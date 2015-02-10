
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/LWPx/UserAgent/Cached.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/004-cached.t',
    't/005-custom-cache.t',
    't/006-cached-chi.t',
    't/TestCache.pm',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/cache_key.t',
    't/is_cached.t',
    't/pages/1.html',
    't/pages/10.html',
    't/pages/2.html',
    't/pages/3.html',
    't/pages/4.html',
    't/pages/5.html',
    't/pages/6.html',
    't/pages/7.html',
    't/pages/8.html',
    't/pages/9.html',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-localbrew-perl-5.12.5-TEST.t',
    't/release-localbrew-perl-latest-TEST.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
