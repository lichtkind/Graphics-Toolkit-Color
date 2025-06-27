
# store all clolor space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;
use Carp;

#### internal space loading ############################################
my %space_obj;
our $default_space_name = 'RGB';
add_space( require "Graphics/Toolkit/Color/Space/Instance/$_.pm" ) for default_space_name(),
                       qw/CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/,   # missing: CubeHelix OKLAB
                       qw/CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/;  # search order

#### space API #########################################################
sub space_names   { sort keys %space_obj }
sub default_space_name { $default_space_name }
sub default_space { $space_obj{ $default_space_name } }
sub get_space     { $space_obj{ uc $_[0] } if exists $space_obj{ uc $_[0] } }
sub is_space      { (defined $_[0] and ref get_space($_[0])) ? 1 : 0 }

sub add_space {
    my $space = shift;
    return 'got no Graphics::Toolkit::Color::Space object' if ref $space ne 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    return "space objct has no name" unless $name;
    return "color space name $name is already taken" if ref get_space( $name );
    my @converter_target = $space->converter_names;
    return "can not add color space $name, it has no converter" unless @converter_target or $name eq $default_space_name;
     for my $converter_target (@converter_target){
        return "space object $name does convert into $converter_target, which is no known color space"
            unless is_space( $converter_target );
    }
    $space_obj{ uc $name } = $space;
    $space_obj{ uc $space->alias } = $space if $space->alias and not ref get_space( $space->alias );
    return 1;
}
sub remove_space {
    my $name = shift;
    return "got no name as argument" unless defined $name and $name;
    my $space = get_space( $name );
    return "no known color space with name $name" unless ref $space;
    delete $space_obj{ uc $space->alias } if $space->alias;
    delete $space_obj{ uc $space->name };
}

#### value API #########################################################

sub convert { # normalized RGB tuple, ~space_name -- normalized named original tuple
    my ($values, $target_space_name, $want_result_normalized, $source_space, $source_values) = @_;
    return "need a value ARRAY and a space name to convert to" unless defined $target_space_name;
    my $target_space = get_space( $target_space_name );
    return "$target_space_name is an unknown color space, try: ".(join ', ', space_names()) unless ref $target_space;
    return "need an ARRAY ref with 3 RGB values as first argument in order to convert them"
        unless ref $values eq 'ARRAY' and @$values == 3;
    $want_result_normalized //= 0;
    if ($target_space_name eq $default_space_name) { # nothing to convert
        $values = $target_space->denormalize( $values ) unless $want_result_normalized;
        return $values;
    }
    if (ref $source_values and defined $source_space and $source_space eq $target_space_name) {
        $source_values = $target_space->denormalize( $source_values ) unless $want_result_normalized;
        return $source_values;
    }

    my $current_space = $target_space;
    my @convert_chain = ($target_space->name);
    while ($current_space->name ne $default_space_name ){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        unshift @convert_chain, $next_space_name if $next_space_name ne $default_space_name;
        $current_space = get_space( $next_space_name );
    }
    my $values_are_normal = 1;
    $current_space = default_space();
    for my $next_space_name (@convert_chain){
        if (ref $source_values eq 'ARRAY' and $source_values->[0] eq $current_space){
            $values = [@{$source_values}[1 .. $#$source_values]];
            $source_values = 0;
            $values_are_normal = 1;
        } else {
            my @normal_in_out = $current_space->converter_normal_states( 'from', $next_space_name );
            $values = $current_space->normalize( $values ) if not $values_are_normal and $normal_in_out[0];
            $values = $current_space->denormalize( $values ) if $values_are_normal and not $normal_in_out[0];
            $values = $current_space->convert_from( $next_space_name, $values);
            $values_are_normal = $normal_in_out[1];
        }
        $current_space = get_space( $next_space_name );
    }
    $values = $target_space->normalize( $values ) if not $values_are_normal and $want_result_normalized;
    $values = $target_space->denormalize( $values ) if $values_are_normal and not $want_result_normalized;
    return $values;
}
sub deconvert { # normalizd value tuple --> RGB tuple
    my ($values, $source_space_name, $want_result_normalized) = @_;
    my $source_space = get_space( $source_space_name );
    return "$source_space_name is an unknown color space, try: ".(join ', ', space_names()) unless ref $source_space;
    $want_result_normalized //= 0;
    if ($source_space_name eq $default_space_name) { # nothing to convert
        $values = $source_space->denormalize( $values ) unless $want_result_normalized;
        return $values;
    }

    my $current_space = $source_space_name;
    my $values_are_normal = 1;
    while (uc $current_space->name ne $default_space_name ){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        my @normal_in_out = $current_space->converter_normal_states( 'to', $next_space_name );
        $values = $current_space->normalize( $values ) if not $values_are_normal and $normal_in_out[0];
        $values = $current_space->denormalize( $values ) if $values_are_normal and not $normal_in_out[0];
        $values = $current_space->convert_to( $next_space_name, $values);
        $values_are_normal = $normal_in_out[1];
        $current_space = get_space( $next_space_name );
    }
    $values = $current_space->normalize( $values ) unless $values_are_normal;
    return $values;
}

sub deformat { # formatted color def --> normalized values
    my ($color_def, $ranges, $suffix) = @_;
    return 'got no color definition' unless defined $color_def;
    my ($values, $original_space_name, $original_space);
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my ($val, $format_name) = $color_space->deformat( $color_def );
        if (ref $val){
            $values = $val;
            $original_space_name = $space_name;
            $original_space = $color_space;
            last;
        }
    }
    return 'could not deformat color definition: "$color_def"' unless ref $original_space;
    $values = $original_space->normalize( $values );
    $values = $original_space->clamp( $values, 'normal');
    return $values, $original_space_name;
}

sub deformat_partial_hash { # convert partial hash into
    my ($value_hash) = @_;
    return unless ref $value_hash eq 'HASH';
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my $pos_hash = $color_space->basis->deformat_partial_hash( $value_hash );
        next unless ref $pos_hash eq 'HASH';
        return wantarray ? ($pos_hash, $color_space->name) : $pos_hash;
    }
    return undef;
}

sub distance { # _c1 _c2 -- ~space ~select @range --> +
    my ($values_a, $values_b, $space_name, $select_axis, $range) = @_;
    return if ref $select_axis and ref $select_axis ne 'ARRAY';
    $space_name //= $default_space_name;
    my $color_space = get_space( $space_name );
    return unless ref $color_space;
    return unless $color_space->is_value_tuple( $values_a ) and $color_space->is_value_tuple( $values_b );
    unless ($space_name eq $default_space_name){
        $values_a = convert( $values_a, $space_name, defined $range);
        $values_b = convert( $values_b, $space_name, defined $range);
    }
    my $delta = $color_space->delta( $values_a, $values_b );
    $delta = $color_space->denormalize_delta( $delta, $range );
    if (defined $select_axis){
        $select_axis = [$select_axis] unless ref $select_axis;
        my @selected_values = grep {defined $_}
                              map {$color_space->select_tuple_value_from_name($_, $delta) } @$select_axis;
        return unless @selected_values == @$select_axis;
        $delta = \@selected_values;
    }
    my $d = 0;
    map  { $d += $_ * $_ } @$delta;
    return sqrt $d;
}

1;
