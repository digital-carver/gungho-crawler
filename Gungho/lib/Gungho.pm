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

my @INTERNAL_PARAMS             = qw(setup_finished);
my @CONFIGURABLE_PARAMS         = qw(block_private_ip_address user_agent);
my %CONFIGURABLE_PARAM_DEFAULTS = (
    map { ($_ => 0) } @CONFIGURABLE_PARAMS
);

__PACKAGE__->mk_classdata($_) for (
    qw(log provider handler engine is_running hooks features),
    @INTERNAL_PARAMS,
    @CONFIGURABLE_PARAMS,
);

our $VERSION = '0.08011';

sub new
{
    warn "Gungho::new() has been deprecated in favor of Gungho->run()";
    my $class = shift;
    $class->setup(@_);
    return $class;
}

sub setup
{
    my $self = shift;

    my $config = $self->load_config($_[0]);
    if (exists $ENV{GUNGHO_DEBUG}) {
        $config->{debug} = $ENV{GUNGHO_DEBUG};
    }

    $self->config($config);

    for my $key (@CONFIGURABLE_PARAMS) {
        $self->$key( $config->{$key} || $CONFIGURABLE_PARAM_DEFAULTS{$key} );
    }

    $self->user_agent("Gungho/$Gungho::VERSION (http://code.google.com/p/gungho-crawler/wiki/Index)") unless $config->{user_agent};
    $self->hooks({});
    $self->features({});

    $self->setup_components();
    $self->setup_log();
    $self->setup_provider();
    $self->setup_handler();
    $self->setup_engine();
    $self->setup_plugins();

    $self->next::method(@_);
    $self->setup_finished(1);
    $self;
}

sub setup_components
{
    my $self = shift;

    my $list = $self->config->{components};
    foreach my $module (@$list) {
        my $pkg = $self->load_gungho_module($module, 'Component');
        $pkg->isa('Gungho::Component') or die "$pkg is not a Gungho::Component subclass";
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

    my $log_config = $self->config->{log} || {};
    my @levels     = @{ $log_config->{levels} || [ qw(info warn error fatal) ] };

    my $log = Gungho::Log->new(@levels);
    $log->autoflush(1);

    # Only explicitly enable debug if the global debug flag is set
    if ($self->config->{debug}) {
        $log->enable('debug');
    }

    $self->log($log);
}

sub setup_provider
{
    my $self = shift;

    my $config = $self->config->{provider};
    if (! $config || ref $config ne 'HASH') {
        croak("Gungho requires a provider");
    }

    my $pkg = $self->load_gungho_module($config->{module}, 'Provider');
    $pkg->isa('Gungho::Provider') or die "$pkg is not a Gungho::Provider subclass";
    $pkg->config($config->{config}) if $config->{config};
    my $obj = $pkg->new();
    $obj->setup( $self );
    $self->provider( $obj );
}

sub setup_engine
{
    my $self = shift;
    my $config = $self->config->{engine} || {
        module => 'POE',
    };
    if (! $config || ref $config ne 'HASH') {
        croak("Gungho requires a engine");
    }

    my $pkg = $self->load_gungho_module($config->{module}, 'Engine');
    $pkg->isa('Gungho::Engine') or die "$pkg is not a Gungho::Engine subclass";
    $pkg->config($config->{config}) if $config->{config};
    my $obj = $pkg->new();
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
    $pkg->isa('Gungho::Handler') or die "$pkg is not a Gungho::Handler subclass";
    $pkg->config($config->{config}) if $config->{config};
    my $obj = $pkg->new();
    $obj->setup( $self );
    $self->handler( $obj );
}

sub setup_plugins
{
    my $self = shift;

    my $plugins = $self->config->{plugins} || [];
    foreach my $plugin (@$plugins) {
        my $pkg = $self->load_gungho_module($plugin->{module}, 'Plugin');
        $pkg->config($plugin->{config}) if $plugin->{config};
        my $obj = $pkg->new();
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
    my $self = shift;
    if (! $self->setup_finished()) {
        $self->setup(@_);
    }
    $self->is_running(1);
    $self->engine->run($self);
}

sub dispatch_requests
{
    my $c = shift;
    $c->provider->dispatch($c, @_);
}

sub prepare_request
{
    my $c = shift;
    my $req  = shift;
    $c->run_hook('dispatch.prepare_request', $req);
    return $req;
}

sub send_request
{
    my $c = shift;
    my $e;
    eval {
        $c->maybe::next::method(@_);
    };
    if ($e = Gungho::Exception->caught('Gungho::Exception::SendRequest::Handled')) {
        return;
    } elsif ($e = Gungho::Exception->caught()) {
        die $e;
    }
    $c->engine->send_request($c, @_);
}

sub handle_response
{
    my $c = shift;

    my $e;
    eval {
        $c->maybe::next::method(@_);
    };
    if ($e = Gungho::Exception->caught('Gungho::Exception::HandleResponse::Handled')) {
        return;
    } elsif ($e = Gungho::Exception->caught()) {
        die $e;
    }
    $c->handler->handle_response($c, @_);
}

1;

=head1 NAME

Gungho - Yet Another High Performance Web Crawler Framework

=head1 SYNOPSIS

  use Gungho;
  Gungho->run($config);

=head1 DESCRIPTION

Gungho is Yet Another Web Crawler Framework, aimed to be extensible and
fast. Its meant to be a culmination of lessons learned while building Xango --
Xango was *fast*, but it was horribly hard to debug or to extend (Gungho
even works right out of the box ;)

Therefore, Gungho's main aim is to make it as easy as possible to write
complex crawlers, while still keeping crawling *fast*. You can simply specify
the urls to fetch and some code to handle the responses -- we do the rest.

Gungho tries to build from clean structures, based upon principles from the
likes of Catalyst and Plagger, so that you can easily extend it to your
liking.

Features such as robot rules handling (robots.txt) and request throttling
can be removed/added on the fly, just by specifying the components that
you want to load. You can easily create additional functionality by writing
your own component.

Gungho is still very fast -- it uses event driven frameworks such as
POE, Danga::Socket, and IO::Async as the main engine to drive requests.
Choose the best engine for your needs: For example, if you plan on creating
a POE-based handler to process the response, you might choose the POE engine -
it will fit nicely into the request cycle. However, do note that the most
heavily excercised engine is POE. Danga::Socket and IO::Async works, but
haven't been tested too vigorously. Please send in requests and bug reports
if you encounter any problems.

WARNING: *ALL* APIs are still subject to change.

=head1 STRUCTURE

Gungho is comprised of three parts. A Provider, which provides Gungho with
requests to process, a Handler, which handles the fetched page, and an
Engine, which controls the entire process.

There are also "hooks". These hooks can be registered from anywhere by
invoking the register_hook() method. They are run at particular points,
which are specified when you call register_hook().

All components (engine, provider, handler) are overridable and switcheable.
However, do note that if you plan on customizing stuff, you should be aware
that Gungho uses Class::C3 extensively, and hence you may see warnings about
the code you use.

=head1 CONFIGURATION OPTIONS

=over 4

=item debug

   ---
   debug: 1

Setting debug to a non-zero value will trigger debug messages to be displayed.

=item block_private_ip_address

   ---
   block_private_ip_address: 1

Setting this to a non-zero value will make addresses resolved via DNS lookups
to be blocked, if they resolved to a private IP address such as 192.168.1.1.
Note that 127.0.0.1 is also considered a private IP.

=back

=head1 COMPONENTS

Components add new functionality to Gungho. Components are loaded at
startup time fro the config file / hash given to Gungho constructor.

  Gungho->run({
    components => [
      'Throttle::Simple'
    ],
    throttle => {
      max_interval => ...,
    }
  });

Components modify Gungho's inheritance structure at run time to add
extra functionality to Gungho, and therefore should only be loaded
before starting the engine.

Here are some available components. Checkout the distribution for a current,
complete list:

=over 4

=item RobotRules

Handles collecting, parsing robots.txt, as well rejecting requests based on 
the rules provided from it.

=item Authentication::Basic

Handles basic auth automatically.

=item Throttle::Domain

Throttles requests based on the number of requests sent to a domain.

=back

=head1 INLINE

If you're looking into simple crawlers, you may want to look at Gungho::Inline,

  Gungho::Inline->run({
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

This method has been deprecated. Use run() instead.

=head2 run

Starts the Gungho process.  It requires either the name of a config filename
or a hashref.

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

=head1 HOW *NOT* TO USE Gungho

One last note about Gungho - Don't use it if you are planning on accessing
a single url -- It's usually not worth it, so you might as well use
LWP::UserAgent or an equivalent module.

Gungho's event driven engine works best when you are accessing hundreds,
if not thousands of urls. It may in fact be slower than using LWP::UserAgent
if you are accessing just a single url.

Of course, you may wish to utilize features other than speed that Gungho 
provides, so at that point, it's simply up to you.

=head1 CODE

You can obtain the current code base from

  http://gungho-crawler.googlecode.com/svn/trunk

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 CONTRIBUTORS

=over 4

=item Kazuho Oku

=item Keiichi Okabe

=back

=head1 SEE ALSO

L<Gungho::Inline|Gungho::Inline>
L<Gungho::Component::RobotRules|Gungho::Component::RobotRules>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
