use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } elsif ( ! eval "use Cache::Memory" || $@) {
        plan(skip_all => "Cache::Memory not installed: $@");
    } else {
        plan(tests => 10);
        use_ok("Gungho");
    }
}

Gungho->setup({ 
    components => [
        'Cache'
    ],
    cache => {
        default_backend => 'basic',
        backends => {
            basic => {
                class => '+Cache::Memory',
                namespace => 'basic',
            },
            foo => {
                class => '+Cache::Memory',
                namespace => 'foo'
            },
        }
    },
    provider => {
        module => 'Simple'
    }
});

my $cache = Gungho->cache('basic');
ok($cache, "cache defined");
isa_ok($cache, "Cache::Memory");
is($cache->namespace, 'basic');

$cache = Gungho->cache('foo');
ok($cache, "cache defined");
isa_ok($cache, "Cache::Memory");
is($cache->namespace, 'foo');

$cache = Gungho->cache();
ok($cache, "cache defined");
isa_ok($cache, "Cache::Memory");
is($cache->namespace, 'basic');

1;
