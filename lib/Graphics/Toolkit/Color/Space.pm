use v5.12;
use warnings;

# base logic of every color space

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::SpaceKeys;

sub new {
    my $pkg = shift;
    my $def = Graphics::Toolkit::Color::SpaceKeys->new( @_ );
    return unless ref $def;

    # which formats the constructor will accept, that can be deconverted into list
    my %deformats = (hash => sub { $def->list_from_hash(@_) if $def->is_hash(@_) } );
    # which formats we can output
    my %formats = (list => sub {@_}, hash => sub { $def->key_hash_from_list(@_) },
                                char_hash => sub { $def->shortcut_hash_from_list(@_) },
                   map( { $_ => eval 'sub {$_['.$def->key_pos($_).']}' } $def->keys ),
                   map( { $_ => eval 'sub {$_['.$def->shortcut_pos($_).']}' } $def->shortcuts ),
    );

    bless { def => $def, delta => '', format => \%formats, deformat => \%deformats, convert => {} };
}

sub name             { uc $_[0]{'def'}->name }
sub dimensions       { $_[0]{'def'}->count }
sub iterator         { $_[0]{'def'}->iterator }
sub is_array         { $_[0]{'def'}->is_array( $_[1] ) }
sub is_partial_hash  { $_[0]{'def'}->is_partial_hash( $_[1] ) }
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }


sub add_formatter {
    my ($self, $format, $code) = @_;
    return if not defined $format or ref $format or ref $code ne 'CODE';
    return if $self->has_format( $format );
    $self->{'format'}{ $format } = $code;
}
sub format {
    my ($self, $values, $format) = @_;
    return unless $self->{'def'}->is_array( $values );
    $self->{'format'}{ lc $format }->(@$values) if $self->has_format( $format );
}

sub add_deformatter {
    my ($self, $format, $code) = @_;
    return if not defined $format or ref $format or exists $self->{'deformat'}{$format} or ref $code ne 'CODE';
    $self->{'deformat'}{ lc $format } = $code;
}
sub deformat {
    my ($self, $values) = @_;
    return unless defined $values;
    for my $deformatter (values %{$self->{'deformat'}}){
        my @values = $deformatter->($values);
        return @values if @values == $self->dimensions;
    }
    return undef;
}


sub add_converter {
    my ($self, $space_name, $to_code, $from_code) = @_;
    return if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return if $self->can_convert( $space_name );
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code };
}
sub convert {
    my ($self, $values, $space_name) = @_;
    return unless $self->{'def'}->is_array( $values ) and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'to'}->(@$values) if $self->can_convert( $space_name );
}

sub deconvert {
    my ($self, $values, $space_name) = @_;
    return unless $self->{'def'}->is_array( $values ) and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'from'}->(@$values) if $self->can_convert( $space_name );
}

1;
