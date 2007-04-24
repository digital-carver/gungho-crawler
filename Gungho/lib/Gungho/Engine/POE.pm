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

__PACKAGE__->mk_accessors($_) for qw(alias loop_alarm loop_delay);

use constant UserAgentAlias => 'Gungho_Engine_POE_UserAgent_Alias';
use constant SKIP_DECODE_CONTENT  =>
    exists $ENV{GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT} ?  $ENV{GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT} : 1;
use constant FORCE_ENCODE_CONTENT => 
    $ENV{GUNGHO_ENGINE_POE_FORCE_ENCODE_CONTENT} && ! SKIP_DECODE_CONTENT;

BEGIN
{
    if (SKIP_DECODE_CONTENT) {
        eval <<'        EOCODE';
            no warnings 'redefine';
            sub HTTP::Response::decoded_content {
                my ($self, %opt) = @_;
                my $caller = (caller(2))[3];
                if ($caller eq 'POE::Component::Client::HTTP::Request::return_response') {
                    $opt{charset} = 'none';
                }
                $self->SUPER::decoded_content(%opt);
            }
        EOCODE
    }
}

sub setup
{
    my $self = shift;
    $self->alias('MainComp');
    $self->loop_delay( $self->config->{loop_delay} ) if $self->config->{loop_delay};
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
    $keepalive_config->{timeout}      ||= 10;

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
        Agent             => "Gungho/$Gungho::VERSION",
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
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
    $self->loop_alarm(undef);

    my $c = $heap->{CONTEXT};

    if (! $c->is_running) {
        $c->log->debug("is_running = 0, waiting for other queued states to finish...\n") if $c->log->is_debug;
        return;
    }

    $c->dispatch_requests();

    my $alarm_id = $self->loop_alarm;
    if (! $alarm_id) {
        my $delay = $self->loop_delay;
        if (! defined $delay || $delay <= 0) {
            $delay = 5;
        }
        $self->loop_alarm($kernel->delay_set('session_loop', $delay));
    }
}

# XXX - this is not a POE state. hmmm??
sub send_request
{
    my ($self, $c, $request) = @_;
    $c->run_hook('engine.send_request', { request => $request });
    POE::Kernel->post(&UserAgentAlias, 'request', 'handle_response', $request);
}

sub handle_response
{
    my ($heap, $req_packet, $res_packet) = @_[ HEAP, ARG0, ARG1 ];

    my $c = $heap->{CONTEXT};

    my $req = $req_packet->[0];
    my $res = $res_packet->[0];

    # Work around POE doing too much for us. 
    if (FORCE_ENCODE_CONTENT && $POE::Component::Client::HTTP::VERSION >= 0.80) {
        if ($res->content_encoding) {
            my @ct = $res->content_type;
            if ((shift @ct) =~ /^text\//) {
                foreach my $ct (@ct) {
                    next unless $ct =~ /charset=((?!utf-?8).+)$/;
                    my $enc = $1;
                    require Encode;
                    $res->content( Encode::encode($enc, $res->content) );
                    last;
                }
            }
        }
    }

    $c->run_hook('engine.handle_response', { request => $req, response => $res });

    # Do we support auth challenge ?
    my $code = $c->can('check_authentication_challenge');
    if ( $code ) {
        # return if auth has taken care of the response
        return if $code->($c, $req, $res);
    }
        
    $c->handle_response($req, $res);
}

1;

__END__

=head1 NAME

Gungho::Engine::POE - POE Engine For Gungho

=head1 SYNOPSIS

  engine:
    module: POE
    config:
      loop_delay: 0.5
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

Gunghog::Engine::POE gives you the full power of POE to Gungho.

=head1 POE::Component::Client::HTTP AND DECODED CONTENTS

Since version 0.80, POE::Component::Client::HTTP silently decodes the content 
of an HTTP response. This means that, even when the HTTP header states

  Content-Type: text/html; charset=euc-jp

Your content grabbed via $response->content() will be in decode Perl unicode.
This is a side-effect from POE::Component::Client::HTTP trying to handle
Content-Encoding for us, and HTTP::Request also trying to be clever.

We have devised workarounds for this. You can either set the following
variables in your environment (before Gunghoe::Engine::POE is loaded)
to enable the workarounds:

  GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT = 1
  # or
  GUNGHO_ENGINE_POE_FORCE_ENCODE_CONTENT = 1

See L<ENVIRONMENT VARIABLES|ENVIRONMENT VARIABLES> for details

=head1 USING KEEPALIVE

Gungho::Engine::POE uses PoCo::Client::Keepalive to control the connections.
For the most part this has no visible effect on the user, but the "timeout"
parameter dictate exactly how long the component waits for a new connection
which means that, after finishing to fetch all the requests the engine
waits for that amount of time before terminating. This is NORMAL.

=head1 ENVIRONMENT VARIABLES

=head2 GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT

When set to a non-null value, this will install a new subroutine in
HTTP::Response's namespace, and will circumvent HTTP::Response to decode
its content by explicitly passing charset = 'none' to HTTP::Response's
decoded_content().

This workaround is ENABLED by default.

=head2 GUNGHO_ENGINE_POE_FORCE_ENCODE_CONTENT

When set to a non-null value, this will re-encode the content back to
what the Content-Type header specified the charset to be.

By default this option is disabled.

=head1 METHODS

=head2 setup

sets up the engine.

=head2 run

Instantiates a PoCo::Client::HTTP session and a main session that handles the
main control.

=head2 send_request($request)

Sends a request to the http client

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