# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Request;
use strict;
use warnings;
use base qw(HTTP::Request);
use Storable qw(dclone);

sub clone
{
    my $self  = shift;
    my $clone = $self->SUPER::clone;
    $clone->notes( dclone $self->notes );
}

sub notes
{
    my $self = shift;
    my $key  = shift;

    return $self->{_notes} unless $key;

    my $value = $self->{_notes}{$key};
    if (@_) {
        $self->{_notes}{$key} = $_[1];
    }
    return $value;
}

1;

__END__

=head1 NAME

Gungho::Request - A Gungho Request Object

=head1 DESCRIPTION

Currently this class is exactly the same as HTTP::Request, but we're
creating this separately in anticipation for a possible change

=head1 METHODS

=head2 clone

Clones the request.

=head2 notes($key[, $value])

Associate arbitrary notes to the request

=cut
