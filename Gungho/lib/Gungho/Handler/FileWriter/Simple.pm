# $Id$
#
# Copyrigt (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler::FileWriter::Simple;
use strict;
use warnings;
use base qw(Gungho::Handler::FileWriter);
use File::Spec;
use Path::Class();
use URI::Escape qw(uri_escape);

__PACKAGE__->mk_accessors($_) for qw(dir);

sub setup
{
    my ($self, $c) = @_;

    $self->dir(
        Path::Class::Dir->new( $self->config->{dir} || File::Spec->tmpdir)
    );
    $self->next::method($c);
}

sub path_to
{
    my ($self, $req, $res) = @_;

    # Just writes to a file name that has been "properly" (for better
    # or for worse...) URl-encoded

    return $self->dir->file( uri_escape( $res->uri ) );
}

1;
