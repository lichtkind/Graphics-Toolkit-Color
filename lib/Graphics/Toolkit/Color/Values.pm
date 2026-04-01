
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
            return bless { color_name => $color_def, rgb => $rgb, source_tuple => '', source_space_name => ''};
        }
    }
    my ($tuple, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_def );
    return "could not recognize color value format or color name: $color_def" unless ref $tuple;
    new_from_tuple( '', $tuple, $space_name);
}
sub new_from_tuple { #
    my ($pkg, $tuple, $space_name, $range_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    return "Need ARRAY of ".$color_space->axis_count." ".$color_space->name." values as first argument!"
        unless $color_space->is_value_tuple( $tuple );
    # $tuple = $color_space->clamp( $tuple, $range_def);
    $tuple = $color_space->normalize( $tuple, $range_def );
    $tuple = $color_space->clamp( $tuple, 'normal');
    _new_from_normal_tuple( $tuple, $color_space );
}
sub _new_from_normal_tuple { #
    my ($tuple, $color_space) = @_;
    my $source_tuple = '';
    my $source_space_name = '';
    if ($color_space->name ne $RGB->name){
        $source_tuple = $tuple;
        $source_space_name = $color_space->name;
        $tuple = Graphics::Toolkit::Color::Space::Hub::deconvert( $color_space->name, $tuple, 'normal' );
    }
    $tuple = $RGB->clamp( $tuple, 'normal' );
    my $nv = $RGB->round( $RGB->denormalize( $tuple ) );
    my $name = Graphics::Toolkit::Color::Name::from_values( $RGB->round( $RGB->denormalize( $tuple ) ) );
    bless { rgb => $tuple, source_tuple => $source_tuple, source_space_name => $source_space_name, color_name => $name };
}

sub is_in_gamut {
    my ($color_def, $range_def) = @_;
    my $rgb = Graphics::Toolkit::Color::Name::get_values( $color_def );
    return 1 if ref $rgb;
    my ($tuple, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_def );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    return 0 unless ref $color_space;
    return $color_space->is_in_bounds( $tuple ); # , $range_def 
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
    my $tuple = $self->normalized( $color_space->name );
    return $tuple if not ref $tuple;
    $tuple = $color_space->denormalize( $tuple, $range_def );
    $tuple = $color_space->clamp( $tuple, $range_def );
    $tuple = $color_space->round( $tuple, $precision_def );
    return $tuple;
}
sub formatted { # in shape values in any format # _ -- ~space, @~|~format, @~|~range, @~|~suffix
    my ($self, $space_name, $format_name, $suffix_def, $range_def, $precision_def) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    my $tuple = $self->shaped( $color_space->name, $range_def, $precision_def );
    return $tuple unless ref $tuple;
    return $color_space->format( $tuple, $format_name, $suffix_def );
}
sub name { $_[0]->{'color_name'} }


1;
