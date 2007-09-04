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
            my $addr = $answer->address;
            return if $self->block_private_ip_address($c, $request, $addr);

            $request->header(Host => $host);
            $request->notes(original_host => $host);
            $request->notes(resolved_ip   => $addr);
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

sub block_private_ip_address {
    my ($self, $c, $request, $address) = @_;

    if ($c->block_private_ip_address && $self->_address_is_private($address)) {
        $c->log->debug('Hostname ' . $request->uri->host . ' has a private ip address: ' . $address);
        $c->handle_response($request, $self->_http_error(500, 'Access blocked for hostname with private address: ' . $request->uri->host, $request));
        return 1;
    }
    
    undef;
}

sub _address_is_private
{
    my ($self, $address) = @_;

    if ($address =~ /^$RE{net}{IPv4}{-keep}$/) {
        my ($o1, $o2, $o3, $o4) = ($2, $3, $4, $5);

        if ($o1 eq '10') {
            return 1;
        } elsif ($o1 eq '127') {
            return 1;
        } elsif ($o1 eq '172') {
            return $o2 >= 16 && $o2 <= 31
        } elsif ($o1 eq '192' && $o2 eq '168') {
            return 1;
        }
    }
       
    return 0;
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

=head2 block_private_ip_address()

Checks if the given DNS response contains a private IP address to be blocked

=head2 run()

Starts the engine. The exact behavior differs between each engine

=cut
