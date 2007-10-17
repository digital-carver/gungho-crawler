use strict;
use Test::More;

BEGIN
{
    my $ok = 1;

    foreach my $module qw(MIME::Base64 URI HTTP::Status HTTP::Headers::Util) {
        next unless $module;
        eval "use $module";
        if ($@) {
            plan(skip_all => "$module not installed: $@");
            $ok = 0;
        }
    }

    if ($ok) {
        plan(tests => 3);
        use_ok("Gungho");
    }
}

Gungho->setup({ 
    components => [
        'Authentication::Basic'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'authenticate');
can_ok('Gungho', 'check_authentication_challenge');

1;