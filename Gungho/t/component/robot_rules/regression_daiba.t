use strict;
use File::Spec;
use Test::More (tests => 4);

BEGIN
{
    use_ok("Gungho::Component::RobotRules::Storage::DB_File");
}

my $db_file = File::Spec->catfile('t', 'robots.db');
if (-f $db_file) {
    unlink $db_file;
}

my $storage = Gungho::Component::RobotRules::Storage::DB_File->new(
    config => {
        filename => $db_file
    }
);
ok($storage);
eval { $storage->setup };
ok(!$@);
ok(-f $db_file, "file exists");

undef $storage;

# unlink $db_file;