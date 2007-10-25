# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Log::Simple;
use strict;
use warnings;
use base qw(Gungho::Log::Dispatch);

sub setup
{
    my $self   = shift;
    my $c      = shift;

    my $config = $c->config || {};
    if (ref $config->{logs} ne 'HASH') {
        $config->{logs} = {};
    }

    $config->{logs}{module} = 'Screen';
    $config->{logs}{name}   = 'simple';
    $self->next::method($c);
}

1;

__END__

=head1 NAME

Gungho::Log::Simple - Simple Gungho Log Class

=head1 SYNOPSIS

  use Gungho::Log::Simple;

  my $log = Gungho::Log::Simple->new();
  $log->setup($c,);

=head1 DESCRIPTION

This is a simple logger, which only logs to stderr.

=head1 METHODS

=head2 setup

Sets up the log

=cut