# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved

package Gungho::Util;
use strict;
use warnings;
use Class::Inspector;
use UNIVERSAL::require;

sub load_module
{
    my $pkg    = shift;
    my $prefix = shift;

    unless ($pkg =~ s/^\+//) {
        $pkg = ($prefix ? "${prefix}::${pkg}" : $pkg);
    }

    Class::Inspector->loaded($pkg) or $pkg->require or die;
    return $pkg;
}

1;

__END__

=head1 NAME

Gungho::Util - Gungho General Utilities

=head1 SYNOPSIS

  use Gungho::Util;
  Gungho::Util::load_module('My::Module', 'Prefix::Namespace');
  Gungho::Util::load_module('+My::Module');

=head1 METHODS

=head2 load_module

Loads a module

=cut
