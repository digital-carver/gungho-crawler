# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine;
use strict;
use warnings;
use base qw(Gungho::Base);
use HTTP::Status qw(status_message);
use Regexp::Common qw(net);

sub run {}

sub handle_dns_response
{
    my ($self, $c, $request, $dns_response) = @_;

    if ($dns_response) {
        foreach my $answer ($dns_response->answer) {
            next if $answer->type ne 'A';
            my $host = $request->uri->host;
            # Check if we are filtering private addresses
            if ($c->block_private_ip_address && $self->_address_is_private($answer->address)) {
                $c->log->info("[DNS] Hostname $host resolved to a private address: " . $answer->address);
                last;
            }

            $request->push_header(Host => $host);
            $request->notes(original_host => $host);
            $request->uri->host($answer->address);
            eval {
                $c->send_request($request);
            };
            if (my $e = $@) {
                if ($e->isa('Gungho::Exception::RequestThrottled')) {
                    # This request was throttled. Attempt to do it later
                    $c->provider->pushback_request($c, $request);
                } else {
                    die $e;
                }
            }

            return;
        }
    }

    $c->handle_response($request, $self->_http_error(500, "Failed to resolve host " . $request->uri->host, $request)),
}

sub _address_is_private
{
    my ($self, $address) = @_;

    if ($address eq '127.0.0.1') {
        return 1;
    } elsif ($address =~ /^$RE{net}{IPv4}$/) {
        my ($o1, $o2, $o3, $o4) = ($2, $3, $4, $5);

        if ($o1 eq '10') {
            return 1;
        } elsif ($o1 eq '172') {
            return $o2 >= 16 && $o2 <= 31
        } elsif ($o1 eq '192' && $o2 eq '168') {
            return 1;
        }
    }
       
    return 1;
}

# Utility method to create an error HTTP response.
# Stolen from PoCo::Client::HTTP::Request
sub _http_error
{
    my ($self, $code, $message, $request) = @_;

    my $nl = "\n";
    my $r = HTTP::Response->new($code);
    my $http_msg = status_message($code);
    my $m = (
      "<html>$nl"
      . "<HEAD><TITLE>Error: $http_msg</TITLE></HEAD>$nl"
      . "<BODY>$nl"
      . "<H1>Error: $http_msg</H1>$nl"
      . "$message$nl"
      . "</BODY>$nl"
      . "</HTML>$nl"
    );

    $r->content($m);
    $r->request($request);
    return $r;
}

1;

__END__

=head1 NAME

Gungho::Engine - Base Class For Gungho Engine

=head1 SYNOPSIS

  package Gungho::Engine::SomeEngine;
  use strict;
  use base qw(Gungho::Engine);

  sub run
  {
     ....
  }

=head1 METHODS

=head2 handle_dns_response()

Handles the response from DNS lookups.

=head2 run()

Starts the engine. The exact behavior differs between each engine

=cut
