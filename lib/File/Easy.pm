=head1 NAME

File::Easy - A simple object representing a file.

=head1 DESCRIPTION

A file object that you can manipulate in different ways.
Useful for logs, etc.

=head1 USAGE

  use File::Easy;

  my $motd = File::Easy->load('/etc/motd');
  
  print $motd; ## Use the file in string context.

  while (@$motd) { ... } ## Use the file as an array.

  $$motd =~ s/Debian/Ubuntu/g; ## Modify the text, requires ${} context.

  $motd .= "Another line added\n"; ## Append to the text.

  $motd *= 'New Text'; ## Override the text entirely.

  $mods += "New line"; ## Adds a new line, with smart newlines.

  $motd->save;  ## Save it back to '/etc/motd'

=cut

package File::Easy;

use v5.12;
use Moo;
use utf8::all;
use Carp;
use File::Easy::Slurp qw(slurp savefile);

use overload (
  '""'       => 'content',
  '@{}'      => 'to_array',
  '${}'      => 'to_ref',
  '.='       => 'append',
  '+='       => 'addline',
  '*='       => 'reset',
  'fallback' => 1,
);

#use Debug::Comments show=>'set';

=head1 PUBLIC METHODS

=over 1

=item new(filename => './newfile.txt')

Creates a new File::Easy object with the specified filename.
This does not load the file, see load() if you want to do that.

=cut

=item filename

The current filename, if any.

=cut

has 'filename' =>
(
  is => 'rw',
);

=item content

The string content, if any.

=cut

has 'content' =>
(
  is      => 'rw',
  default => '',
);

=item loaded

Will be 1 if a file has been loaded, or 0 if not.

=cut

has 'loaded' =>
(
  is      => 'rw',
  default => sub { 0; },
);

=item saved

Will be a unix timestamp if saved, or 0 if not.

=cut

has 'saved' =>
(
  is      => 'rw',
  default => sub { 0; },
);

=item load($filename, %options)

Loads an existing file. To create a new file, use new() instead.

This can be used on an existing object, or to create a new instance:

  my $file = File::Easy->load('/etc/motd');

Recognized options:

  fatal  => 1        Instead of warning, bail.
  silent => 1        Instead of warning, silently fail.
  forget => 1        Don't override our internal file name.

If you leave off all parameters, or specify the filename as '' or 0, then
it will attempt to re-load the currently loaded file (if there is no currently
loaded file, it will fail.)

=cut

sub load
{
  my $self = shift;

  if (ref $self)
  {
    my ($filename, %opts);
    if (@_)
    {
      $filename = shift;
      if (@_)
      {
        %opts = @_;
      }
    }

    if (!$filename)
    {
      my $err = "No filename found to load.";
      if ($self->filename)
      {
        $filename = $self->filename;
        $opts{forget} = 1;
      }
      elsif ($opts{fatal})
      {
        croak $err;
      }
      elsif (!$opts{silent})
      {
        carp $err;
        return $self;
      }
    }
    
    my $err = "File '$filename' does not exist.";
    if (!$opts{forget})
    {
      $self->filename($filename);
    }
    if (-f $filename && -r _ )
    {
      $self->content(slurp($filename));
      $self->loaded(1);
    }
    elsif ($opts{fatal})
    {
      croak $err;
    }
    elsif (!$opts{silent})
    {
      carp $err;
    }
    return $self;
  }
  else
  {
    return $self->new->load(@_);
  }
}

=item to_array()

This is not typically used directly, but is used by the overload pragma 
for when this object is used in an array context. Meaning:

  my @lines = @{$file};

is the same as:

  my @lines = $file->to_array();

In many cases you can use @$file instead of @{$file}, but not always.

=cut

sub to_array
{
  my $self = shift;
  my @lines = split("\n", $self->content);
  return \@lines;
}

=item to_ref()

This is not typically used directly, but is used by the overload pragma
for when this object is used in a referencial scalar context. Thus:

  ${$file} =~ s/Debian/Ubuntu/g;

is the same as doing:

  my $ref = $file->to_ref();
  $ref =~ s/Debian/Ubuntu/g;

Both of which are nicer than if you were to skip references entirely:

  my $text = $file->content;
  $text =~ s/Debian/Ubuntu/g;
  $file->set($text);

I know which of the above I'd prefer to use. In many cases you can use
$$file instead of ${$file}, but not always.

=cut

sub to_ref
{
  my $self = shift;
  return \$self->{content};
}

=item append()

Not typically used directly, this is used by the overload pragma when
the .= assignment has been called.

So for instance:

  $file .= "Hi there";

is equivilent to:

  $$file .= "Hi there";

I know, a small change, but hey, why not eh?

=cut

sub append
{
  my ($self, $append) = @_;
  $self->{content} .= $append;
  return $self;
}

=item addline()

Not typically used directly, this is used by the overload proagma when
the += assignment has been called. It is similar to append, but deals with
adding appropriate newline characters to ensure the text to be appended is
added as its own line (and ends in a newline.)

  $file += "A new line of text to add.";

=cut

sub addline
{
  my ($self, $append) = @_;
  if ($self->content !~ /\n$/)
  {
    $self->{content} .= "\n";
  }
  if ($append !~ /\n$/)
  {
    $append .= "\n";
  }
  $self->{content} .= $append;
  return $self;
}

=item set()

Sets the content of the file. Typically you would pass a string, but
you can also pass an array (but not an array reference.)

If the first parameter is a hash reference, it can be used to set options.

Recognized options:

  delimiter => $what      Specify what to join lines with (default is '')
  separator => $what      Alias for 'delimiter'.

Usage:

  $file->set($string);  ## Set the contents to a string.
  $file->set(@array);   ## Set the contents to an array, joined by ''.

  $file->set({delimiter=>"\n"}, @array); ## Array, joined by newlines.

=cut

sub set
{
  my $self = shift;
  my $args = ( ref $_[0] eq 'HASH' ) ? shift : {} ;
  ##[set]= @_
  my $delim = '';
  
  if ($args->{'delimiter'})
  {
    $delim = $args->{'delimiter'};
  }
  elsif ($args->{'seperator'})
  {
    $delim = $args->{'seperator'};
  }
  $self->{content} = join($delim, @_);
  return $self;
}

=item reset()

Not generally used directly, this is a wrapper for set() that gets called
if you use the *= operator on the object. Unlike set, this accepts only a
single scalar string value.

  $file *= "Text to set";

=cut

sub reset
{
  my ($self, $text) = @_;
  return $self->set($text);
}

=item cat()

A wrapper around set() that takes no options, and automatically sets
the 'delimiter' option to "\n" (newline.)

  $file->cat(@lines);

=cut

sub cat
{
  my $self = shift;
  return $self->set( {delimiter=>"\n"}, @_ );
}

=item save()

Saves the content back into the file. If used with no parameters, it saves
the file back with the original filename. If a parameter is passed, that will
be used as the new filename (and remembered for future 'save' calls.)

  $file->save;                ## Saves back to the original filename.
  $file->save('newname.txt'); ## Saves to a new filename.

Recognized options:

  forget => 1         Don't remember the new filename.
  fatal  => 1         Die if no filename, or inability to save.
  silent => 1         Don't issue any warnings, just silently fail.

=cut

sub save
{
  my ($self, $filename, %opts) = @_;
  my $err = "No filename for File::Easy::save()";
  if ($filename)
  {
    if (!$opts{forget})
    {
      $self->filename($filename);
    }
  }
  elsif ($self->filename)
  {
    $filename = $self->filename;
  }
  elsif ($opts{fatal})
  {
    croak $err;
  }
  elsif (!$opts{silent})
  {
    carp $err;
    return $self;
  }

  $err = "Couldn't save to '$filename'";
  my $saved = savefile($filename, $self->content);
  if ($saved)
  {
    $self->saved(time);
  }
  elsif ($opts{fatal})
  {
    croak $err;
  }
  elsif (!$opts{silent})
  {
    carp $err;
  }
  return $self;
}

=back

=head1 DEPENDENCIES

Perl 5.12 or higher

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

=head1 AUTHOR

Timothy Totten <2010@huri.net>

=head1 LICENSE

Artistic License 2.0

=cut

## End of package.
1;