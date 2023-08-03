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
    my %deformats = (hash => sub { $def->list_from_hash(@_) if $def->is_hash(@_) } );

    bless { def => $def, format => \%formats, deformat => \%deformats, convert => {} };
}

sub name       { uc $_[0]{'def'}->name }
sub dimensions { $_[0]{'def'}->count }
sub iterator   { $_[0]{'def'}->iterator }
sub is_format  { (defined $_[1] and exists $_[0]{'format'}{ $_[1] }) ? 1 : 0 }

sub add_format { # @rgb --> $val
    my ($self, $name, $code) = @_;
    return if ref $name or ref $code ne 'CODE' or exists $self->{'format'}{$name};
    $self->{'format'}{$name} = $code;
}
sub format {
    my ($self, $values, $format) = @_;
    return unless $self->{'def'}->is_array( $values );
    $format //= 'list';
    $self->{'format'}{ $format }->(@$values) if exists $self->{'format'}{ $format };
}

sub add_deformater {
    my ($self, $name, $code) = @_;
    return if ref $name or ref $code ne 'CODE' or exists $self->{'deformat'}{$name};
    $self->{'deformat'}{$name} = $code;
}
sub deformat {
    my ($self, $values) = @_;
    return unless defined $values;
    for my $deformater (values %{$self->{'deformat'}}){
        my @values = $deformater->($values);
        return @values if @values == $self->dimensions;
    }
    return undef;
}

sub add_converter {
    my ($self, $name, $from_code, $to_code) = @_;
    return if ref $name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE'
        or exists $self->{'convert'}{$name};
    $self->{'convert'}{$name} = {from => $from_code, to => $to_code };
}
sub convert {
    my ($self, $values, $space) = @_;
    return unless $self->{'def'}->is_array( $values ) or not exists $self->{'convert'}{ $space };
    $self->{'convert'}{ $space }{'to'}->(@$values);
}

sub deconvert {
    my ($self, $values, $space) = @_;
    return unless $self->{'def'}->is_array( $values ) or not exists $self->{'convert'}{ $space };
    $self->{'convert'}{ $space }{'from'}->(@$values);
}

1;
