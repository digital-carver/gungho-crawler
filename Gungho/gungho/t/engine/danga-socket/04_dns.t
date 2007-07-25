use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;
use GunghoTest::PrivateDNS;

BEGIN
{
    GunghoTest->plan_or_skip(
        requires    => "Danga::Socket",
        test_count  => 20
    );
}

GunghoTest::PrivateDNS->run(engine => 'Danga::Socket');
