# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::RobotRules::Storage::Cache;
use strict;
use warnings;
use base qw(Gungho::Component::RobotRules::Storage);

sub setup
{
    my $self = shift;
    my %config = %{ $self->config() };
    my $module = delete $config{module} || 'Cache::Memcached';

    Class::Inspector->loaded($module) or $module->require or die;
    $self->storage( $module->new(%$config) );
    $self->next::method(@_);
}

sub get_rule
{
    my $self = shift;
    my $request = shift;

    my $uri = $request->original_uri;
    return $self->storage->get( $uri->host_port ) || ();
}

sub put_rule
{
    my $self = shift;
    my $request = shift;
    my $rule    = shift;

    my $uri = $request->original_uri;
    $self->storage->set( $uri->host_port, $rule );
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Storage::Cache - Cache Storage For RobotRules

=head1 METHODS

=head2 setup

=head2 get_rule

=head2 put_rule

=cut


1;