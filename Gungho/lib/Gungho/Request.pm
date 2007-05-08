# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Request;
use strict;
use warnings;
use base qw(HTTP::Request);
use Storable qw(dclone);
use UNIVERSAL::require;

our $DIGEST;

sub _find_digest_class
{
    $DIGEST ||= do {
        my $pkg;
        foreach my $x qw(SHA1 MD5) {
            my $candidate = "Digest::$x";
            if ($candidate->require()) {
                $pkg = $candidate;
                last;
            }
        }
        $pkg;
    };
}

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{_notes} = {};
    return $self;
}

sub id
{
    my $self = shift;

    local $@ = undef;
    $self->{_id} ||= do {
        my $pkg    = _find_digest_class() || die "Could not find Digest class";
        my $digest = $pkg->new;

        $digest->add(map { defined $_ ? $_ : '' } (time(), {}, rand(), $self->method, $self->uri, $self->protocol));
        $self->headers->scan(sub {
            $digest->add(join(':', $_[0], $_[1]));
        });
        $digest->hexdigest;
    };
    die $@ if $@;
    $self->{_id};
}

sub clone
{
    my $self  = shift;
    my $clone = $self->SUPER::clone;
    $clone->notes( dclone $self->notes );
    return $clone;
}

sub notes
{
    my $self = shift;
    my $key  = shift;

    return $self->{_notes} unless $key;

    my $value = $self->{_notes}{$key};
    if (@_) {
        $self->{_notes}{$key} = $_[0];
    }
    return $value;
}

sub requires_name_lookup
{
    my $self = shift;
    return $self->uri->host() !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
}

sub format
{
    my $self   = shift;
    my $scheme = $self->uri->scheme;
    my $pkg    = "Gungho::Request::$scheme";

    require Class::Inspector;
    Class::Inspector->loaded($pkg) or $pkg->require or die;

    my $protocol = $pkg->new;
    $protocol->format($self);
}

1;

__END__

=head1 NAME

Gungho::Request - A Gungho Request Object

=head1 DESCRIPTION

Currently this class is exactly the same as HTTP::Request, but we're
creating this separately in anticipation for a possible change

=head1 METHODS

=head2 new()

Creates a new Gungho::Request instance

=head2 id()

Returns a Unique ID for this request

=head2 clone()

Clones the request.

=head2 notes($key[, $value])

Associate arbitrary notes to the request

=head2 format

Formats the request so that it's appropriate to send through a socket.

=cut
