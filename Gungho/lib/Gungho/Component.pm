# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component;
use strict;
use warnings;
use base qw(Gungho::Base);

sub inject_base
{
    my $class = shift;
    my $c     = shift;

    my $pkg = ref($c);
    {
        no strict 'refs';
        push @{ "${pkg}::ISA" }, $class;
    }
}

1;

