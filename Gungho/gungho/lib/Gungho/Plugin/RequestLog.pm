# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Plugin::RequestLog;
use strict;
use warnings;
use base qw(Gungho::Plugin);
use Gungho::Log::Dispatch;

__PACKAGE__->mk_accessors($_) for qw(log);

sub setup
{
    my ($self, $c) = @_;

    my $log = Gungho::Log::Dispatch->new();
    $log->setup($c, {
        min_level => 'info',
        logs => $self->config,
        callbacks => sub {
            my %args = @_;
            my $message = $args{message};
            if ($message !~ /\n$/) {
                $message =~ s/$/\n/;
            }
            sprintf('%s %s', time(), $message);
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
    my ($self, $c, $data) = @_;
    my $uri = $data->{request}->original_uri;
    $self->log->info(sprintf("Fetching %s", $uri));
}

sub log_response
{
    my ($self, $c, $data) = @_;
    $self->log->info(sprintf("DONE %s (status = %s)", $data->{request}->uri, $data->{response}->code));
}

1;

__END__

=head1 NAME

Gungho::Plugin::RequestLog - Log Requests

=head1 SYNOPSIS

  plugins:
    - module: RequestLog
      config:
        - module: File::Locked
          file: /path/to/filename
  
=head1 DESCRIPTION

If you want to know what Gungho's fetching, load this plugin

=head1 METHODS

=head2 setup

=head2 log_request

=head2 log_response

=cut
