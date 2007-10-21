use strict;
use Test::More (tests => 2);;

BEGIN
{
    use_ok("Gungho");
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