# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider::YAML;
use strict;
use warnings;
use base qw(Gungho::Provider);
use Best [
    [ qw(YAML::Syck YAML) ],
    qw(LoadFile)
];

__PACKAGE__->mk_accessors($_) for qw(read_done requests);

sub new
{
    my $class = shift;
    my $self = $class->next::method(@_);

    $self->has_requests(1);
    $self->read_done(0);
    $self->requests([]);
    $self;
}

sub pushback_request
{
    my ($self, $c, $req) = @_;

    my $list = $self->requests;
    push @$list, $req;
    $self->has_requests(1);
}

sub dispatch
{
    my ($self, $c) = @_;

    if (! $self->read_done) {
        my $filename = $self->config->{filename};
        die "No file specified" unless $filename;

        my $config = eval { LoadFile($filename) };
        if ($@ || !$config) {
            die "Could not read YAML file $filename: $@";
        }

        foreach my $conf (@{ $config->{requests} || []}) {
            my $req = Gungho::Request->new(
                $conf->{method} || 'GET',
                $conf->{url}
            );

            my($name, $value);
            while (($name, $value) = keys %{ $conf->{headers} || {} }) {
                $req->push_header($name, $value);
            }

            while (($name, $value) = each %$conf) {
                next if $name =~ /^(?:method|url|headers)$/;
                if (my $code = $req->can($name)) {
                    $code->($req, $value);
                }
            }

            $req = $c->prepare_request($req);

print $req->as_string;
            $self->pushback_request($c, $req);
        }
        $self->read_done(1)
    }

    my $requests = $self->requests;
    $self->requests([]);
    while (@$requests) {
        $self->dispatch_request($c, shift @$requests);
    }

    if (scalar @{ $self->requests } <= 0) {
        $c->is_running(0);
    }
}

1;

__END__

=head1 NAME 

Gungho::Provider::YAML - Specify requests in YAML format

=head1 SYNOPSIS

  # config.yml
  ---
  provider:
    module: YAML
    config: 
      filename: url.yml

  # url.yml
  ---
  requests:
    - method: POST
      url: http://example.com/post/to/me
      headers:
        X-MyHeader: foo
        Host: hoge
      content:
    - url: http://example.com/get/me

=cut