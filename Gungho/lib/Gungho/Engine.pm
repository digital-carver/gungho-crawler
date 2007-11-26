# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine;
use strict;
use warnings;
use base qw(Gungho::Base);

sub run {}

sub stop {}

sub finish_request {}

sub handle_response
{
    my ($self, $c, $request, $response) = @_;
    if (my $host = $request->notes('original_host')) {
        # Put it back
        $request->uri->host($host);
    }
    $self->finish_request($request);
    $c->handle_response($request, $response);
}

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

=head2 run()

Starts the engine. The exact behavior differs between each engines

=head2 stop()

Stops the engine.  The exact behavior differs between each engines

=cut
