# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::Danga::Socket;
use strict;
use warnings;
use base qw(Gungho::Engine);
use HTTP::Parser;
use IO::Socket::INET;

# Danga::Socket uses the field pragma, which breaks things
# if we try to subclass from both Gungho::Engine and Danga::Socket.

__PACKAGE__->mk_accessors($_) for qw(impl_class active_requests context loop_delay);

sub setup
{
    my $self = shift;
    $self->impl_class('Gungho::Engine::Danga::Socket::Impl');
    $self->active_requests({});
    $self->loop_delay( $self->config->{loop_delay} ) if $self->config->{loop_delay};
    $self->next::method(@_);
}

sub run
{
    my ($self, $c) = @_;

    my $impl = $self->impl_class;
    $self->context($c);
    $impl->SetPostLoopCallback(
        sub {
            $c->dispatch_requests();

            my $delay = $self->loop_delay;
            if (! defined $delay || $delay <= 0) {
                $delay = 5;
            }
            select(undef, undef, undef, $delay);

            my $continue =  $c->is_running || Danga::Socket->WatchedSockets();

            if (! $continue) {
                $c->log->info("no more requests, stopping...");
            }
            return $continue;
        }
    );
    $impl->EventLoop();
}
        
sub send_request
{
    my $self = shift;
    my $c    = shift;
    my $req  = shift;

    my $uri  = $req->uri;

    my $socket = IO::Socket::INET->new(
        PeerAddr => $uri->host,
        PeerPort => $uri->port || $uri->default_port,
        Blocking => 0,
    );
    die if $@;

    my $impl = $self->impl_class;
    my $danga = $impl->new($socket);

    $danga->watch_read(1);
    $danga->watch_write(1);
    $danga->{request} = $req;
    $danga->{engine}  = $self;

    $req->headers->push_header(user_agent => $c->default_user_agent);
    $req->notes(danga => $danga);
}

sub handle_response
{
    my $self = shift;
    my $request = shift;
    my $response = shift;
    delete $self->active_requests->{$request->id};

    my $danga = $request->notes('danga');
    $request->notes('danga', undef);

    $self->context->handle_response($request, $response);
}

package Gungho::Engine::Danga::Socket::Impl;
use strict;
use Danga::Socket;
use base qw(Danga::Socket);
use fields qw(request write_done engine);

sub new
{
    my Gungho::Engine::Danga::Socket::Impl $self = shift;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);
    return $self;
}

sub event_write
{
    my $self = shift;

    if ($self->{write_done}) {
        if ($self->write(undef)) {
            $self->watch_write(0);
        }
    }

    my $request = $self->{request};
    my $req_str = $request->format();
    if ($self->write($req_str)) {
        $self->watch_write(0);
    }
    $self->{write_done} = 1;
}

sub event_read
{
    my $self = shift;

    my $request = $self->{request};
    my $parser = $request->notes('parser');
    if (! $parser) {
        $parser = HTTP::Parser->new(response => 1);
        $request->notes('parser', $parser);
    }

    my ($buf, $success);
    while(1) {
        my $bytes = sysread($self->sock(), $buf, 8192);
        last if ($bytes || 0) <= 0;

        my $parser_status = $parser->add($buf);

        if ($parser_status == 0 ) {
            $success = 1;
            last;
        }
    }

    if (! $success) {
        die "Stopped reading, but we don't have enough to create a response";
    }

    my $response = $parser->object;
    $response->request($request);

    $self->watch_read(0);

    delete Danga::Socket->DescriptorMap->{ fileno($self->sock) };
    $self->{engine}->handle_response($request, $response);
}

1;

__END__

=head1 NAME

Gungho::Engine::Danga::Socket - Gungho Engine Using Danga::Socket

=head1 DESCRIPTION

This class uses Danga::Socket to dispatch requests.

WARNING: This engine is still experimental. Patches welcome!
In particular, this class definitely should cache connections.

=head1 METHODS

=head2 setup

=head2 run

=head2 send_request

=head2 handle_response

=cut