#!/usr/bin/perl

use v5.12;
use strict;
use warnings;
use Test::More;

use lib './lib';

BEGIN { use_ok('File::Easy::Slurp', qw(slurp lines catfile savefile)); }

my $filen1 = "./t/test1.txt";
my $filen2 = ".test1.txt";
my $filen3 = "./t/test2.txt";

my $want1 = "Hello World\nHow are you today?";
my $want2 = "This is a test";

my $text = slurp($filen1);

is $text, $want1, "slurp works"; 

my @lines = lines($filen1);

is $lines[0], "Hello World\n", "lines works";

savefile($filen2, $text);

ok -f $filen2, "save creates file";

$text = slurp($filen3);

is $text, $want2, "slurped again";

$text = catfile $filen2;

is $text, $want1, "save wrote correct data, catfile works on scalar";

@lines = ();
@lines = catfile $filen1;

is $lines[1], "How are you today?", "catfile works in array context";

## Clean up.
unlink $filen2;

done_testing();

