
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;

my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

########################################################################
sub complement { # :base_color +steps +tilt %target_delta --> @_
    my ($reference_color, $steps, $tilt, $target_delta) = shift;
    my $start_values = $reference_color->in_shape( $HSL->name );
    my $result_count = int abs $steps;
    my $half_result_count = int (($result_count - 1) / 2);
    my $exponent = abs($tilt) + 1;
    my %target_delta = (h => ($target_delta->[0] // 0),
                        s => ($target_delta->[1] // 0),
                        l => ($target_delta->[2] // 0) );
    my $ideal_complement = $reference_color->add( { hue => 180 }, $HSL->name );
    my $complement = $ideal_complement->add( { %target_delta }, $HSL->name );
    my @result = ();
    my $hue_range = 180 + $target_delta{'h'};
    for my $step_nr (1 .. $half_result_count) {
        my $delta_h = $target_delta{'h'};
        my $delta_s = $target_delta{'s'};
        my $delta_l = $target_delta{'l'};
        push @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                        [$start_values->[0] + $delta_h,
                         $start_values->[1] + $delta_s,
                         $start_values->[2] + $delta_l], $HSL->name);
    }
    push @result, $complement if $steps % 2;
    $hue_range = 180 - $target_delta{'h'};
    for my $step_nr ($result_count - $half_result_count .. $result_count - 1) {
        my $delta_h = $target_delta{'h'};
        my $delta_s = $target_delta{'s'};
        my $delta_l = $target_delta{'l'};
        push @result, Graphics::Toolkit::Color::Values->new_from_tuple(
                        [$start_values->[0] + $delta_h,
                         $start_values->[1] + $delta_s,
                         $start_values->[2] + $delta_l], $HSL->name);
    }

    push @result, $reference_color if $result_count > 1;
    return @result;
}

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
sub cluster {# :values, +radius @+|+distance, :space --> @:values
    my ($center, $radius, $distance, $color_space) = @_;
    my @result = ();

    return @result;
}


1;
