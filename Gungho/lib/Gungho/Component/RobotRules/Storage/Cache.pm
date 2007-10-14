# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::RobotRules::Storage::Cache;
use strict;
use warnings;
use base qw(Gungho::Component::RobotRules::Storage);

__PACKAGE__->mk_accessors($_) for qw(expiration);

sub setup
{
    my $self = shift;
    my $c    = shift;
    my %config = %{ $self->{config} };
    my $module = delete $config{module} || 'Cache::Memcached';
    my $expiration = delete $config{expiration} || 86400  * 7;

    Class::Inspector->loaded($module) or $module->require or die;
    $self->storage( $module->new(%config) );
    $self->expiration( $expiration );
    $self->next::method(@_);
}

sub get_rule
{
    my $self    = shift;
    my $c       = shift;
    my $request = shift;

    my $uri  = $request->original_uri;
    my $rule =  $self->storage->get( $uri->host_port ) || '';
    $c->log->debug("Fetch robot rules for $uri ($rule)");
    return $rule || ();
}

sub put_rule
{
    my $self    = shift;
    my $c       = shift;
    my $request = shift;
    my $rule    = shift;

    my $uri = $request->original_uri;
    $c->log->debug("Saving robot rules for $uri");

    # Cache:::Memcached::Managed is a bad boy and breaks API compatibility
    # with the rest of the Cache::* modules
    my @args;
    my $storage = $self->storage;
    if ($storage->isa('Cache::Memcached::Managed')) {
        @args = (id => $uri->host_port, key => 'robot_rules', value => $rule, expiration => $self->expiration);
    } else {
        @args = ($uri->host_port, $rule, $self->expiration);
    }
    $self->storage->set( @args );
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Storage::Cache - Cache Storage For RobotRules

=head1 SYNOPSIS

  robotrules:
    cache:
      module: 'Cache::Memcached'
      expiration: 86400
      servers:
        - 127.0.0.1:11211

=head1 METHODS

=head2 setup

=head2 get_rule

=head2 put_rule

=cut
