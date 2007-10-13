# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::RequestLog;
use strict;
use warnings;
use base qw(Gungho::Component);
use Gungho::Log::Dispatch;

__PACKAGE__->mk_accessors($_) for qw(log);

sub setup
{
    my ($self, $c) = @_;

    my $log = Gungho::Log::Dispatch->new();
    $log->setup($c, {
        min_level => 'info',
        logs => $c->config->{request_log},
        callbacks => sub {
            my %args = @_;
            sprintf('%s %s', time(), $args{message});
        }
    });
    $self->log($log);

    $c->register_hook(
        'engine.send_request'    => sub { $self->log_request(@_) },
        'engine.handle_response' => sub { $self->log_response(@_) },
    );
}

sub log_request
{
    my ($self, $data) = @_;
    $self->log->info(sprintf("Fetching %s", $data->{request}->uri));
}

sub log_response
{
    my ($self, $data) = @_;
    $self->log->info(sprintf("DONE %s (status = %s)", $data->{request}->uri, $data->{response}->code));
}

1;
