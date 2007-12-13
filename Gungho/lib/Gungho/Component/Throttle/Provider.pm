# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Throttle::Provider;
use strict;
use warnings;
use base qw(Gungho::Component);

__PACKAGE__->mk_classdata($_) for qw(request_count max_requests pending_requests);

sub setup
{
    my $c = shift;
    $c->next::method();
    my $config = $c->config->{throttle}{provider} || {};
    my $max = $config->{max_requests} || 10;
    $c->pending_requests( {} );
    $c->request_count( 0 );
    $c->max_requests( $max );
}

sub dispatch_requests
{
    my ($c) = @_;

    if ($c->request_count < $c->max_requests) {
        $c->next::method();
    } else {
        $c->log->debug("Max request count " . $c->max_requests . " reached");
    }
}

sub send_request
{
    my ($c, $request) = @_;

    if ($c->next::method($request)) {
        if (! $c->pending_requests->{ $request->id }) {
            $c->pending_requests->{ $request->id } = $request;
            $c->increment_request_count();
        }
        $c->log->debug( $request->uri );
        $c->log->debug( "count is " . $c->request_count );
    }
}

sub handle_response
{
    my ($c, $request, $response) = @_;

    $c->next::method($request, $response);
    delete $c->pending_requests->{ $request->id };
    $c->decrement_request_count();
}

sub increment_request_count
{
    my $c = shift;
    $c->request_count( $c->request_count + 1 );
}

sub decrement_request_count
{
    my $c = shift;
    $c->request_count( $c->request_count - 1 );
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle::Provider - Throttle Calls To The Provider

=head1 SYNOPSIS

  components:
    - Throttle::Provider
  throttle:
    provider:
      max_requests: 10

=head1 DESCRIPTION

Often times it is more conveinient to throttle the number of times the Provider
is invoked to fetch the next request than for the provider to keep tabs of
how many requests it has sent so far.

This component keeps track of how many URLs have gone through send_request()
and back to handle_response(), and will prevent Gungho from calling the
provider to fetch the next request.

=cut