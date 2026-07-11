
# read only store of a single color: name + values in default and original space

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

#### constructor #######################################################
sub new_from_any_input { #  values => %space_name => tuple ,   ~origin_space, ~color_name
    my ($pkg, $color_def, $space_name, $range_def, $raw) = @_;
    return "Can not create color value object without color definition!" unless defined $color_def;
    if (not ref $color_def) { # try to resolve color name
        my $rgb = Graphics::Toolkit::Color::Name::get_values( $color_def );
        if (ref $rgb){
            $rgb = $RGB->clamp( $RGB->normalize( $rgb ), 'normal' );
            return bless { color_name => $color_def, rgb_tuple => $rgb, source_tuple => '', source_space_name => ''};
        }
    }
    my ($tuple, $found_space_name, $format) = (defined $space_name)
                                            ? Graphics::Toolkit::Color::Space::Hub::deformat( $color_def, $space_name )
                                            : Graphics::Toolkit::Color::Space::Hub::deformat_search( $color_def );
    return $tuple unless ref $tuple;
    new_from_tuple( '', $tuple, $found_space_name, $range_def, $raw);
}
sub new_from_tuple { #
    my ($pkg, $tuple, $space_name, $range_def, $raw) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    return "Need ARRAY of ".$color_space->axis_count." ".$color_space->name." values as first argument!"
        unless $color_space->is_value_tuple( $tuple );
    $tuple = $color_space->normalize( $tuple, $range_def );
    $tuple = $color_space->clamp( $tuple, 'normal' ) unless defined $raw and $raw;

    my $source_tuple = '';
    my $source_space_name = '';
    if ($color_space->name ne $RGB->name){ # convert into RGB if needed
        $source_tuple = $tuple;
        $source_space_name = $color_space->name;
        $tuple = Graphics::Toolkit::Color::Space::Hub::deconvert( $tuple, $color_space, 'normal' );
    }

    my $name = Graphics::Toolkit::Color::Name::from_values( $RGB->round( $RGB->denormalize( $tuple ) ) );
    bless { rgb_tuple => $tuple, source_tuple => $source_tuple, source_space_name => $source_space_name, color_name => $name };
}

#### getter ############################################################
sub normalized { # normalized (0..1) value tuple in any color space
    my ($self, $color_space, $raw) = @_;
    $color_space //= Graphics::Toolkit::Color::Space::Hub::default_space();
    return 'got no know color space object' unless Graphics::Toolkit::Color::Space::Hub::is_known_space( $color_space );
    my $tuple = Graphics::Toolkit::Color::Space::Hub::convert(
        $self->{'rgb_tuple'}, $color_space, 'normal', $self->{'source_tuple'}, $self->{'source_space_name'},
    );
    $tuple = $color_space->clamp( $tuple, 'normal' ) unless defined $raw and $raw;
    return $tuple;
}
sub shaped  { # in any color space, range and precision
    my ($self, $color_space, $range_def, $precision_def, $raw) = @_;
    $color_space //= Graphics::Toolkit::Color::Space::Hub::default_space();
    return 'got no know color space object' unless Graphics::Toolkit::Color::Space::Hub::is_known_space( $color_space );
    my $tuple = $self->normalized( $color_space, $raw );
    return $tuple if not ref $tuple;
    $tuple = $color_space->denormalize( $tuple, $range_def );
    $tuple = $color_space->round( $tuple, $precision_def ) unless ($raw and not defined $precision_def) 
                                                               or (defined $range_def and not defined $precision_def);
    $tuple = $color_space->clamp( $tuple, $range_def ) unless defined $raw and $raw;
    return $tuple;
}
sub formatted { # in shape values in any format # _ -- ~space, @~|~format, @~|~range, @~|~suffix --> @|%|$
    my ($self, $color_space, $format_name, $suffix_def, $range_def, $precision_def, $raw) = @_;
    $color_space //= Graphics::Toolkit::Color::Space::Hub::default_space();
    return \'got no know color space object' unless Graphics::Toolkit::Color::Space::Hub::is_known_space( $color_space );
    my $tuple = $self->shaped( $color_space, $range_def, $precision_def, $raw );
    return \$tuple unless ref $tuple; # error is SCALAR ref because result can be string
    return $color_space->format( $tuple, $format_name, $suffix_def );
}
sub name { $_[0]->{'color_name'} }

sub is_in_gamut {
    my ($self, $color_space) = @_;
    $color_space //= Graphics::Toolkit::Color::Space::Hub::try_get_space( $self->{'source_space_name'} );
    return 0 unless Graphics::Toolkit::Color::Space::Hub::is_known_space( $color_space );
    my $tuple = $self->normalized( $color_space, 'raw' );
    return 0 unless ref $tuple;
    return $color_space->is_in_linear_bounds( $tuple, 'normal' );
}

1;
