#!/usr/bin/perl

use v5.12;
use strict;
use warnings;
use Test::More;

use lib './lib';

my $class = "File::Easy";

my $filen1 = ".test1.txt";     ## One we'll generate.
my $filen2 = "./t/test2.txt";  ## One we'll load.

require_ok $class;

my $file = new_ok($class => [filename => $filen1]);

my $str1 = "Hello";
my $str2 = " World";
my $str3 = "How are you today?";

$file *= $str1;
is $file->content, $str1, "Override works";
$file .= " World";
is $file->content, $str1.$str2, "Append works";
$file += "How are you today?";
my $testr = $str1.$str2."\n$str3\n";
is $file->content, $testr, "Add line works";

#FIXME: stringify is broken.
#is "$file", $testr, "stringify works";

$$file =~ s/World/Universe/g;
$testr =~ s/World/Universe/g;

is $file->content, $testr, "Reference works";

$file->save;

ok -f $file->filename, "save creates file";

$file->load($filen2);

is $file->content, "This is a test", "load works";

$file->load($filen1);

is $file->content, $testr, "save saves correct data";

## Cleanup.
unlink $filen1;

done_testing();

