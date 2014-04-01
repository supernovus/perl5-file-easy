=head1 NAME

File::Easy::JSON - JSON Config files made easy

=head1 DESCRIPTION

Config files in JSON, with easy loading, and optional saving.

=head1 USAGE

  my $config = File::Easy::JSON->new($filename, rw=>1);
  my $setting = $config->get('key');
  $config->set('key', $perl_structure);
  $config->save;

Or, if you are only interested in the JSON object:

  my $config = File::Easy::JSON->load($filename);
  my $setting = $config->{key};

=cut

package File::Easy::JSON;

use v5.12;
use Moo;
use utf8::all;
use JSON 2.0;
use Carp;
use File::Easy::Slurp qw(slurp savefile);

use overload (
  '%{}' => 'data',
);

=head1 PUBLIC METHODS

=over 1

=item load($filename)

This is a class method, that takes a filename, and returns the JSON object
loaded from the file.

  my $json = File::Easy::JSON->load("myfile.json");

=cut

sub load
{
  my ($self, $filename) = @_;
  croak "Config file does not exist '$filename'" if !-f $filename;
  my $text = slurp($filename);
  my $json = decode_json($text);
  return $json;
}

=item new(filename => $filename, ...)

Takes a filename, and a few select options, and returns a File::Easy::JSON
object representing the config file.

  my $config = File::Easy::JSON->new(filename => $filename, rw=>1, compact=>1);

The 'filename' parameter is required.

Recognized options:

  ro      => 1         Disable the ability to use set().
  rw      => 1         Enable the ability to use save().
  compact => 1         Don't use pretty formatting when saving.

As may be obvious, 'ro' and 'rw' are mutually exclusive, and 'ro' will
override 'rw' if both are set.

=cut

has 'filename' =>
(
  is       => 'ro',
  required => 1,
);

has 'data' =>
(
  is => 'lazy',
);

has 'ro' =>
( 
  is      => 'ro',
  default => sub { 0; },
);

has 'rw' =>
(
  is      => 'ro',
  default => sub { 0; },
);

has 'compact' =>
(
  is      => 'ro',
  default => sub { 0; },
);

sub _build_data
{
  my ($self) = @_;
  return $self->load($self->filename);
}

=item has($key)

Returns 1 if the key exists, or 0 if it does not.

=cut

sub has
{
  my ($self, $key) = @_;
  return exists $self->data->{$key};
}

=item get($key, ...)

Looks to see if a key exists in the config, and if it does, returns it.
If it doesn't, what it does depends on the options sent. If no options
were set, returns the undefined result.

  my $value = $config->get($key, default => "blah");

Recognized options:

  default  => $value      If no key is found, returns this.
  required => 1           If no key is found, die with a fatal error.

=cut

sub get
{
  my ($self, $key, %opts) = @_;
  if (exists $self->data->{$key})
  {
    return $self->data->{$key};
  }
  else
  {
    if (exists $opts{default})
    {
      return $opts{default};
    }
    elsif ($opts{required})
    {
      croak "Required value '$key' not found in config.";
    }
    else { return; }
  }
}

=item set($key, $value);

Sets the given key in the config to the given value. The value must be able
to be serialized into JSON.

  $config->set('name', "John Smith");

=cut

sub set
{
  my ($self, $key, $value) = @_;
  if ($self->ro) { croak "Attempt to change readonly config."; }
  $self->data->{$key} = $value;
}

=item save()

Saves back to the original file. Only available if 'rw' is enabled.

=cut

sub save
{
  my ($self) = @_;
  if ($self->ro || !$self->rw)
  {
    croak "Attempt to save file without 'rw' mode enabled.";
  }
  my $pretty = 1; ## Default to pretty output.
  if ($self->compact) { $pretty = 0; } ## Unless otherwise specified.
  my $text = JSON->new->utf8->pretty($pretty)->encode($self->data);
  savefile($filename, $text);
}

## End of methods

=back

=head1 DEPENDENCIES

Perl 5.12 or higher

JSON 2.0 or higher (with JSON::XS preferably.)

=head1 BUGS AND LIMITATIONS

The get() implementation in this only supports a single key name, there is
currently no nested queries supported.

=head1 AUTHOR

Timothy Totten <2010@huri.net>

=head1 LICENSE

Artistic License 2.0

=cut

## End of package.
1;
