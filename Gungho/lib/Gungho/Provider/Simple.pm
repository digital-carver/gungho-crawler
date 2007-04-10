# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider::Simple;
use strict;
use warnings;
use base qw(Gungho::Provider);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(requests);

sub new
{
    my $class = shift;
    my $self  = $class->next::method(@_);
    $self->requests([]);
    $self;
}

sub setup
{
    my $self = shift;

    my $url = $self->config->{url};
    if (! ref($url) ) {
        $url = [ $url ];
    }

    foreach my $u (@$url) {
        $self->add_request(
            Gungho::Request->new(GET => $u)
        );
    }
    $self->next::method(@_);
}

sub add_request
{
    my ($self, $req) = @_;

    my $list = $self->requests;
    push @$list, $req;
    $self->has_requests(1);
}

sub get_requests
{
    my ($self, $c) = @_;

    my $list = $self->requests;
    $self->requests([]);
    $self->has_requests(0);
    $c->is_running(0);
    return @$list;
}

1;

__END__

=head1 NAME

Gungho::Provider::Simple - An In-Memory, Simple Provider

=head1 SYNOPSIS

  use Gungho::Provider::Simple;
  my $g = Gungho::Provider::Simple->new;
  $g->add_request(Gungho::Request->new(GET => 'http://...'));
  
=head1 METHODS

=head2 new()

Creates a new instance.

=head2 setup($c)

Sets up the provider.

=head2 add_request($request)

Adds a new request to the provider.

=head2 get_requests()

Returns the list of requests in the provider. The list is set to an empty
list after the call, and has_requests is set to 0



=cut