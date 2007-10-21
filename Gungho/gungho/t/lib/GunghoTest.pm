package GunghoTest;
use strict;
use Test::More();

sub plan_or_skip
{
    my $class = shift;
    my %args  = @_;

    if ($args{requires}) {
        eval "use $args{requires}";
        if ($@) {
            Test::More::plan(skip_all => "$args{requires} not available");
            return;
        }
    }

    Test::More::plan(tests => $args{test_count});
    return 1;
}

1;
