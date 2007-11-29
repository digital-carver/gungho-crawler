use strict;
use inc::Module::Install;

name("Gungho");
all_from("lib/Gungho.pm");

requires("Best");
requires("Class::Accessor::Fast");
requires("Class::C3::Componentised");
requires("Class::Data::Inheritable");
requires("Class::Inspector");
requires("Config::Any");
requires("Event::Notify", '0.00004');
requires("Exception::Class");
requires("FindBin");
requires("Getopt::Long");
requires("HTTP::Status");
requires("HTTP::Request");
requires("HTTP::Response");
requires("Log::Dispatch");
requires("Path::Class");
requires("Pod::Usage");
requires("Regexp::Common");
requires("Storable");
requires("URI");
requires("UNIVERSAL::isa", "0.06");
requires("UNIVERSAL::require");

recommends('Digest::MD5');
recommends('perl', '5.008');

build_requires('YAML');
build_requires('DirHandle');
build_requires('File::Spec');
build_requires('Test::More');
build_requires('Test::MockObject');

# Hey, stolen right off of Plagger
eval {
    require YAML;
    require DirHandle;
    require File::Spec;

    my $dh = DirHandle->new("deps");
    my @plugins;
    while (my $f = $dh->read) {
        next unless $f =~ /\.(?:yml|yaml)$/;
        my $meta = eval { YAML::LoadFile( File::Spec->catfile("deps", $f) ) };
        if ($@) {
            warn "Loading deps/$f failed: $@";
            next;
        }
        push @plugins, $meta if !$meta->{platform} || $meta->{platform} eq $^O;
    }

    for my $meta (sort { $b->{default} <=> $a->{default} || $a->{name} cmp $b->{name} } @plugins) {
        features(
            $meta->{name}, [
                -default => $meta->{default},
                map recommends($_ => $meta->{depends}->{$_}), keys %{$meta->{depends} || {}},
            ],
        );
    }
};
if ($@) {
    print STDERR <<EOM;
==============================================================================
!!! Failed to load deps for features !!!

$@
NOTE: This means that Gungho was not able to load the files in deps directory,
which contain the prerequisites for various components. If you force install,
you may encounter problems running Gungho later.

This is probably not good, but continuing anyway.
==============================================================================
EOM
}

my @tests;
eval {
    my $code;

    $code = sub {
        my $dir = shift;
        my $dh  = DirHandle->new($dir);
        while (my $f = $dh->read) {
            next if $f =~ /^\.+$/;
            my $fullpath = File::Spec->catfile($dir, $f);
            if (-d $fullpath) {
                $code->($fullpath);
            } else {
                next unless $fullpath =~ /\.t$/;
                push @tests, $fullpath;
            }
        }
    };
    $code->('t');

    @tests;
};
if ($@) {
    print STDERR <<EOM
==============================================================================
!!! Failed to load tests !!!

$@
This is probably not good, but continuing anyway.
==============================================================================
EOM
}

tests join(' ', @tests);
auto_install;
WriteAll;
