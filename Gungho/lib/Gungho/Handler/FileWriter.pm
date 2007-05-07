# $Id$
#
# Copyrigt (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler::FileWriter;
use strict;
use warnings;
use base qw(Gungho::Handler);
use Path::Class();

sub handle_response
{
    my ($self, $c, $req, $res) = @_;

    my $file = $self->path_to($req, $res);
    my $fh   = $file->openw() or die;

    $c->log->debug("Writing " . $req->uri . " to $file");

    $fh->print($res->content);
    $fh->close;
}

1;