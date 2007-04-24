# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# Copyright (c) 2007 Kazuho Oku
# All rights reserved.

package Gungho::Inline;
use strict;
use warnings;
use base qw(Gungho);
use Gungho::Request;

sub new {
    my $class = shift;
    my $config = shift;
    
    foreach my $k qw(provider handler) {
        if ($config->{$k} && ref $config->{$k} eq 'CODE') {
            $config->{$k} = {
                module => qw(Inline),
                config => {
                    callback => $config->{$k},
                },
            };
        }
    }

    $class->SUPER::new($config);
}

package Gungho::Provider::Inline;

use base qw(Gungho::Provider);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(requests callback);

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->has_requests(1);
    $self->requests([]);
    $self;
}

sub setup {
    my $self = shift;
    my $callback = $self->config->{callback};
    die "``callback'' not supplied\n" unless ref $callback eq 'CODE';
    $self->callback($callback);
    $self->next::method(@_);
}

sub add_request {
    my ($self, $req) = @_;
    push @{$self->requests}, $req;
}

sub pushback_request {
    my ($self, $c, $req) = @_;
    $self->add_request($req);
}

sub dispatch {
    my ($self, $c) = @_;
    
    if ($self->callback) {
        unless ($self->callback->($c, $self)) {
            $self->callback(undef);
        }
    }
    
    my $reqs = $self->requests;
    $self->requests([]);
    while (@$reqs) {
        $self->dispatch_request($c, shift @$reqs);
    }
    
    if (! $self->callback && @{$self->requests} == 0) {
        $self->has_requests(0);
        $c->is_running(0);
    }
}

package Gungho::Handler::Inline;

use base qw(Gungho::Handler);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(callback);


sub setup {
    my $self = shift;
    my $callback = $self->config->{callback};
    die "``callback'' not supplied\n" unless ref $callback eq 'CODE';
    $self->callback($callback);
    $self->next::method(@_);
}

sub handle_response {
    my ($self, $c, $req, $res) = @_;
    
    $self->callback->($req, $res, $c, $self);
}

1;


__END__

=head1 NAME

Gungho::Inline - Inline Your Providers And Handlers

=head1 SYNOPSIS

  use Gungho::Inline;
  use IO::Select;
  
  Gungho::Inline->new({
    provider => sub {
      my ($c, $p) = @_;
      while (IO::Select->new(STDIN)->can_read(0)) {
        return if STDIN->eof;
        my $url = STDIN->getline;
        chomp $url;
        $p->add_request($c->prepare_request(Gungho::Request->new(GET => $url)));
      }
      1;
    },
    handler => sub {
      my ($req, $res) = @_;
      print $res->code, ' ', $req->uri, "\n";
    },
  })->run();

=head1 DESCRIPTION

Sometimes you don't need the full power of an independent Gungho Provider
and or Handler. In those cases, Gungho::Inline saves you from creating 
separate packages

This module is still experimental. Feedback welcome

=head1 METHODS

=head2 new(provider => $callback, handler => $callback)

Creates a new Gungho instance with these callbacks

=head1 AUTHOR

Original code by Kazuho Oku. 
  
=cut