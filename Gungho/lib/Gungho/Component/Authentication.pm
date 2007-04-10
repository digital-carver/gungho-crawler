

package Gungho::Component::Authentication;
use strict;
use warnings;
use base qw(Gungho::Component);
use Carp qw(croak);
use HTTP::Status();
use HTTP::Headers::Util();

sub inject_base
{
    my $class = shift;
    my $c     = shift;

    $c->features->{ $class->can('feature_name') ?
        $class->feature_name : 
        do {
            my $name = $class;
            $name =~ s/^Gungho::Component:://;
            $name;
        }
    }++;
    $class->next::method($c, @_);
}

sub authenticate
{
    croak ref($_[0]) . "::authenticate() unimplemented";
}

sub check_authentication_challenge
{
    my ($c, $req, $res) = @_;

    my $handled = 0;

    # Check if there was a Auth challenge. If yes and Gungho is configured
    # to support authentication, then do the auth magic
    my $code = $res->code;

    if ( $code == &HTTP::Status::RC_UNAUTHORIZED ||
         $code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED )
    {
        my $proxy = ($code == &HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
        my $ch_header = $proxy ? "Proxy-Authenticate" : "WWW-Authenticate";
        my @challenge = $res->header($ch_header);

        if (! @challenge) {
            $c->log->debug("Response from " . $req->uri . " returned with code = $code, but is missing Authenticate header");
            $res->header("Client-Warning" => "Missing Authenticate header");
            goto DONE;
        }
CHALLENGE:
        for my $challenge (@challenge) {
            $challenge =~ tr/,/;/; # "," is used to separate auth-params!!
            ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
            my $scheme = lc(shift(@$challenge));
            shift(@$challenge); # no value 
            $challenge = { @$challenge };  # make rest into a hash
            for (keys %$challenge) {       # make sure all keys are lower case
                $challenge->{lc $_} = delete $challenge->{$_};
            }

            unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
                $c->log->debug("Response from " . $req->uri . " returned with code = $code, bad authentication scheme '$scheme'");
                $res->header("Client-Warning" => "Bad authentication scheme '$scheme'");
                goto DONE;
            }
            $scheme = ucfirst $1;  # untainted now

            if (! $c->has_feature("Authentication::$scheme")) {
                $c->log->debug("Response from " . $req->uri . " returned with code = $code, but authentication scheme '$scheme' is unsupported");
                goto DONE;
            }

            # now attempt to authenticate
            return $c->authenticate($proxy, $challenge, $req, $res);
        }
    }

DONE:
    return $handled;
}

1;
