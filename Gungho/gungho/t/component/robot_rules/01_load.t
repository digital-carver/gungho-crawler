use strict;
use Test::More;

BEGIN
{
    my $ok = 1;

    foreach my $module qw(URI WWW::RobotRules::Parser DB_File) {
        next unless $module;
        eval "use $module";
        if ($@) {
            plan(skip_all => "$module not installed: $@");
            $ok = 0;
        }
    }

    if ($ok) {
        plan(tests => 7);
        use_ok("Gungho");
    }
}

Gungho->setup({ 
    components => [
        'RobotRules'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'pending_robots_txt');
can_ok('Gungho', 'robot_rules_parser');
can_ok('Gungho', 'robot_rules_storage');
can_ok('Gungho', 'allowed');
can_ok('Gungho', 'handle_response');

isa_ok(Gungho->robot_rules_parser, "WWW::RobotRules::Parser");

1;