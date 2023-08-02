use v5.12;
use warnings;

# base logic of every color space

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::SpaceKeys;

sub new {
    my $pkg = shift;
    my $def = Graphics::Toolkit::Color::SpaceKeys->new( @_ );
    return unless ref $def;

    my %formats = (list => sub {@_}, hash => sub { $def->key_hash_from_list(@_) },
                                char_hash => sub { $def->shortcut_hash_from_list(@_) },
                   map( {my $p = $def->key_pos($_); $_ => eval 'sub {$_[0]['.$p.']}' } $def->keys ),
                   map( {my $p = $def->shortcut_pos($_); $_ => eval 'sub {$_[0]['.$p.']}' } $def->shortcuts ),
    );
    bless { def => $def, format => \%formats, unformat => {}, convert => {}, deconvert => {} };
}

sub name       { uc $_[0]{'def'}->name }
sub dimensions { $_[0]{'def'}->count }
sub iterator   { $_[0]{'def'}->iterator }
sub is_format  { (defined $_[1] and exists $_[0]{'format'}{ $_[1] }) ? 1 : 0 }

sub format {
    my ($self, $values, $format) = @_;
    return unless $self->{'def'}->is_array( $values );
    $format //= 'list';
    $self->{'format'}{ $format }->{ @$values } if exists $self->{'format'}{ $format };
}

sub add_format { # @rgb --> $val
    my ($self, $name, $code) = @_;
    return if ref $name or ref $code ne 'CODE' or exists $self->{'format'}{$name};
    $self->{'format'}{$name} = $code;
}

1;

__END__

format
  is
  into
  from


converter
  into
  from
