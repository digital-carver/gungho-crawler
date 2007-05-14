# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Throttle::Domain;
use strict;
use warnings;
use base qw(Gungho::Component::Throttle::Throttler);

__PACKAGE__->mk_accessors($_) for qw(matcher);

sub setup
{
    my $self = shift;

    my $config  = $self->config->{throttle}{domain};

    $self->prepare_throttler(
        map { ($_ => $config->{$_}) }
            qw(max_items interval db_file)
    );

    my $domains = $config->{domains} || [];
    my $matcher;
    if (! @$domains) {
        $matcher = sub { 0 };
    } else {
        my $sub = <<EOSUB;
sub {
    my \$request = shift;
    my \$url     = \$request->url;
    my \$host    = \$url->host;
EOSUB

        foreach my $d (@$domains) {
            if (my $re = $d->{match}) {
                # protect ourselves from "/"
                $re =~ s/\//\\\//g;
                $sub .= "    (\$host =~ /$re/) and return 1;\n";
            }
        }
        $sub .= "\nreturn 0;\n}";

        $matcher = eval $sub or die;
    }
    $self->matcher($matcher);

    $self->next::method(@_);
}

sub throttle
{
    my $self = shift;
    my $request = shift;

    my $do_throttle = 1;
    my $code = $self->matcher;
    if ($code) {
        $do_throtle = $code->($request);
    }

    if ($do_throttle) {
        $t->try_push(key => $request->url->host);
    }
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle::Domain - Throttle By Domain

=head1 SYNOPSIS

  ---
  throttle:
    domain:
      max_items 1000
      interval: 3600
      domains:
        - match: 'A [Regular]+ Exp?ression'
        - match: \.cpan\.org$
  components:
    - Throttle::Domain

=head1 DESCRIPITION

This component allows you to throttle requests by domain names.

You can specify a regular expression, in which case only the domains that 
match the particular regular expression will be throttled. Otherwise,
the hostname from each request will be used as the key to throttle

=head1 METHODS

=head2 setup

=head2 throttle($request)

Checks if a request can be executed succesfully. Returns 1 if it's ok to
execute the request.

=cut