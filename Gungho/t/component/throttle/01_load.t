use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } elsif ( ! eval "use Data::Throttler" || $@) {
        plan(skip_all => "Data::Throttler not installed: $@");
    } else {
        plan(tests => 10);
        use_ok("Gungho");
    }
}

eval {
    Gungho->setup({ 
        components => [
            'Throttle::Domain'
        ],
        provider => {
            module => 'Simple'
        }
    });
};
ok(!$@);