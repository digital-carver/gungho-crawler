use strict;
use inc::Module::Install;

name("Gungho");
all_from("lib/Gungho.pm");

requires("Class::Accessor::Fast");
requires("Class::C3");
requires("Class::Inspector");
requires("Config::Any");
requires("Data::Dump");
requires("Exception::Class");
requires("FindBin");
requires("Getopt::Long");
requires("Pod::Usage");
requires("Regexp::Common");
requires("Storable");
requires("UNIVERSAL::isa");
requires("UNIVERSAL::require");

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
    die "Failed to load deps! : $@";
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
    die "Failed to load tests! : $@";
}

tests join(' ', @tests);
auto_install;
WriteAll;
