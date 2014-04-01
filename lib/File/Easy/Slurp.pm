package File::Easy::Slurp;

use v5.12;
use strict;
use warnings;
use parent qw(Exporter);
use utf8::all;

our @EXPORT_OK = qw(slurp lines catfile savefile);
our @EXPORT    = qw(slurp);

sub slurp
{
  my $filename = shift;
  my $text = do { local( @ARGV, $/ ) = $filename ; <> };
  return $text;
}

sub lines
{
  my $filename = shift;
  open (my $file, $filename);
  my @lines = <$file>;
  close $file;
  return @lines;
}

sub catfile
{
  if (wantarray)
  {
    return lines(@_);
  }
  else
  {
    return slurp(@_);
  }
}

sub savefile
{
  my $opts = ( ref $_[0] eq 'HASH' ) ? shift : {} ;
  my $filename = shift;
  my $mode = '>';
  if ($opts->{append}) { $mode = '>>'; }
  
  open (my $file, $mode, $filename)
    or return 0;

  print $file @_;
  close $file;
  return 1;
}

1;
