# $Id$
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp qw(croak);
use Config::Any;
use UNIVERSAL::require;

use Gungho::Log;

__PACKAGE__->mk_accessors($_) for qw(config log provider handler engine);

our $VERSION = '0.01';

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;

    my $config = $self->load_config($_[0]);
    $self->config($config);
    $self->setup();

    return $self;
}

sub setup
{
    my $self = shift;

    $self->setup_log();
    $self->setup_provider();
    $self->setup_handler();
    $self->setup_engine();
}

sub setup_log
{
    my $self = shift;

    my $log = Gungho::Log->new();
    $log->autoflush(1);
    $self->log($log);
}

sub setup_provider
{
    my $self = shift;

    my $config = $self->config->{provider};
    if (! $config) {
        croak("Gungho requires a provider");
    }

    my $pkg = $self->load_gungho_module($config->{module}, 'Provider');
    $self->provider( $pkg->new($config->{config}) );
}

sub setup_engine
{
    my $self = shift;
    my $config = $self->config->{engine} || {
        module => 'POE',
        config => {
            http_comp_args => {}
        }
    };
    if (! $config) {
        croak("Gungho requires a engine");
    }

    my $pkg = $self->load_gungho_module($config->{module}, 'Engine');
    $self->engine( $pkg->new($config->{config}) );
}

sub setup_handler
{
    my $self = shift;

    my $config = $self->config->{handler} || {
        module => 'Null',
        config => {}
    };
    my $pkg = $self->load_gungho_module($config->{module}, 'Handler');
    $self->handler( $pkg->new($config->{config}) );
}

sub load_config
{
    my $self = shift;
    my $config = shift;

    if ($config && ! ref $config) {
        my $filename = $config;
        # In the future, we may support multiple configs, but for now
        # just load a single file via Config::Any
        my $list = Config::Any->load_files( { files => [ $filename ] } );
        ($config) = $list->[0]->{$filename};
    }

    if (! $config) {
        croak("Could not load config");
    }

    if (ref $config ne 'HASH') {
        croak("Gungho expectes config that can be decoded to a HASH");
    }

    return $config;
}

sub load_gungho_module
{
    my $self   = shift;
    my $pkg    = shift;
    my $prefix = shift;

    unless ($pkg =~ /^\+/) {
        $pkg = ($prefix ? "Gungho::${prefix}::" : "Gungho::") . $pkg;
    }
    $pkg->require or die;
    return $pkg;
}

sub run { $_[0]->engine->run($_[0]) }

sub has_requests
{
    my $self = shift;
    $self->provider->has_requests;
}

sub get_requests
{
    my $self = shift;
    $self->provider->get_requests;
}

sub handle_response
{
    my ($self, $response) = @_;
    $self->handler->handle_response($self, $response);
}

1;

=head1 NAME

Gungho - Yet Another High Performance Web Crawler Framework

=head1 SYNOPSIS

  use Gungho;
  my $g = Gungho->new($config);
  $g->run;

=head1 DESCRIPTION

Gungho is Yet Another Web Crawler Framework, aimed to be an extensible and
fast. Its meant to be a culmination of lessons learned while building Xango --
Xango was *fast*, but it was horribly hard to debug. Gungho tries to build
from clean structures, based upon principles from the likes of Catalyst and
Plagger.

WARNING: *ALL* APIs are still subject to change.

=head1 STRUCTURE

Gungho is comprised of three parts. A Provider, which provides Gungho with
requests to process, a Handler, which handles the fetched page, and an
Engine, which controls the entire process.

=head1 METHODS

=head2 new($config)

Creates a new Gungho instance. It requires either the name of a config filename
or a hashref.

=head2 run

Starts the Gungho process.

=head2 setup

Sets up the Gungho environment, including calling the various setup_*
methods to configure the provider, engine, handler, etc.

=head2 setup_engine

=head2 setup_handler

=head2 setup_log

=head2 setup_provider

Sets up the various components.

=head2 has_requests

Delegates to provider's has_requests

=head2 get_requests

Delegates to provider's get_requests

=head2 handle_response

Delegates to handler's handle_response

=head2 load_config($config)

Loads the config from $config via Config::Any.

=head2 load_gungho_module($name, $prefix)

Loads a Gungho component. Compliments the module name with 'Gungho::$prefix::',
unless the name is prefixed with a '+'. In that case, no transformation is
performed, and the module name is used as-is.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
