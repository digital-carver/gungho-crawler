# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Base;
use strict;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Class::C3;
INIT { Class::C3::initialize() }

__PACKAGE__->mk_classdata(config => {});

sub new
{
    my $class  = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

sub setup {}

1;

__END__

=head1 NAME

Gungho::Base - Base Class For Various Gungho Objects

=head1 SYNOPSIS

  package Gungho::Something;
  use base qw(Gungho::Base);

=head1 MMETHODS

=head2 new(\%config)

Creates a new object instance. Takes a config hashref. 

=head2 setup()

Sets up the object. Use it like this in your object:

  sub setup
  {
     my $self = shift;
     # do custom setup
     $self->next::method(@_);
  }

=cut
