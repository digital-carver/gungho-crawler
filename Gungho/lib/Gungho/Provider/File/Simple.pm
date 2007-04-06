# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider::File::Simple;
use strict;
use warnings;
use base qw(Gungho::Provider);

sub new
{
    my $class = shift;
    my $self = $class->next::method(@_);

    $self->has_requests(1);
    $self;
}

sub _parse_fh
{
    my $self = shift;
    my $fh   = shift;

    my @requests;
    while (<$fh>) {
        chomp;
        next unless /\S+/;
        push @requests, Gungho::Request->new(GET => $_);
    }
    return @requests;
}

sub get_requests
{
    my $self = shift;

    my $filename = $self->config->{filename};
    open(my $fh, $filename) or
        die "Could not open $filename for reading: $!";

    my @requests = $self->_parse_fh($fh);
    close($fh);

    $self->has_requests(0);

    return @requests;
}

1;

__END__

=head1 NAME

Gungho::Provider::File::Simple - Provide Requests From A Simple File

=head1 METHODS

=head2 new

Creates a new instance.

=head2 get_requests

Opens the filename specified in the config file, and reads each line in the
file, converting them to a simple Gungho::Request object.

=cut
