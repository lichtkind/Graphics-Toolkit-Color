
# value objects with cache of original values

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;


sub new { #  values => %space_name => tuple ,   ~origin_space, ~color_name
    my ($pkg, $color_val) = @_;
    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_val );
    return carp "could not recognize color value format" unless ref $values;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my $std_space = Graphics::Toolkit::Color::Space::Hub::base_space();
    my $self = {};
    $self->{'origin'} = $space->name;
    $values = $space->clamp( $values );
    $values = $space->normalize( $values );
    $self->{$space->name} = $values;
    $self->{$std_space->name} = $space->convert($values, $std_space->name) if $space ne $std_space;
    bless $self;
}

sub get_tuple { # get a value tuple in any color space, range and format
    my ($self, $space_name, $format_name, $range_def) = @_;
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my $std_space_name = $Graphics::Toolkit::Color::Space::Hub::base_package;
    $space_name //= $std_space_name;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my $values = (exists $self->{$space->name})
               ? $self->{$space->name}
               : $space->deconvert( $self->{$std_space_name}, $std_space_name);
    $values = $space->denormalize( $values, $range_def);
    Graphics::Toolkit::Color::Space::Hub::format( $values, $space_name, $format_name);
}
sub get_name { $_[0]->get( $_[0]->{'origin'}, 'string' ) }
sub string   { $_[0]->get( $_[0]->{'origin'}, 'string' ) }

########################################################################

sub set { # %val --> _
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $val_hash );
    return carp 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my @values = $self->get( $space_name );
    for my $pos (keys %$pos_hash){
        $values[$pos] = $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @values]);
}

sub add { # %val --> _
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $val_hash );
    return carp 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my @values = $self->get( $space_name );
    for my $pos (keys %$pos_hash){
        $values[$pos] += $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @values]);
}

sub blend { # _c1 _c2 -- +factor ~space --> _
    my ($self, $c2, $factor, $space_name ) = @_;
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $factor //= 0.5;
    $space_name //= 'RGB';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my @values1 = $self->get( $space_name );
    my @values2 = $c2->get( $space_name );
    my @rvalues = map { ((1-$factor) * $values1[$_]) + ($factor * $values2[$_]) } 0 .. $#values1;
    __PACKAGE__->new([$space_name, @rvalues]);
}

########################################################################

sub distance { # _c1 _c2 -- ~space ~select @range --> +
    my ($self, $c2, $space_name, $select, $range) = @_;
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $space_name //= 'RGB';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    $select = $space->basis->shortcut_of_key($select) if $space->basis->is_key( $select );
    my @values1 = $self->get( $space_name, 'list', 'normal' );
    my @values2 = $c2->get( $space_name, 'list', 'normal' );
    return unless defined $values1[0] and defined $values2[0];

    my $delta = $space->delta( \@values1, \@values2 );
    $delta = $space->denormalize_range( $delta, $range);
    return unless ref $delta and @$delta == $space->dimensions;

    # grep values for individual select / subspace distance
    if (defined $select and $select){
        my @components = split( '', $select );
        my $pos = $space->basis->key_pos( $select );
        @components = defined( $pos )
                    ? ($pos)
                    : (map  { $space->basis->shortcut_pos($_) }
                       grep { defined $space->basis->shortcut_pos($_) } @components);
        return - carp "called 'distance' for select $select that does not fit color space $space_name!" unless @components;
        $delta = [ map { $delta->[$_] } @components ];
    }

    # Euclidean distance:
    my $d = 0;
    map {$d += ($_ * $_)} @$delta;
    return sqrt $d;
}

1;

