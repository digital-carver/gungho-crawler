use strict;
use Test::More;

BEGIN
{
    eval "use HTML::RobotsMETA";
    if ($@) {
        plan(skip_all => "HTML::RobotsMETA not installed: $@");
    } else {
        plan(tests => 4);
        use_ok("Gungho");
    }
}

Gungho->setup({ 
    components => [
        'RobotsMETA'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'robots_meta');
ok(Gungho->robots_meta);
isa_ok(Gungho->robots_meta, "HTML::RobotsMETA");

1;