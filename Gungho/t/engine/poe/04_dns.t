use strict;
use Test::More;
use lib('t/lib');
use GunghoTest;
use GunghoTest::PrivateDNS;

BEGIN
{
    GunghoTest->plan_or_skip(
        requires    => "POE",
        test_count  => 18
    );
}

GunghoTest::PrivateDNS->run(engine => "POE");
