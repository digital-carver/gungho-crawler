# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::RobotRules;
use strict;
use warnings;
use base qw(Gungho::Component);
use Gungho::Component::RobotRules::Rule;
use WWW::RobotRules::Parser;

__PACKAGE__->mk_classdata($_) for qw(pending_robots_txt robot_rules_parser robot_rules_storage);

sub setup
{
    my $c = shift;
    $c->pending_robots_txt({});
    $c->setup_robot_rules_storage();
    $c->setup_robot_rules_parser();
    $c->next::method(@_);
}

sub send_request
{
    my ($c, $request) = @_;

    my $allowed = 
        $request->uri->path eq '/robots.txt' ||
        $c->allowed($request)
    ;
    if ($allowed == -2) {
        $c->log->debug("Fetch for /robots.txt already scheduled for " . $request->uri->host_port);
        Gungho::Exception::SendRequest::Handled->throw;
    } elsif ($allowed == -1) {
        $c->log->debug("No robot rules found for " . $request->uri->host_port . ", going to fetch one");
        Gungho::Exception::SendRequest::Handled->throw;
    } elsif ($allowed) {
        $c->maybe::next::method($request);
    } else {
        $c->log->debug($request->uri . " is disallowed by robot rules");
        Gungho::Exception::SendRequest::Handled->throw;
    }
}

sub allowed
{
    my ($c, $request) = @_;

    my $rule = $c->robot_rules_storage->get_rule( $c, $request );
    if (! $rule) {
        if ($c->push_pending_robots_txt($request) == 0) {
            return -2;
        }

        my $uri = $request->original_uri;
        $uri->path('/robots.txt');
        $uri->query(undef);
        $uri->fragment(undef);
        my $req = Gungho::Request->new(GET => $uri);
        $req->notes('auto_robot_rules' => 1);
        $c->provider->pushback_request( $c, $req );
        return -1;
    } else {
        return $rule->allowed( $c, $request->uri );
    }
}

sub handle_response
{
    my $c = shift;
    my ($request, $response) = @_;

    if ($request->uri->path eq '/robots.txt' && $request->notes('auto_robot_rules')) {
        $c->log->debug("Handling robots.txt response for " . $request->uri->path);
        $c->parse_robot_rules($request, $response);
        $c->dispatch_pending_robots_txt($request);
        Gungho::Exception::HandleResponse::Handled->throw;
    }

    $c->maybe::next::method(@_);
}

sub push_pending_robots_txt
{
    my ($c, $request) = @_;

    my $uri = $request->original_uri;
    my $h = $c->pending_robots_txt->{ $uri->host_port };
    if (! $h) {
        $h = {};
        $c->pending_robots_txt->{ $uri->host_port } = $h;
    }

    if(! exists $h->{ $request->id }) {
        $c->log->debug("Pushing request " . $request->uri . " to pending list (robot rules)...");
        $h->{ $request->id } = $request ;
        return 1;
    }
    return 0;
}

sub dispatch_pending_robots_txt
{
    my ($c, $request) = @_;

    my $uri = $request->original_uri;
    my $pending = delete $c->pending_robots_txt->{ $uri->host_port };
    if ($pending && ref $pending eq 'HASH') {
        $c->provider->pushback_request( $c, $_ ) for values %$pending;
    }
}

sub setup_robot_rules_storage
{
    my $c = shift;

    my $config = $c->config->{robotrules}{storage} || {};

    my $pkg = $config->{module} || 'RobotRules::Storage::DB_File';
    my $pkg_config = $config->{config} || {};
    $pkg = $c->load_gungho_module($pkg, 'Component');
    my $storage = $pkg->new(%$config);
    $storage->setup($c);
    $c->robot_rules_storage( $storage );
}

sub setup_robot_rules_parser
{
    my $c = shift;

    my $config = $c->config->{robotrules}{parser} || {};

    my $pkg = $config->{module} || '+WWW::RobotRules::Parser';
    my $pkg_config = $config->{config} || {};
    $pkg = $c->load_gungho_module($pkg, 'Component');
    my $parser = $pkg->new($config);
    $c->robot_rules_parser( $parser );
}

sub parse_robot_rules
{
    my ($c, $request, $response) = @_;

    my $h = ($request && $response && $response->is_success && $response->content) ?
        $c->robot_rules_parser->parse($request->original_uri, $response->content) :
        {}
    ;
    $c->log->debug("Parse robot rules " . $request->uri . ": " . keys(%$h) . " rules");
    my $rule = Gungho::Component::RobotRules::Rule->new($h);
    $c->robot_rules_storage->put_rule($c, $request, $rule);
}

1;

=head1 NAME

Gungho::Component::RobotRules - Respect robots.txt

=head1 SYNOPSIS

  ---
  components:
    - RobotRules

=head1 METHODS

=head2 setup

=head2 setup_robot_rules_parser

=head2 setup_robot_rules_storage

=head2 handle_response

=head2 send_request

=head2 allowed($request)

Returns 1 if request is allowed to be fetched, 0 if not. -1 and -2 are returned
when there is a pending request to fetch /robots.txt

=head2 dispatch_pending_robots_txt

Dispatches requests that were pending because of a missing robots.txt entry

=head2 push_pending_robots_txt

Pushes a request in the wait queue for a robots.txt

=head2 parse_robot_rules

Parses the robot rule and stores it

=cut