
# store all clolor space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;
use Carp;

#### internal space loading ############################################
our $default_space_name = 'RGB';
my @search_order = ($default_space_name,
                   qw/CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/, # missing: CubeHelix OKLAB Hunterlab
                   qw/CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/);
my %space_obj;
add_space( require "Graphics/Toolkit/Color/Space/Instance/$_.pm" ) for @search_order;

#### space API #########################################################
sub is_space_name      { (ref get_space($_[0])) ? 1 : 0 }
sub all_space_names    { sort keys %space_obj }
sub default_space_name { $default_space_name }
sub default_space      { get_space( $default_space_name ) }
sub get_space          { (defined $_[0] and exists $space_obj{ uc $_[0] }) ? $space_obj{ uc $_[0] } : '' }
sub try_get_space {
    my $name = shift || $default_space_name;
    my $space = get_space( $name );
    return (ref $space) ? $space
                        : "$name is an unknown color space, try: ".(join ', ', all_space_names());
}

sub add_space {
    my $space = shift;
    return 'got no Graphics::Toolkit::Color::Space object' if ref $space ne 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    return "space objct has no name" unless $name;
    return "color space name $name is already taken" if ref get_space( $name );
    my @converter_target = $space->converter_names;
    return "can not add color space $name, it has no converter" unless @converter_target or $name eq $default_space_name;
     for my $converter_target (@converter_target){
        my $target_space = get_space( $converter_target );
        return "space object $name does convert into $converter_target, which is no known color space" unless $target_space;
        $space->alias_converter_name( $converter_target, $target_space->alias ) if $target_space->alias;
    }
    $space_obj{ uc $name } = $space;
    $space_obj{ uc $space->alias } = $space if $space->alias and not ref get_space( $space->alias );
    return 1;
}
sub remove_space {
    my $name = shift;
    return "need name of color space as argument in order to remove the space" unless defined $name and $name;
    my $space = get_space( $name );
    return "can not remove unknown color space: $name" unless ref $space;
    delete $space_obj{ uc $space->alias } if $space->alias;
    delete $space_obj{ uc $space->name };
}

#### value API #########################################################

sub convert { # normalized RGB tuple, ~space_name -- normalized named original tuple
    my ($values, $target_space_name, $want_result_normalized, $source_space_name, $source_values) = @_;
    my $target_space = try_get_space( $target_space_name );
    my $source_space = try_get_space( $source_space_name );
    $want_result_normalized //= 0;
    return "need an ARRAY ref with 3 RGB values as first argument in order to convert them"
        unless default_space()->is_value_tuple( $values );
    return $target_space unless ref $target_space;
    return "arguments source_space_name and source_values have to be provided both or none."
        if defined $source_space_name xor defined $source_values;
    return "argument source_values has to be a tuple, if provided"
        if $source_values and not $source_space->is_value_tuple( $source_values );

    # none conversion cases
    $values = $source_values if ref $source_values and $source_space eq $target_space;
    if ($target_space->name eq default_space()->name or $source_space eq $target_space) {
        return ($want_result_normalized) ? $values : $target_space->round($target_space->denormalize( $values ));
    }
    # find conversion chain
    my $current_space = $target_space;
    my @convert_chain = ($target_space->name);
    while ($current_space->name ne $default_space_name ){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        unshift @convert_chain, $next_space_name if $next_space_name ne $default_space_name;
        $current_space = get_space( $next_space_name );
    }
    # actual conversion
    my $values_are_normal = 1;
    my $space_name_before = default_space_name();
    for my $space_name (@convert_chain){
        my $current_space = get_space( $space_name );
        if ($current_space eq $source_space){
            $values = $source_values;
            $values_are_normal = 1;
        } else {
            my @normal_in_out = $current_space->converter_normal_states( 'from', $space_name_before );
            $values = $current_space->normalize( $values ) if not $values_are_normal and $normal_in_out[0];
            $values = $current_space->denormalize( $values ) if $values_are_normal and not $normal_in_out[0];
            $values = $current_space->convert_from( $space_name_before, $values);
            $values_are_normal = $normal_in_out[1];
        }
        $space_name_before = $current_space->name;
    }
    $values = $target_space->normalize( $values )  if not $values_are_normal and $want_result_normalized;
    $values = $target_space->denormalize( $values )if $values_are_normal and not $want_result_normalized;
    $values = $target_space->round( $values ) unless $want_result_normalized;
    return $values;
}
sub deconvert { # normalizd value tuple --> RGB tuple
    my ($space_name, $values, $want_result_normalized) = @_;
    return "need a space name to convert to as first argument" unless defined $space_name;
    my $original_space = try_get_space( $space_name );
    return $original_space unless ref $original_space;
    return "need an ARRAY ref with 3 or 4 values as first argument in order to deconvert them"
        unless ref $values eq 'ARRAY' and (@$values == 3 or @$values == 4);
    $want_result_normalized //= 0;
    if ($original_space->name eq $default_space_name) { # nothing to convert
        return ($want_result_normalized) ? $values : $original_space->round( $original_space->denormalize( $values ));
    }

    my $current_space = $original_space;
    my $values_are_normal = 1;
    while (uc $current_space->name ne $default_space_name){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        my @normal_in_out = $current_space->converter_normal_states( 'to', $next_space_name );
        $values = $current_space->normalize( $values ) if not $values_are_normal and $normal_in_out[0];
        $values = $current_space->denormalize( $values ) if $values_are_normal and not $normal_in_out[0];
        $values = $current_space->convert_to( $next_space_name, $values);
        $values_are_normal = $normal_in_out[1];
        $current_space = get_space( $next_space_name );
    }
    return ($want_result_normalized) ? $values : $current_space->round( $current_space->denormalize( $values ));
}

sub deformat { # formatted color def --> normalized values
    my ($color_def, $ranges, $suffix) = @_;
    return 'got no color definition' unless defined $color_def;
    my ($values, $original_space, $format_name);
    for my $space_name (all_space_names()) {
        my $color_space = get_space( $space_name );
        ($values, $format_name) = $color_space->deformat( $color_def );
        if (defined $format_name){
            $original_space = $color_space;
            last;
        }
    }
    return 'could not deformat color definition: "$color_def"' unless ref $original_space;
    $values = $original_space->normalize( $values );
    $values = $original_space->clamp( $values, 'normal');
    return $values, $original_space->name, $format_name;
}

sub deformat_partial_hash { # convert partial hash into
    my ($value_hash, $space_name) = @_;
    return unless ref $value_hash eq 'HASH';
    my $space = try_get_space( $space_name );
    return $space unless ref $space;
    my @space_name_options = (defined $space_name and $space_name) ? ($space->name) : (@search_order);
    for my $space_name (@space_name_options) {
        my $color_space = get_space( $space_name );
        my $pos_hash = $color_space->basis->pos_hash_from_partial_hash( $value_hash );
        next unless ref $pos_hash eq 'HASH';
        return wantarray ? ($pos_hash, $color_space->name) : $pos_hash;
    }
    return undef;
}

sub distance { # RGB tuples -- ~space, ~@select @range --> +
    my ($values_a, $values_b, $space_name, $select_axis, $range) = @_;
    my $color_space = try_get_space( $space_name );
    my $default_space = default_space();
    return $color_space unless ref $color_space;
    return 'got malformed value ARRAY' unless $default_space->is_value_tuple( $values_a )
                                          and $default_space->is_value_tuple( $values_b );
    unless ($color_space->name eq $default_space_name){
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
    map { $d += $_ * $_ } @$delta;
    return sqrt $d;
}

1;
