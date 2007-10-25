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

    if (! $dns_response) {
        return;
    }

    foreach my $answer ($dns_response->answer) {
        next unless $answer->type eq 'A';
        return if $c->handle_dns_response($request, $answer, $dns_response);
    }

    $c->handle_response($request, $c->_http_error(500, "Failed to resolve host " . $request->uri->host, $request)),
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
