
# read only store of a single color: name + values in default and original space

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

#### constructor #######################################################
sub new_from_any_input { #  values => %space_name => tuple ,   ~origin_space, ~color_name
    my ($pkg, $color_def) = @_;
    return "Can not create color value object without color definition!" unless defined $color_def;
    if (not ref $color_def) { # try to resolve color name
        my $rgb = Graphics::Toolkit::Color::Name::get_values( $color_def );
        if (ref $rgb){
            $rgb = $RGB->clamp( $RGB->normalize( $rgb ), 'normal' );
            return bless { name => $color_def, rgb => $rgb, source_values => '', source_space_name => ''};
        }
    }
    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_def );
    return "could not recognize color value format or color name: $color_def" unless ref $values;
    new_from_tuple( '', $values, $space_name);
}
sub new_from_tuple { #
    my ($pkg, $values, $space_name, $range_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    return "Need ARRAY of ".$color_space->axis_count." ".$color_space->name." values as first argument!"
        unless $color_space->is_value_tuple( $values );
    $values = $color_space->clamp( $values, $range_def);
    $values = $color_space->normalize( $values, $range_def );
    $values = $color_space->clamp( $values, 'normal');
    _new_from_normal_tuple($values, $color_space);
}
sub _new_from_normal_tuple { #
    my ($values, $color_space) = @_;
    my $source_values = '';
    my $source_space_name = '';
    if ($color_space->name ne $RGB->name){
        $source_values = $values;
        $source_space_name = $color_space->name;
        $values = Graphics::Toolkit::Color::Space::Hub::deconvert( $color_space->name, $values, 'normal' );
    }
    $values = $RGB->clamp( $values, 'normal' );
    my $name = Graphics::Toolkit::Color::Name::from_values( $RGB->round( $RGB->denormalize( $values ) ) );
    bless { rgb => $values, source_values => $source_values, source_space_name => $source_space_name, name => $name };
}

#### getter ############################################################
sub normalized { # normalized (0..1) value tuple in any color space
    my ($self, $space_name) = @_;
    Graphics::Toolkit::Color::Space::Hub::convert(
        $self->{'rgb'}, $space_name, 'normal', $self->{'source_space_name'}, $self->{'source_values'},
    );
}
sub shaped  { # in any color space, range and precision
    my ($self, $space_name, $range_def, $precision_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $values = $self->normalized( $color_space->name );
    return $values if not ref $values;
    $values = $color_space->denormalize( $values, $range_def );
    $values = $color_space->clamp( $values, $range_def );
    $values = $color_space->round( $values, $precision_def );
    return $values;
}
sub formatted { # in shape values in any format # _ -- ~space, @~|~format, @~|~range, @~|~suffix
    my ($self, $space_name, $format_name, $suffix_def, $range_def, $precision_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $values = $self->shaped( $color_space->name, $range_def, $precision_def );
    return $values unless ref $values;
    return $color_space->format( $values, $format_name, $suffix_def );
}
sub name { $_[0]->{'name'} }

#### single color calculator ###########################################
sub set { # .values, %newval -- ~space_name --> _
    my ($self, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash(
                                        $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : 'any supported color space!';
    }
    my $values = $self->shaped( $space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $values->[$pos] = $new_values->[$pos] if defined $new_values->[$pos];
    }
    $self->new_from_tuple( $values, $color_space->name );
}

sub add { # .values, %newval -- ~space_name --> _
    my ($self, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash(
                                        $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : 'any supported color space!';
    }
    my $values = $self->shaped( $space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $values->[$pos] += $new_values->[$pos] if defined $new_values->[$pos];
    }
    $self->new_from_tuple( $values, $color_space->name );
}

sub mix { #  @%(+percent, _color)  -- ~space_name --> _
    my ($self, $recipe, $color_space ) = @_;
    return if ref $recipe ne 'ARRAY';
    my $result_values = [(0) x $color_space->axis_count];
    for my $ingredient (@$recipe){
        return if ref $ingredient ne 'HASH' or not exists $ingredient->{'percent'}
               or not exists $ingredient->{'color'} or ref $ingredient->{'color'} ne __PACKAGE__;
        my $values = $ingredient->{'color'}->shaped( $color_space->name );
        $result_values->[$_] +=  $values->[$_] * $ingredient->{'percent'} / 100 for 0 .. $#$values;
    }
    $self->new_from_tuple( $result_values, $color_space->name );
}

sub invert {
    my ($self, $color_space ) = @_;
    my $values = $self->normalized( $color_space->name );
    $self->new_from_tuple( [ map {1 - $_} @$values ], $color_space->name, 'normal' );
}

1;
