# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::Throttle;
use strict;
use warnings;
use base qw(Gungho::Component);

sub feature_name { 'Throttle' }
sub throttle { 1 }

sub send_request
{
    my ($c, $request) = @_;

    if (! $request->notes('original_host') && ! $c->throttle($request)) {
        $c->log->debug("Request " . $request->url . " (" . $request->id . ") was throttled")
            if $c->log->is_debug;
        $c->provider->pushback_request($c, $request);
        Gungho::Exception::SendRequest::Handled->throw();
    }
    $c->maybe::next::method($request);
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle - Base Class To Throttle Requests

=head1 SYNOPSIS

  package Gungho::Component::Throttle::Domain;
  use base qw(Gungho::Component::Throttle);

=head1 METHODS

=head2 feature_name

=head2 throttle

=head2 send_request

=cut