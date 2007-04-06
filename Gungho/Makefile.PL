use strict;
use inc::Module::Install;

name("Gungho");
all_from("lib/Gungho.pm");

requires("Class::Accessor::Fast");
requires("Class::C3");
requires("Config::Any");
requires("UNIVERSAL::require");

features(
    "POE Engine" => [
        -default => 0,
        recommends('POE'),
        recommends('POE::Component::Client::HTTP')
    ]
);

auto_install;
WriteAll;
