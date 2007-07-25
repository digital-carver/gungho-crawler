package GunghoTest::PrivateDNS;
use strict;
use warnings;
use Gungho::Inline;
use Test::More;

sub run
{
    my $class = shift;
    my %opts  = @_;

    my $engine = $opts{engine} || 'POE';

    Gungho::Inline->run(
        {
            engine => {
                module => $engine,
            },
            block_private_ip_address => 1,
        },
        {
            provider => sub {
                my($p, $c) = @_;
                $p->add_request(Gungho::Request->new(GET => $_)) for qw(
                    http://10.0.0.1
                    http://10.255.255.254
                    http://127.0.0.1
                    http://127.255.255.254
                    http://172.16.0.1
                    http://172.31.255.254
                    http://192.168.0.1
                    http://192.168.255.254
                    http://localhost
                    http://224.0.0.1
                )
            },
            handler => sub {
                my ($p, $c, $req, $res) = @_;
                is($res->code, 500, 'HTTP status is 500');
                # should return blocked error for 127.0.0.1 and localhost, but not for 224.0.0.1 (connect(2) will return a protocol-family error)
                my $expected = "Access blocked for hostname with private address: " . $req->uri->host;
                if ($req->uri->host !~ /^224\./) {
                    like($res->content, qr($expected), 'Error message is correct');
                } else {
                    unlike($res->content, qr($expected), 'Error message is correct');
                }
            }
        }
    );
}

1;
