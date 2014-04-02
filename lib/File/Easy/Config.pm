=head1 NAME

File::Easy::Config - Config files made easy

=head1 DESCRIPTION

Structured configuration files, with easy loading, and optional saving.

=head1 USAGE

  my $config = File::Easy::Config->new($filename, rw=>1);
  my $setting = $config->get('key');
  $config->set('key', $perl_structure);
  $config->save;

=cut

package File::Easy::Config;

use v5.12;
use Moo;
use utf8::all;
use JSON 2.0;
use Carp;

=head1 PUBLIC METHODS

=over 1

=item new(filename => $filename, ...)

Takes a filename, and a few select options, and returns a File::Easy::Config
object representing the config file.

  my $config = File::Easy::Config->new(filename => $filename);

The 'filename' parameter is required.

Recognized options:

  ro      => 1         Disable the ability to use set().
  rw      => 1         Enable the ability to use save().
  compact => 1         Don't use pretty formatting when saving.

As may be obvious, 'ro' and 'rw' are mutually exclusive, and 'ro' will
override 'rw' if both are set.

The 'compact' setting only works on certain configuration formats, such as
JSON. In other formats such as YAML, it has no effect.

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

has 'format' =>
(
  is => 'rw',
);

has 'plugins' =>
(
  is      => 'ro',
  default => sub
  {
    [
      {
        test  => qr/\.jso?n$/,
        class => 'File::Easy::Config::JSON',
      },
      {
        test  => qr/\.ya?ml$/,
        class => 'File::Easy::Config::YAML',
      }
    ]
  },
);

sub add_plugin
{
  my ($self, $test, $plugin) = @_;
  my $pdef =
  {
    test  => $test,
    class => $plugin,
  };
  push @{$self->{plugins}}, $pdef;
}

sub load
{
  my ($self, $filename) = @_;
  for my $plugin (@{$self->plugins})
  {
    if ($filename =~ $plugin->{test})
    {
      my $class = $plugin->{class};
      eval "require $class";
      if ($@)
      {
        croak "Could not load plugin '$class': $@";
      }
      $self->format($class);
      return $class->load($filename);
    }
  }
  croak "No plugin could be found to load '$filename'.";
}

sub _build_data
{
  my ($self) = @_;
  return $self->load($self->filename);
}

=item get($query, ...)

Looks to see if a namespace exists in the config, and if it does, returns it.
If it doesn't, what it does depends on the options sent. If no options
were set, returns the undefined result.

  my $value = $config->get($query, default => "blah");

Nested namespaces are supported by using a dotted syntax, so for instance:

  $config->get("companies.acme.users.0.name");

  Could translate into:

  $config->data->{companies}->{acme}->{users}->[0]->{name};

Recognized options:

  default  => $value      If no key is found, returns this.
  required => 1           If no key is found, die with a fatal error.

If you pass an array reference of queries, they will be searched for in order.

=cut

sub get
{
  my ($self, $query, %opts) = @_;

  my $notfound = sub
  {
    my ($key, %opts) = @_;
    if (exists $opts{default})
    {
      return $opts{default};
    }
    elsif ($opts{required})
    {
      croak "Required value '$key' not found in config.";
    }
    else 
    { 
      return; 
    }
  };

  if (ref $query eq 'ARRAY')
  {
    for my $subquery (@$query)
    {
      my $subval = $self->get($subquery);
      if (defined $subval)
      {
        return $subval;
      }
    }
    return $notfound->(join(' | ', @$query), %opts);
  }

  my @keyspace = split(/\./, $query);
  my $data = $self->data;
  for my $key (@keyspace)
  {
    my $dt = ref $data;
    if ($dt eq 'HASH' && exists $data->{$key})
    {
      $data = $data->{$key};
    }
    elsif ($dt eq 'ARRAY' && exists $data->[$key])
    {
      $data = $data->[$key];
    }
    else
    {
      return $notfound->($key, %opts);
    }
  }
  return $data;
}

=item set($key, $value);

Sets the given key in the config to the given value. The value must be able
to be serialized into the configuration format.

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

  my $class = $self->format || croak "No format set, cannot save.";
  $class->save($self->filename, $self->data, compact => $self->compact);
}

## End of methods

=back

=head1 DEPENDENCIES

Perl 5.12 or higher

JSON 2.0 or higher (with JSON::XS preferably.)
YAML 0.90 or higher (with YAML::XS preferably.)

=head1 BUGS AND LIMITATIONS

The set() method does not support nested namespaces yet.

We could use more data format plugins.

=head1 AUTHOR

Timothy Totten <2010@huri.net>

=head1 LICENSE

Artistic License 2.0

=cut

## End of package.
1;
