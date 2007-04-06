# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Request;
use strict;
use warnings;
use base qw(HTTP::Request);

1;

__END__

=head1 NAME

Gungho::Request - A Gungho Request Object

=head1 DESCRIPTION

Currently this class is exactly the same as HTTP::Request, but we're
creating this separately in anticipation for a possible change

=cut
