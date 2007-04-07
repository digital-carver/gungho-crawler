# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::POE;
use strict;
use warnings;
use base qw(Gungho::Engine);
use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Client::HTTP;

__PACKAGE__->mk_accessors($_) for qw(alias);

use constant UserAgentAlias => 'Gungho_Engine_POE_UserAgent_Alias';

sub setup
{
    my $self = shift;
    $self->alias('MainComp');
    $self->next::method(@_);
}

sub run
{
    my ($self, $c) = @_;

    my %config = %{ $self->config || {} };

    my $keepalive_config = delete $config{keepalive} || {};
    $keepalive_config->{keep_alive}   ||= 10;
    $keepalive_config->{max_open}     ||= 200;
    $keepalive_config->{max_per_host} ||= 5;
    $keepalive_config->{timeout}      ||= 1;

    my $keepalive = POE::Component::Client::Keepalive->new(%$keepalive_config);

    my $client_config = delete $config{client} || {};
    foreach my $key (keys %$client_config) {
        if ($key =~ /^[a-z]/) { # ah, need to make this CamelCase
            my $camel = ucfirst($key);
            $camel =~ s/_(\w)/uc($1)/ge;
            $client_config->{$camel} = delete $client_config->{$key};
        }
    }

    POE::Component::Client::HTTP->spawn(
        %$client_config,
        Alias             => &UserAgentAlias,
        ConnectionManager => $keepalive,
    );

    POE::Session->create(
        heap => { CONTEXT => $c },
        object_states => [
            $self => {
                _start          => 'session_start',
                _stop           => 'session_stop',
                session_loop    => 'session_loop',
                handle_response => 'handle_response',
            }
        ]
    );
    
    POE::Kernel->run();
}

sub session_start
{
    $_[KERNEL]->alias_set( $_[OBJECT]->alias );
    $_[KERNEL]->yield('session_loop');
}

sub session_stop
{
    $_[KERNEL]->alias_remove( $_[OBJECT]->alias );
}

sub session_loop
{
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $c = $heap->{CONTEXT};

    if ($c->has_requests) {
        foreach my $request ( $c->get_requests() ) {
            $kernel->post(&UserAgentAlias, 'request', 'handle_response', $request);
        }

        $kernel->yield('session_loop');
    }
}

sub handle_response
{
    my ($heap, $req_packet, $res_packet) = @_[ HEAP, ARG0, ARG1 ];

    my $c = $heap->{CONTEXT};

    my $req = $req_packet->[0];
    my $res = $res_packet->[0];
    $c->handle_response($res);
}

1;

__END__

=head1 NAME

Gungho::Engine::POE - POE Engine For Gungho

=head1 SYNOPSIS

  engine:
    module: POE
    config:
      client:
        agent:
          - AgentName1
          - AgentName2
        max_size: 16384
        follow_redirect: 2
        proxy: http://localhost:8080
      keepalive:
        keep_alive: 10
        max_open: 200
        max_per_host: 20
        timeout: 10


=head1 DESCRIPTION

=head1 USING KEEPALIVE

Gungho::Engine::POE uses PoCo::Client::Keepalive to control the connections.
For the most part this has no visible effect on the user, but the "timeout"
parameter dictate exactly how long the component waits for a new connection
which means that, after finishing to fetch all the requests the engine
waits for that amount of time before terminating. This is NORMAL.

=head1 METHODS

=head2 setup

sets up the engine.

=head2 run

Instantiates a PoCo::Client::HTTP session and a main session that handles the
main control.

=head2 handle_response

=head2 session_start

=head2 session_stop

=head2 session_loop

These are used as POE session states

=head1 TODO

Xango, Gungho's predecessor, tried really hard to overcome one of my pet-peeves
with PoCo::Client::HTTP -- which is that, while it can handle hundreds and
thousands of requests, all the requests are unnecessarily stored on
memory. Xango tried to solve this, but it ended up bloating the software.
We may try to tackle this later.

=cut