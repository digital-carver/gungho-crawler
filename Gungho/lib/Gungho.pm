# $Id$
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho;
use strict;
use warnings;
use 5.008;
use base qw(Gungho::Base);
use Carp qw(croak);
use Config::Any;
use Class::Inspector;
use UNIVERSAL::isa;
use UNIVERSAL::require;

use Gungho::Log;
use Gungho::Exception;

__PACKAGE__->mk_accessors($_) for qw(config log provider handler engine is_running hooks features);

our $VERSION = '0.03';

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

    $self->hooks({});
    $self->features({});

    $self->setup_components();
    $self->setup_log();
    $self->setup_provider();
    $self->setup_handler();
    $self->setup_engine();

    $self->setup_plugins();

    $self->next::method(@_); # This propagates to 
}

sub setup_components
{
    my $self = shift;

    my $list = $self->config->{components};
    foreach my $module (@$list) {
        my $pkg = $self->load_gungho_module($module, 'Component');
        $pkg->inject_base($self);
    }

    # XXX - Hack! Class::C3 doesn't like it when we have G::Base
    # before G::Component based objects in our ISA, so remove
    if (@$list) {
        @Gungho::ISA = grep { $_ ne 'Gungho::Base' } @Gungho::ISA;
        Class::C3::reinitialize();
    }
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
    my $obj = $pkg->new(config => $config->{config});
    $obj->setup( $self );
    $self->provider( $obj );
}

sub setup_engine
{
    my $self = shift;
    my $config = $self->config->{engine} || {
        module => 'POE',
    };
    if (! $config) {
        croak("Gungho requires a engine");
    }

    my $pkg = $self->load_gungho_module($config->{module}, 'Engine');
    my $obj = $pkg->new(config => $config->{config});
    $obj->setup( $self );
    $self->engine( $obj );
}

sub setup_handler
{
    my $self = shift;

    my $config = $self->config->{handler} || {
        module => 'Null',
        config => {}
    };
    my $pkg = $self->load_gungho_module($config->{module}, 'Handler');
    my $obj = $pkg->new(config => $config->{config});
    $obj->setup( $self );
    $self->handler( $obj );
}

sub setup_plugins
{
    my $self = shift;

    my $plugins = $self->config->{plugins} || [];
    foreach my $plugin (@$plugins) {
        my $pkg = $self->load_gungho_module($plugin->{module}, 'Plugin');
        my $obj = $pkg->new(config => $plugin->{config});
        $obj->setup($self);
    }
}

sub register_hook
{
    my $self = shift;
    my $hooks = $self->hooks;
    while(@_) {
        my($name, $hook) = splice(@_, 0, 2);
        $hooks->{$name} ||= [];
        push @{ $hooks->{$name} }, $hook;
    }
}

sub run_hook
{
    my $self = shift;
    my $name = shift;
    my $hooks = $self->hooks->{$name} || [];
    foreach my $hook (@{ $hooks }) {
        if (ref($hook) eq 'CODE') {
            $hook->($self, @_);
        } else {
            $hook->execute($self, @_);
        }
    }
}

sub has_feature
{
    my ($self, $name) = @_;
    return exists $self->features()->{$name};
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

    unless ($pkg =~ s/^\+//) {
        $pkg = ($prefix ? "Gungho::${prefix}::" : "Gungho::") . $pkg;
    }

    Class::Inspector->loaded($pkg) or $pkg->require or die;
    return $pkg;
}

sub run
{
    $_[0]->is_running(1);
    $_[0]->engine->run($_[0]);
}

sub dispatch_requests
{
    my $self = shift;
    $self->provider->dispatch($self);
}

sub prepare_request
{
    my $self = shift;
    my $req  = shift;
    $self->run_hook('dispatch.prepare_request', $req);

    return $req;
}

sub send_request
{
    my ($self, $request) = @_;

    if ($self->has_feature('Throttle')) {
        if ($self->throttle($request)) {
            $self->engine->send_request($self, $request);
        } else {
            $self->log->debug("Request " . $request->url . " (" . $request->id . ") was throttled")
                if $self->log->is_debug;
            Gungho::Exception::RequestThrottled->throw($request);
        }
    } else {
        $self->engine->send_request($self, $request);
    }
}

sub handle_response
{
    my ($self) = @_;
    $self->handler->handle_response(@_);
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

All components (engine, provider, handler) are overridable and switcheable.
Plugin mechanism is available to add hooks to be executed during the run.

WARNING: *ALL* APIs are still subject to change.

=head1 STRUCTURE

Gungho is comprised of three parts. A Provider, which provides Gungho with
requests to process, a Handler, which handles the fetched page, and an
Engine, which controls the entire process.

There are also "hooks". These hooks can be registered from anywhere by
invoking the register_hook() method. They are run at particular points,
which are specified when you call register_hook().

=head1 INLINE

If you're looking into simple crawlers, you may want to look at Gungho::Inline,

  Gungho::Inline->new({
    provider => sub { ... },
    handler  => sub { ... }
  });

See the manual for Gungho::Inline for details.

=head1 HOOKS

Currently available hooks are:

=head2 engine.send_request

=head2 engine.handle_response

=head1 METHODS

=head2 new($config)

Creates a new Gungho instance. It requires either the name of a config filename
or a hashref.

=head2 run

Starts the Gungho process.

=head2 has_feature($name)

Returns true if Gungho supports some feature $name

=head2 setup()

Sets up the Gungho environment, including calling the various setup_*
methods to configure the provider, engine, handler, etc.

=head2 setup_components()

=head2 setup_engine()

=head2 setup_handler()

=head2 setup_log()

=head2 setup_provider()

=head2 setup_plugins()

Sets up the various components.

=head2 register_hook($hook_name => $coderef[, $hook_name => $coderef])

Registers a hook to be run under the specified $hook_name

=head2 run_hook($hook_name)

Runs all the hooks under the hook $hook_name

=head2 has_requests

Delegates to provider's has_requests

=head2 get_requests

Delegates to provider's get_requests

=head2 handle_response

Delegates to handler's handle_response

=head2 dispatch_requests

Calls provider->dispatch

=head2 prepare_request($req)

Given a request, preps it before sending it to the engine

=head2 send_request

Delegates to engine's send_request

=head2 load_config($config)

Loads the config from $config via Config::Any.

=head2 load_gungho_module($name, $prefix)

Loads a Gungho component. Compliments the module name with 'Gungho::$prefix::',
unless the name is prefixed with a '+'. In that case, no transformation is
performed, and the module name is used as-is.

=head1 CODE

You can obtain the current code base from

  http://gungho-crawler.googlecode.com/svn/trunk

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
