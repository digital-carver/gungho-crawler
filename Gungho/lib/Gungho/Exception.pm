# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Exception;
use strict;
use warnings;
use Exception::Class
    'Gungho::Exception',
    map {
        ($_ => { isa => 'Gungho::Exception' })
    } qw(
        Gungho::Exception::RequestThrottled
        Gungho::Exception::SendRequest::Handled
        Gungho::Exception::HandleResponse::Handled
    )
;

1;

__END__

=head1 NAME

Gungho::Exception - Gungho Exceptions

=cut
