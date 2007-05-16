use strict;
use Test::More;

BEGIN
{
    my @modules = qw(
        Gungho::Base
        Gungho::Component
        Gungho::Component::Authentication
        Gungho::Component::Authentication::Basic
        Gungho::Component::Authentication
        Gungho::Component::RobotRules
        Gungho::Component::RobotRules::Rule
        Gungho::Component::RobotRules::Storage
        Gungho::Component::RobotRules::Storage::DB_File
        Gungho::Component::RobotRules::Storage
        Gungho::Component::RobotRules
        Gungho::Component::Throttle
        Gungho::Component::Throttle::Domain
        Gungho::Component::Throttle::Simple
        Gungho::Component::Throttle::Throttler
        Gungho::Component::Throttle
        Gungho::Engine
        Gungho::Exception
        Gungho::Handler
        Gungho::Handler::FileWriter::Simple
        Gungho::Handler::Null
        Gungho::Inline
        Gungho::Log
        Gungho::Plugin
        Gungho::Plugin::RequestTimer
        Gungho::Provider
        Gungho::Provider::File::Simple
        Gungho::Provider::Simple
        Gungho::Provider::YAML
        Gungho::Request
        Gungho::Request::http
        Gungho
    );
    
    plan tests => scalar @modules;
    use_ok($_) for @modules;
}

1;