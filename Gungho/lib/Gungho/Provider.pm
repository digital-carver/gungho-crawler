# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider;
use strict;
use warnings;
use base qw(Gungho::Base);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(has_requests);

sub dispatch {}

sub dispatch_request
{
    my ($self, $c, $req) = @_;
    $c->send_request($req);
}

sub pushback_request {
    my ($self, $c, $req) = @_;
    die ref($self) . '::pushback_request is not implemented';
}

1;

__END__

=head1 NAME

Gungho::Provider - Base Class For Gungho Prividers

=head1 METHODS

=head2 has_requests

Returns true if there are still more requests to be processed.

=head2 dispatch($c)

Dispatch requests to be fetched to the Gungho framework

=head2 dispatch_request($c, $req)

Dispatch a single request

=head2 pushback_request($c, $req)

Push back a request which couldn't be sent to the engine, for example
because the request was throttled.

=cut
