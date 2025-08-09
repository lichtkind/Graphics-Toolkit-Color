
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;

my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

########################################################################
sub complement { # :base_color +steps +tilt %target_delta --> @:values
    my ($start_color, $steps, $tilt, $target_delta) = shift;
    my $start_values = $start_color->shaped( $HSL->name );
    my $target_values = [@$start_values];
    my $result_count = int abs $steps;
    my $half_result_count = int (($result_count - 1) / 2);
    my $scaling_exponent = abs($tilt) + 1;
    my $max_of_linear_half_scale = ((($result_count - 1) / 2) ** $scaling_exponent) - 1;
    for my $axis_index (0 .. 2) {
        $target_delta->[$axis_index] = 0 unless defined $target_delta->[$axis_index];
        $target_values->[$axis_index] += $target_delta->[$axis_index];
    }
    $target_values = $HSL->clamp( $target_values );  # bring back out of bound linear axis values
    $target_delta->[1] = $target_values->[1] - $start_values->[1];
    $target_delta->[2] = $target_values->[2] - $start_values->[2];
    my @result = ();
    my $hue_range = 180 + $target_delta->[0]; # real value size of half complement circle
    for my $step_nr (1 .. $half_result_count) {
        my $hue_pos = $step_nr ** $scaling_exponent;
        $hue_pos = $max_of_linear_half_scale - $hue_pos if $tilt > 0;
        $hue_pos /= $max_of_linear_half_scale;
        push @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                        [$start_values->[0] + ($hue_range         * $hue_pos),
                         $start_values->[1] + ($target_delta->[1] * $hue_pos),
                         $start_values->[2] + ($target_delta->[2] * $hue_pos)], $HSL->name);
    }
    # THE complement
    push @result, Graphics::Toolkit::Color::Values->new_from_tuple( $target_values, $HSL->name) if $steps % 2;
    $hue_range = 180 - $target_delta->[0];
    for my $step_nr ($result_count - $half_result_count .. $result_count - 1) {
        my $hue_pos = $step_nr ** $scaling_exponent;
        $hue_pos = $max_of_linear_half_scale - $hue_pos if $tilt > 0;
        $hue_pos /= $max_of_linear_half_scale;
        push @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                        [$start_values->[0] + ($hue_range         * $hue_pos),
                         $start_values->[1] + ($target_delta->[1] * $hue_pos),
                         $start_values->[2] + ($target_delta->[2] * $hue_pos)], $HSL->name);
    }
    push @result, $start_color if $result_count > 1;
    return @result;
}

########################################################################
sub gradient { # @:colors, +steps, +tilt, :space --> @:values
    my ($colors, $steps, $tilt, $color_space) = @_;
    my $scaling_exponent = abs($tilt) + 1; # tilt = exponential scaling
    my $max_of_linear_scale = ($steps ** $scaling_exponent) - 1;
    my $segment_count = @$colors - 1;
    my $percent_of_segment = 100 / $segment_count;
    my @result = ($colors->[0]);
    for my $step_nr (2 .. $steps - 1){
        my $linear_pos = ($step_nr ** $scaling_exponent) - 1;
        $linear_pos = $max_of_linear_scale - $linear_pos if $tilt < 0;
        my $percent_of_gradient = $linear_pos / $max_of_linear_scale * 100;
        my $current_segment_nr = int ($percent_of_gradient / $percent_of_segment);
        my $percent_in_segment = $segment_count * ($percent_of_gradient - ($current_segment_nr * $percent_of_segment));
        push @result, $colors->[$current_segment_nr]->mix(
                          [{color => $colors->[$current_segment_nr+1], percent => $percent_in_segment}], $color_space );
    }
    push @result, pop @$colors if $steps > 1;
    return @result;
}

########################################################################
sub cluster { # :values, +radius @+|+distance, :space --> @:values
    my ($center, $radius, $distance, $color_space) = @_;
    my $axis_count = $color_space->axis_count;
    my @result = ();
    if (ref $radius) {
    } else {
        # max distance
        # in alle 4 richtungen
        # finde kontout
        # spiegle 8 mal
        # berechne nächste ebene
    }
# check for space borders
    return @result;
}


1;
