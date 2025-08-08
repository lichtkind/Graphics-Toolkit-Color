
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;

my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

########################################################################
sub complement { # :values +steps +hue_tilt +saturation_tilt +lightness_tilt --> @_
    my ($reference_color, $steps, $tilt, $target) = shift;
    my $start_values = $reference_color->in_shape( $HSL->name );
    my $result_count = int abs $steps;
    my $half_result_count = int (($result_count - 1) / 2);
    my %delta = (h => ($target->[0] // 0), s => ($target->[1] // 0), l => ($target->[2] // 0));
    my $ideal_complement = $reference_color->add( { hue => 180 }, $HSL->name );
    my $complement = $ideal_complement->add( { %delta }, $HSL->name );
    my @result = ();
    for my $step_nr (1 .. $half_result_count) {

    }
    push @result, $complement if $steps % 2;
    for my $step_nr ($result_count - $half_result_count .. $result_count - 1) {

    }
    # Graphics::Toolkit::Color::Values->new_from_tuple( $values, $HSL->name);
    #~ my $saturation_tilt = (exists $arg{'s'}) ? (delete $arg{'s'}) :
                          #~ (exists $arg{'saturation_tilt'}) ? (delete $arg{'saturation_tilt'}) : 0;
    #~ return $help if ref $saturation_tilt and ref $saturation_tilt ne 'HASH';
    #~ my $saturation_axis_offset = 0;
    #~ if (ref $saturation_tilt eq 'HASH'){
        #~ my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $saturation_tilt );
        #~ return $help if not defined $space_name or $space_name ne 'HSL' or not exists $pos_hash->{1};
        #~ $saturation_axis_offset = $pos_hash->{0} if exists $pos_hash->{0};
        #~ $saturation_tilt = $pos_hash->{1};
    #~ }
    #~ my $lightness_tilt = (exists $arg{'l'}) ? (delete $arg{'l'}) :
                         #~ (exists $arg{'lightness_tilt'}) ? (delete $arg{'lightness_tilt'}) : 0;
    #~ return $help if ref $lightness_tilt and ref $lightness_tilt ne 'HASH';
    #~ my $lightness_axis_offset = 0;
    #~ if (ref $lightness_tilt eq 'HASH'){
        #~ my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $lightness_tilt );
        #~ return $help if not defined $space_name or $space_name ne 'HSL' or not exists $pos_hash->{2};
        #~ $lightness_axis_offset = $pos_hash->{0} if exists $pos_hash->{0};
        #~ $lightness_tilt = $pos_hash->{2};
    #~ }

    #~ my @hsl2 = my @hsl = $self->values('HSL');
    #~ my @hue_turn_point = ($hsl[0] + 90, $hsl[0] + 270, 800); # Dmax, Dmin and Pseudo-Inf
    #~ my @sat_turn_point  = ($hsl[0] + 90, $hsl[0] + 270, 800);
    #~ my @light_turn_point = ($hsl[0] + 90, $hsl[0] + 270, 800);
    #~ my $sat_max_hue = $hsl[0] + 90 + $saturation_axis_offset;
    #~ my $sat_step = $saturation_tilt * 4 / $steps;
    #~ my $light_max_hue = $hsl[0] + 90 + $lightness_axis_offset;
    #~ my $light_step = $lightness_tilt * 4 / $steps;
    #~ if ($saturation_axis_offset){
        #~ $sat_max_hue -= 360 while $sat_max_hue > $hsl[0]; # putting dmax in range
        #~ $sat_max_hue += 360 while $sat_max_hue <= $hsl[0]; # above c1->hue
        #~ my $dmin_first = $sat_max_hue > $hsl[0] + 180;
        #~ @sat_turn_point =  $dmin_first ? ($sat_max_hue - 180, $sat_max_hue, 800)
                                       #~ : ($sat_max_hue, $sat_max_hue + 180, 800);
        #~ $sat_step = - $sat_step if $dmin_first;
        #~ my $sat_start_delta = $dmin_first ? ((($sat_max_hue - 180 - $hsl[0]) / 90 * $saturation_tilt) - $saturation_tilt)
                                          #~ : (-(($sat_max_hue -      $hsl[0]) / 90 * $saturation_tilt) + $saturation_tilt);
        #~ $hsl[1] += $sat_start_delta;
        #~ $hsl2[1] -= $sat_start_delta;
    #~ if ($lightness_axis_offset){
        #~ $light_max_hue -= 360 while $light_max_hue > $hsl[0];
        #~ $light_max_hue += 360 while $light_max_hue <= $hsl[0];
        #~ my $dmin_first = $light_max_hue > $hsl[0] + 180;
        #~ @light_turn_point =  $dmin_first ? ($light_max_hue - 180, $light_max_hue, 800)
                                         #~ : ($light_max_hue, $light_max_hue + 180, 800);
        #~ $light_step = - $light_step if $dmin_first;
        #~ my $light_start_delta = $dmin_first ? ((($light_max_hue - 180 - $hsl[0]) / 90 * $lightness_tilt) - $lightness_tilt)
                                            #~ : (-(($light_max_hue -      $hsl[0]) / 90 * $lightness_tilt) + $lightness_tilt);
        #~ $hsl[2] += $light_start_delta;
        #~ $hsl2[2] -= $light_start_delta;

    #~ my (@result) = $c1;
    #~ my $hue_avg_step = 360 / $steps;
    #~ my $hue_c2_distance = $self->distance( to => $c2, in => 'HSL', select => 'hue');
    #~ my $hue_avg_tight_step = $hue_c2_distance * 2 / $steps;
    #~ my $hue_sec_deg_delta = 8 * ($hue_avg_step - $hue_avg_tight_step) / $steps; # second degree delta
    #~ $hue_sec_deg_delta = -$hue_sec_deg_delta if $hue_tilt < 0; # if c2 on right side
    #~ my $hue_last_step = my $hue_ak_step = $hue_avg_step; # bar height of pseudo integral
    #~ my $hue_current = my $hue_current_naive = $hsl[0];
    #~ my $saturation_current = $hsl[1];
    #~ my $lightness_current = $hsl[2];
    #~ my $hi = my $si = my $li = 0; # index of next turn point where hue step increase gets flipped (at Dmax and Dmin)
    #~ for my $i (1 .. $steps - 1){
        #~ $hue_current_naive += $hue_avg_step;

        #~ if ($hue_current_naive >= $hue_turn_point[$hi]){
            #~ my $bar_width = ($hue_turn_point[$hi] - $hue_current_naive + $hue_avg_step) / $hue_avg_step;
            #~ $hue_ak_step += $hue_sec_deg_delta * $bar_width;
            #~ $hue_current += ($hue_ak_step + $hue_last_step) / 2 * $bar_width;
            #~ $hue_last_step = $hue_ak_step;
            #~ $bar_width = 1 - $bar_width;
            #~ $hue_sec_deg_delta = -$hue_sec_deg_delta;
            #~ $hue_ak_step += $hue_sec_deg_delta * $bar_width;
            #~ $hue_current += ($hue_ak_step + $hue_last_step) / 2 * $bar_width;
            #~ $hi++;
        #~ } else {
            #~ $hue_ak_step += $hue_sec_deg_delta;
            #~ $hue_current += ($hue_ak_step + $hue_last_step) / 2;
        #~ }
        #~ $hue_last_step = $hue_ak_step;
        #~ if ($hue_current_naive >= $sat_turn_point[$si]){
            #~ my $bar_width = ($sat_turn_point[$si] - $hue_current_naive + $hue_avg_step) / $hue_avg_step;
            #~ $saturation_current += $sat_step * ((2 * $bar_width) - 1);
            #~ $sat_step = -$sat_step;
            #~ $si++;
        #~ } else { $saturation_current += $sat_step; }
        #~ if ($hue_current_naive >= $light_turn_point[$li]){
            #~ my $bar_width = ($light_turn_point[$li] - $hue_current_naive + $hue_avg_step) / $hue_avg_step;
            #~ $lightness_current += $light_step * ((2 * $bar_width) - 1);
            #~ $light_step = -$light_step;
            #~ $li++;
        #~ } else { $lightness_current += $light_step; }

    push @result, $reference_color if $result_count > 1;
    return @result;
}

sub gradient { # @:colors, +steps, +tilt, :space --> @:values
    my ($colors, $steps, $tilt, $color_space) = @_;
    my @result = ($colors->[0]);
    my $exponent = abs($tilt) + 1;
    my $scale_max = ($steps ** $exponent) - 1;
    my $segment_count = @$colors - 1;
    my $segment_size = $scale_max / $segment_count;
    for my $step_nr (2 .. $steps - 1){
        my $linear_pos = ($step_nr ** $exponent) - 1;
        $linear_pos = $scale_max - $linear_pos if $tilt < 0;
        my $percent = $linear_pos / $scale_max * 100;
        my $color_index = int ($percent / $segment_size);
        $percent = $segment_count * ($percent - ($segment_size * $color_index));
        push @result, $colors->[$color_index]->mix(
                          [{color => $colors->[$color_index+1], percent => $percent}], $color_space );
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
