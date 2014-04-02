#!/usr/bin/perl

use v5.12;
use strict;
use warnings;
use Test::More;

use lib './lib';

my $class;

BEGIN { 
  $class = 'File::Easy::Config';
  use_ok($class); 
}

my $filen1 = "./t/conf1.json";
my $filen2 = "./t/conf2.yaml";

my $config = $class->new(filename => $filen1); #new_ok($class, [filename => $filen1]);

is $config->get('hello'), 'world', 'simple get()';

is $config->get('companies.acme.users.1.name'), 'Lisa', 'nested get()';

is $config->get(["goodbye", "hello"]), 'world', 'chained get()';

## TODO: test YAML config, set() and save().

done_testing();
