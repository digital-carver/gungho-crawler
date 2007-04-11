
package Gungho::Component::Throttle;
use strict;
use warnings;
use base qw(Gungho::Component);

sub feature_name { 'Throttle' }
sub throttle { 1 }

1;

__END__

=head1 NAME

Gungho::Component::Throttle - Base Class To Throttle Requests

=head1 SYNOPSIS

  package Gungho::Component::Throttle::Domain;
  use base qw(Gungho::Component::Throttle);

=head1 METHODS

=head2 feature_name

=head2 throttle

=cut