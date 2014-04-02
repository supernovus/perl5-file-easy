package File::Easy::Config::JSON;

use v5.12;
use strict;
use warnings;
use utf8::all;
use JSON 2.0;
use File::Easy::Slurp qw(slurp savefile);

sub load
{
  my ($self, $filename) = @_;
  if (!-f $filename) { return; }

  return decode_json(slurp($filename));
}

sub save
{
  my ($self, $filename, $content, %opts) = @_;
  my $pretty = 1;
  if ($opts{compact}) { $pretty = 0; }
  my $output = JSON->new->utf8->pretty($pretty)->encode($content);
  savefile($filename, $output);
}

1;
