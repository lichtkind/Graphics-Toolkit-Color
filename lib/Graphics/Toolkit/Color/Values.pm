
# read only store of values for a single color in RGB, original space and name

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

sub new_from_any_input { #  values => %space_name => tuple ,   ~origin_space, ~color_name
    my ($pkg, $color_def) = @_;
    return "Can not create color value object without color definition!" unless defined $color_def;
    if (not ref $color_def) { # try to resolve color name
        my $rgb = Graphics::Toolkit::Color::Name::values( $color_def );
        if (ref $rgb){
            $rgb = $RGB->clamp( $RGB->normalize($rgb), 'normal' );
            return bless { name => $color_def, rgb => $rgb, source_values => '', source_space_name => ''};
        }
    }
    my ($values, $source_space) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_def );
    return "could not recognize color value format or color name: $color_def" unless ref $values;
    __PACKAGE__->new_from_normal_tuple( $values, $source_space);
}
sub new_from_normal_tuple { #
    my ($pkg, $values, $space_name) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    return "Need ARRAY of ".$color_space->axis_count." normalized (0..1) ".$color_space->name." values as first argument!"
        unless $color_space->is_value_tuple( $values );
    $values = $color_space->clamp( $values, 'normal' );
    my $source_values = '';
    if ($color_space->name ne $RGB->name){
        $source_values = $values;
        $values = Graphics::Toolkit::Color::Space::Hub::deconvert( $space_name, $values, 'normal' );
    } else { $space_name = '' }
    $values = $RGB->clamp( $values, 'normal' );
    my $name = Graphics::Toolkit::Color::Name::name_from_rgb( $RGB->round( $RGB->denormalize( $values ) ) );
    bless { name => $name, closest => '',
            rgb => $values, source_values => $source_values, source_space_name => $space_name };
}

########################################################################
sub name { $_[0]->{'name'} }
sub closest_name_and_distance {
    my ($self) = @_;
    return ($self->{'name'}, 0) if $self->{'name'};
    unless ($self->{'closest'}){
        my $values = $self->in_shape( Graphics::Toolkit::Color::Space::Hub::default_space_name() );
        my ($names, $distances) = Graphics::Toolkit::Color::Name::names_in_rgb_range( $values, 5);
        ($names, $distances) = Graphics::Toolkit::Color::Name::names_in_rgb_range( $values, 35)
            unless ref $names eq 'ARRAY' and @$names;
        $self->{'closest'} = { name => $names->[0], distance => $distances->[0]};
    }
    return @{$self->{'closest'}}{'name', 'distance'};
}

sub normalized { # normalized (0..1) value tuple in any color space
    my ($self, $space_name) = @_;
    Graphics::Toolkit::Color::Space::Hub::convert(
        $self->{'rgb'}, $space_name, 'normal', $self->{'source_space_name'}, $self->{'source_values'},
    );
}
sub in_shape  { # in any color space, range and precision
    my ($self, $space_name, $range_def, $precision_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $values = $self->normalized( $color_space->name );
    return $values unless ref $values;
    $values = $color_space->denormalize( $values, $range_def );
    $values = $color_space->clamp( $values, $range_def );
    $values = $color_space->round( $values, $precision_def );
    return $values;
}
sub formatted { # in shape values in any format
    my ($self, $space_name, $format_name, $range_def, $precision_def, $suffix_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $values = $self->in_shape( $color_space->name, $range_def, $precision_def );
    return $values unless ref $values;
    return $color_space->format( $values, $format_name, $suffix_def );
}

########################################################################
sub distance { # _c1 _c2 -- ~space ~select @range --> +
    my ($self, $second_color_values, $space_name, $select, $range) = @_;
    return "need value object as second argument" unless ref $second_color_values eq __PACKAGE__;
    return "$space_name is not a known color space name"
        if defined $space_name and not Graphics::Toolkit::Color::Space::Hub::is_space_name($space_name);
    return '"select" argument has to be an axis name or an ARRAY thereof'
        if ref $select and ref $select ne 'ARRAY';
    Graphics::Toolkit::Color::Space::Hub::distance(
        $self->normalized, $second_color_values->normalized, $space_name, $select, $range
    );
}

1;
