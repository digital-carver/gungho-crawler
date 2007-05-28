use strict;
use Test::More tests => 2;

use Gungho::Inline;

Gungho::Inline->run(
    {
        block_private_ip_address => 1,
    },
    {
        provider => sub {
            my($p, $c) = @_;
            $p->add_request(Gungho::Request->new(GET => $_)) for qw(
                http://localhost
            )
        },
        handler => sub {
            my ($p, $c, $req, $res) = @_;
            is($res->code, 500, 'HTTP status is 500');
            like($res->content, do {
                my $str = "Failed to resolve host " . $req->uri->host;
                qr($str);
            }, 'Error message is correct');
        }
    }
);
