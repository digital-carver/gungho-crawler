# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider::File::Simple;
use strict;
use warnings;
use base qw(Gungho::Provider);

__PACKAGE__->mk_accessors($_) for qw(read_done requests);

sub new
{
    my $class = shift;
    my $self = $class->next::method(@_);

    $self->has_requests(1);
    $self->read_done(0);
    $self->requests([]);
    $self;
}

sub pushback_request
{
    my ($self, $req) = @_;

    my $list = $self->requests;
    push @$list, $req;
    $self->has_requests(1);
}

sub dispatch
{
    my ($self, $c) = @_;

    if (! $self->read_done) {
        my $filename = $self->config->{filename};
        die "No file specified" unless $filename;
        open(my $fh, $filename) or
            die "Could not open $filename for reading: $!";

        while (<$fh>) {
            chomp;
            next unless /\S+/;

            my $req = $c->prepare_request(Gungho::Request->new(GET => $_));
            $self->pushback_request($req);
        }
        close($fh);
        $self->read_done(1)
    }

    my $requests = $self->requests;
    $self->requests([]);
    while (@$requests) {
        $self->dispatch_request($c, shift @$requests);
    }

    if (scalar @{ $self->requests } <= 0) {
        $c->is_running(0);
    }
}

1;

__END__

=head1 NAME

Gungho::Provider::File::Simple - Provide Requests From A Simple File

=head1 SYNOPSIS

  provider:
    module: File::Simple
    config:
      filename: /path/to/filename

  # in file
  http://foo.com
  http://bar.com
  http://baz.com

=head1 METHODS

=head2 new

Creates a new instance.

=head2 pushback_request

=head2 dispatch

=cut
