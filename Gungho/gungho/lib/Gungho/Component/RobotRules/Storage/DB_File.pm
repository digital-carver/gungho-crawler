# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::RobotRules::Storage::DB_File;
use strict;
use warnings;
use base qw(Gungho::Component::RobotRules::Storage);
use DB_File;
use Storable qw(nfreeze thaw);

sub setup
{
    my $self = shift;
    my $config = $self->config();
    $config->{filename} ||= File::Spec->catfile(File::Spec->tmpdir, 'robots.db');

    my %o;
    $self->storage( tie %o, 'DB_File', $config->{filename} );
    $self->next::method(@_);
}

sub get_rule
{
    my $self = shift;
    my $request = shift;
    my $v;

    my $uri = $request->original_uri;
    if ($self->storage->get( $uri->host_port, $v ) == 0) {
        return thaw($v);
    }
    return ();
}

sub put_rule
{
    my $self = shift;
    my $request = shift;
    my $rule    = shift;

    my $uri = $request->original_uri;
    $self->storage->put( $uri->host_port, nfreeze($rule) );
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Storage::DB_File - DB_File Storage For RobotRules

=head1 METHODS

=head2 setup

=head2 get_rule

=head2 put_rule

=cut
