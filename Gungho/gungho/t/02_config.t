use strict;
use Test::More qw(no_plan);

BEGIN
{
    use_ok("Gungho");
}

my $config = Gungho->load_config("t/data/02_config/yaml.yml");

is_deeply($config, { foo => 1 });