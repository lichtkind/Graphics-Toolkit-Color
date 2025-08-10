
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;

my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

########################################################################
sub complement { # :base_color +steps +tilt %target_delta --> @:values
    my ($start_color, $steps, $tilt, $target_delta) = @_;
    my $start_values = $start_color->shaped( $HSL->name );
    my $target_values = [@$start_values];
    $target_values->[0] += 180;
    for my $axis_index (0 .. 2) {
        $target_delta->[$axis_index] = 0 unless defined $target_delta->[$axis_index];
        $target_values->[$axis_index] += $target_delta->[$axis_index];
    }
    $target_values = $HSL->clamp( $target_values );  # bring back out of bound linear axis values
    $target_delta->[1] = $target_values->[1] - $start_values->[1];
    $target_delta->[2] = $target_values->[2] - $start_values->[2];
    my $result_count = int abs $steps;
    my $scaling_exponent = abs($tilt) + 1;
    my @hue_percent = map {
        my $hue_percent = ($_ * 2 / $result_count) ** $scaling_exponent;
        ($tilt > 0) ? (1 - $hue_percent) : $hue_percent;
    } 1 .. int (($result_count - 1) / 2);
    my $hue_range = 180 + $target_delta->[0]; # real value size of half complement circle
    my @result = ();
    push( @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                    [$start_values->[0] + ($hue_range         * $_),
                     $start_values->[1] + ($target_delta->[1] * $_),
                     $start_values->[2] + ($target_delta->[2] * $_)], $HSL->name)) for @hue_percent;
    push @result, Graphics::Toolkit::Color::Values->new_from_tuple( $target_values, $HSL->name)
        if $result_count == 1 or not $result_count % 2;
    $hue_range = 180 - $target_delta->[0];
    @hue_percent = map {1 - $_} reverse @hue_percent;
    push( @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                    [$target_values->[0] + ($hue_range         * $_),
                     $target_values->[1] - ($target_delta->[1] * $_),
                     $target_values->[2] - ($target_delta->[2] * $_)], $HSL->name)) for @hue_percent;
    push @result, $start_color if $result_count > 1;
    return @result;
}

########################################################################
sub gradient { # @:colors, +steps, +tilt, :space --> @:values
    my ($colors, $steps, $tilt, $color_space) = @_;
    my $scaling_exponent = abs($tilt) + 1; # tilt = exponential scaling
    my $segment_count = @$colors - 1;
    my @result = ($colors->[0]);
    for my $step_nr (2 .. $steps - 1){
        my $percent_of_gradient = (($step_nr-1) / ($steps-1)) ** $scaling_exponent;
        $percent_of_gradient = 1 - $percent_of_gradient if $tilt < 0;
        my $current_segment_nr = int ($percent_of_gradient * $segment_count);
        my $percent_in_segment = 100 * $segment_count * ($percent_of_gradient - ($current_segment_nr / $segment_count));
        push @result, $colors->[$current_segment_nr]->mix(
                          [{color => $colors->[$current_segment_nr+1], percent => $percent_in_segment}], $color_space );
    }
    push @result, pop @$colors if $steps > 1;
    return @result;
}

########################################################################
sub cluster { # :values, +radius @+|+distance, :space --> @:values
    my ($center_color, $radius, $distance, $color_space) = @_;
    my $color_space_name = $color_space->name;
    my $center_values = $center_color->shaped( $color_space_name );
    my @result_values;
    if (ref $radius) {
        my $r = $radius->[0];
        my $axis_count = $color_space->axis_count;
    } else {
        # max distance
        # in alle 4 richtungen
        # finde kontout
        # spiegle 8 mal
        # berechne nächste ebene
    }
    my @result = map { # check for space borders and constraints
        my $color = Graphics::Toolkit::Color::Values->new_from_tuple( $_, $color_space_name);
        ($color_space->is_equal( $_, $color->shaped( $color_space_name ), 5)) ? $color : undef;
    } @result_values;
    return grep {ref} @result;
}


1;
