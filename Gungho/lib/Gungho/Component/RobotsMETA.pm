# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::RobotsMETA;
use strict;
use warnings;
use base qw(Gungho::Component);
use HTML::RobotsMETA;

__PACKAGE__->mk_classdata($_) for qw(robots_meta);

sub setup
{
    my $self = shift;
    $self->next::method(@_);
    $self->robots_meta( HTML::RobotsMETA->new );
}

sub handle_response
{
    my ($self, $req, $res) = @_;

    if ($res->is_success && $res->content_type =~ m{^text/html}i) {
        eval {
            my $rules = $self->robots_meta->parse_rules( $res->content );
            $res->notes( robots_meta => $rules );
        };
        if ($@) {
            $self->log->debug("Failed to parse " . $res->request->uri . " for robots META information: $@");
        }
    }
    $self->next::method($req, $res);
}

1;

__END__

=head1 NAME

Gungho::Component::RobotsMETA - Automatically Parse Robots META

=head1 SYNOPSIS

  components:
    - RobotsMETA

=head1 DESCRIPTION

This module automatically parses any text/html document for robots exclusion
directies embedded in the document.

=head1 METHODS

=head2 setup

=head2 handle_response

=cut
