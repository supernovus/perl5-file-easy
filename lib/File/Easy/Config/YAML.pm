package File::Easy::Config::YAML;

use v5.12;
use strict;
use warnings;
use utf8::all;
use YAML::Any qw(LoadFile DumpFile);

sub load
{
  my ($self, $filename) = @_;
  if (!-f $filename) { return; }
  return LoadFile($filename);
}

sub save
{
  my ($self, $filename, $content, %opts) = @_;
  if (!-w $filename) { return; }
  DumpFile($filename, $content);
  return 1;
}

1;
