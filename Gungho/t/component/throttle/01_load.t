use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } else {
        eval "use Data::Throttler";
        if ($@) {
            plan(skip_all => "Data::Throttler not installed: $@");
        } else {
            plan(tests => 2);
            use_ok("Gungho");
        }
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