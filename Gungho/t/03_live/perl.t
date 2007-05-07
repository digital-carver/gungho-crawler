use strict;
use Test::More;

BEGIN
{
    if (! $ENV{GUNGHO_TEST_LIVE}) {
        plan skip_all => "Enable GUNGHO_TEST_LIVE to run these tests";
    } else {
        plan tests => 3;
        use_ok "Gungho::Inline";
    }
}

Gungho::Inline->run({
    provider => sub {
        my($c, $p) = @_;
        $p->add_request(Gungho::Request->new(GET => $_)) for qw(
            http://www.perl.com
            http://search.cpan.org
        )
    },
    handler => sub {
        my($req, $res) = @_;

        ok( $res->is_success, $req->uri . " is success");
    },
});