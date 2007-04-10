# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider;
use strict;
use base qw(Gungho::Base);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(has_requests);

sub get_requests {}

1;

__END__

=head1 NAME

Gungho::Provider - Base Class For Gungho Prividers

=head1 METHODS

=head2 has_requests

Returns true if there are still more requests to be processed.

=head2 get_requests

Returns a list of requests that wished to be processed.

=cut
