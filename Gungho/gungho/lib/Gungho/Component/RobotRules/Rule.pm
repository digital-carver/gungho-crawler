# $Id$

package Gungho::Component::RobotRules::Rule;
use strict;
use warnings;
use base qw(Gungho::Base);
use URI;

__PACKAGE__->mk_accessors($_) for qw(rules);

sub new
{
    my $class = shift;
    my $self  = $class->next::method();
    $self->setup(@_);
    $self;
}

sub setup
{
    my $self = shift;
    my $rules = shift;
    $self->rules($rules);
}

sub allowed
{
    my $self = shift;
    my $c    = shift;
    my $uri  = shift;

    $uri = URI->new($uri) unless ref $uri;
    my $str   = $uri->path_query;
    my $rules = $self->rules;
    while (my ($key, $list) = each %$rules) {
        next unless $self->is_me($c, $key);

        foreach my $rule (@$list) {
            return 1 unless length $rule;
            return 0 if index($str, $rule) == 0;
        }
        return 1;
    }
    return 1;
}

sub is_me
{
    my $self = shift;
    my $c    = shift;
    my $name = shift;

    return index(lc($c->user_agent), lc($name)) >= 0;
}

1;

__END__

=head1 NAME

Gungho::Component::RobotRules::Rule - A Rule Object

=head1 METHODS

=head2 new

=head2 setup

=head2 allowed

=head2 is_me

=cut
