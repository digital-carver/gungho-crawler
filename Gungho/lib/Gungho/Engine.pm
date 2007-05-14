# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine;
use strict;
use warnings;
use base qw(Gungho::Base);
use HTTP::Status qw(status_message);

sub run {}

sub handle_dns_response
{
    my ($self, $c, $request, $dns_response) = @_;

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
        $c->send_request($request);
        return;
    }

    $self->_http_error(500, "Failed to resolve host " . $request->uri->host, $request),
}

sub _address_is_private
{
    my ($self, $address) = @_;

    return $address =~ /^(?:192\.168|10\.0)\.\d+\.\d+$/
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

=head2 run()

=head2 handle_dns_response()

Handles the response from DNS lookups.

Starts the engine. The exact behavior differs between each engine

=cut
