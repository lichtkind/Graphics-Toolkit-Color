
# methods to compute one related color

package Graphics::Toolkit::Color::Calculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Util qw/is_nr spow/;
use Graphics::Toolkit::Color::Values;

#### light designer API ################################################
sub lighten { 
    my ($color_values, $by, $raw, $color_space) = @_;
    lightness( $color_values, undef, undef, $by, $raw, $color_space);
}
sub darken  {
    my ($color_values, $by, $raw, $color_space) = @_;
    lightness( $color_values, undef, undef, -$by, $raw, $color_space);
}
sub lightness {
    my ($color_values, $set, $mult, $add, $spread, $raw, $space_name) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
	return $color_space unless ref $color_space;
    return "selected color space: '".$color_space->name."' has no axis with a lightness role" 
		unless $color_space->is_axis_role( 'lightness' );
	$set  = {'lightness' => $set}  if defined $set;
	$mult = {'lightness' => $mult} if defined $mult;
	$add  = {'lightness' => $add}  if defined $add;
	derive($color_values, $set, $mult, $add, $raw, 'normal', $color_space->name);
} 

sub saturate   {
    my ($color_values, $by, $raw, $color_space) = @_;
    saturation( $color_values, undef, undef, $by, $raw, $color_space);
}
sub desaturate {
    my ($color_values, $by, $raw, $color_space) = @_;
    saturation( $color_values, undef, undef, -$by, $raw, $color_space);
}
sub saturation {
    my ($color_values, $set, $mult, $add, $raw, $space_name) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
	return $color_space unless ref $color_space;
    return "selected color space: '".$color_space->name."' has no axis with a lightness role" 
		unless $color_space->is_axis_role( 'saturation' );
	$set  = {'saturation' => $set}  if defined $set;
	$mult = {'saturation' => $mult} if defined $mult;
	$add  = {'saturation' => $add}  if defined $add;
	derive($color_values, $set, $mult, $add, $raw, 'normal', $color_space->name);
}

# L : neu = achsenmitte + (alt - mitte) × faktor
# S : achsenmitte# alt + betrag × (1 − alt)


#### low level methods #############################################

sub derive {
    my ($color_values, $set, $mult, $add, $raw, $range_def, $selected_space_name, $default_space_name) = @_;
    my ($tuple, $color_space);
    my $default_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $default_space_name );
    $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $selected_space_name ) if defined $selected_space_name;
    return $color_space if defined $selected_space_name and not ref $color_space;

    if (defined $set and not ref $set){  # set constant
	    $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $default_space_name ) unless ref $color_space;
	    return $color_space unless ref $color_space;
		$tuple = $color_values->shaped( $color_space->name, $range_def, -1, $raw ) unless ref $tuple;
		return $tuple unless ref $tuple;
		$tuple->[$_] = $set for $color_space->basis->axis_iterator;
	} elsif (ref $set eq 'HASH'){         # set partial hash
		my ($new_values, $deduced_space_name) = 
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $set, $selected_space_name );
		return $new_values unless ref $new_values;
	    my $deduced_color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $deduced_space_name );
		$color_space = (ref $color_space) ? $color_space 
		                                  :($default_space->family eq $deduced_color_space->family) 
			                              ? $default_space 
			                              : $deduced_color_space;
		$tuple = $color_values->shaped( $color_space->name, $range_def, -1, $raw ) unless ref $tuple;
		$tuple->[ $color_space->pos_from_axis_name($_) ] = $set->{$_} for keys %$set;
	}
    if (defined $mult and not ref $mult){
	    $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $default_space_name ) unless ref $color_space;
	    return $color_space unless ref $color_space;
		$tuple = $color_values->shaped( $color_space->name, $range_def, -1, $raw ) unless ref $tuple;
		return $tuple unless ref $tuple;
		$tuple->[$_] *= $mult for $color_space->basis->axis_iterator;
	} elsif (ref $mult eq 'HASH'){
		my ($new_values, $deduced_space_name) = 
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $mult, $selected_space_name );
		return $new_values unless ref $new_values;
	    my $deduced_color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $deduced_space_name );
		$color_space = (ref $color_space) ? $color_space 
		                                  :($default_space->family eq $deduced_color_space->family) 
			                              ? $default_space 
			                              : $deduced_color_space;
		$tuple = $color_values->shaped( $color_space->name, $range_def, -1, $raw ) unless ref $tuple;
		$tuple->[ $color_space->pos_from_axis_name($_) ] *= $mult->{$_} for keys %$mult;
	}
    if (defined $add and not ref $add){
	    $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $default_space_name ) unless ref $color_space;
	    return $color_space unless ref $color_space;
		$tuple = $color_values->shaped( $color_space->name, $range_def, -1, $raw ) unless ref $tuple;
		return $tuple unless ref $tuple;
		$tuple->[$_] += $add for $color_space->basis->axis_iterator;
	} elsif (ref $add eq 'HASH'){
		my ($new_values, $deduced_space_name) = 
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $add, $selected_space_name );
		return $new_values unless ref $new_values;
	    my $deduced_color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $deduced_space_name );
		$color_space = (ref $color_space) ? $color_space 
		                                  :($default_space->family eq $deduced_color_space->family) 
			                              ? $default_space 
			                              : $deduced_color_space;
		$tuple = $color_values->shaped( $color_space->name, $range_def, -1, $raw ) unless ref $tuple;
		$tuple->[ $color_space->pos_from_axis_name($_) ] += $add->{$_} for keys %$add;
	}
    return $color_values->new_from_tuple( $tuple, $color_space->name, $range_def, $raw );
}

sub set_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $deduced_space_name) = 
		Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : $help_start.'any supported color space!';
    }
    my $tuple = $color_values->shaped( $deduced_space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $tuple->[$pos] = $new_values->[$pos] if defined $new_values->[$pos];
    }
    return $color_values->new_from_tuple( $tuple, $color_space->name );
}

sub add_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $deduced_space_name) = 
		Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : $help_start.'any supported color space!';
    }
    my $tuple = $color_values->shaped( $deduced_space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $tuple->[$pos] += $new_values->[$pos] if defined $new_values->[$pos];
    }
    return $color_values->new_from_tuple( $tuple, $color_space->name );
}

sub apply_gamma {
    my ($color_values, $gamma, $color_space) = @_;
    my $gamma_array = '';
    return "need a color space as third argument" if ref $color_space ne 'Graphics::Toolkit::Color::Space';
    if (ref $gamma eq 'HASH'){
        ($gamma_array, my $deduced_space_name) = 
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $gamma, $color_space->name );
		return 'axis names: '.join(', ', keys %$gamma).' do not correlate to the selected color space: '.
			($color_space->name).'!' unless ref $gamma_array;
	}
	$gamma_array = [ ($gamma) x $color_space->axis_count] if is_nr( $gamma );
	$gamma_array = $gamma if not defined $gamma_array and ref $gamma eq 'ARRAY';
    return 'got badly formatted gamma value' if ref $gamma_array ne 'ARRAY';
	
	my $tuple = $color_values->normalized( $color_space->name );
    for my $axis_nr ($color_space->basis->axis_iterator){
	    $tuple->[$axis_nr] = spow($tuple->[$axis_nr], $gamma_array->[$axis_nr]) if exists $gamma_array->[$axis_nr];
    }
    return $color_values->new_from_tuple( $tuple, $color_space->name, 'normal' );
}

sub tint     { mix_with(@_, [ 1 , 1 , 1  ]) } # white
sub tone     { mix_with(@_, [ .5, .5, .5 ]) } # grey50
sub shade    { mix_with(@_, [ 0 , 0 , 0  ]) } # black
sub mix_with {
    my ($color_values, $by, $raw, $color_space, $tuple) = @_;
    mix( $color_values, $color_values->new_from_tuple( $tuple, 'RGB', 'normal' ), $by, $raw, $color_space);
}
sub mix { #  .base_color_vals, @.added_volor_vals, @+|+add_amount, .space --> .color_values
    my ($base_color, $added_color, $add_amount, $raw, $color_space_name ) = @_;
    return "need color value object as first argument !\n" unless ref $base_color eq 'Graphics::Toolkit::Color::Values';
    return "second argument has to be an ARRAY !\n" unless ref $added_color eq 'ARRAY';
    return "need a color space name !\n" unless defined $color_space_name;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $color_space_name );
    return $color_space unless ref $color_space;


    my $color_count = @$added_color + 1;
    $add_amount = 1 / $color_count unless defined $add_amount;
    $add_amount = [($add_amount) x ($color_count - 1)] unless ref $add_amount eq 'ARRAY';
	return "ARRAY of mix amounts needs a value for every color !\n" unless @$add_amount == $color_count - 1;
    my $mix_sum = 0;
    $mix_sum += $_ for @$add_amount;
    if ($mix_sum > 1){
		for my $reciepe_index (0 .. $#$add_amount){
			$add_amount->[$reciepe_index] = $add_amount->[$reciepe_index] / $mix_sum;
		}
	} else {
         push @$add_amount, 1 - $mix_sum;
         push @$added_color, $base_color;
	}
   
    my $result_values = [(0) x $color_space->axis_count];
    for my $color_nr (0 .. $#$added_color){
        my $tuple = $added_color->[$color_nr]->shaped( $color_space->name );
        $result_values->[$_] +=  $tuple->[$_] * $add_amount->[$color_nr] for 0 .. $#$tuple;
    }
    return $base_color->new_from_tuple( $result_values, $color_space->name );
}

sub invert {
    my ($color_values, $only, $raw, $color_space, $default_color_space ) = @_;
    $only = [$only] if defined $only and not ref $only; # selected axes
    return "need argument only as axis name (short or long) or as ARRAY of names!"
		if defined $only and ref $only ne 'ARRAY';
    if (defined $only){
		my %partial_hash = map { $_ => 1 } @$only;
		my $preselected_space_name = defined($color_space) ? $color_space->name : undef;
		my ($new_values, $deduced_space_name) =
			Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( \%partial_hash, $preselected_space_name );
		return "could not find any color space that contains the axes: ". join(', ', @$only).' !' 
			if not defined $deduced_space_name and not defined $color_space;
		return "axes ". join(', ', @$only) . 'do not match color space '.$color_space->name.' !'
			if not defined $deduced_space_name and ref $color_space;
		$color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $deduced_space_name );
	}
	$color_space //= $default_color_space;
    
    my $selected_axis = (defined $only) ? [ ] : [$color_space->basis->axis_iterator];
    if (defined $only) {
	    for my $axis_name (@$only){
		    my $pos = $color_space->pos_from_axis_role( $axis_name );
			$selected_axis->[$pos] = $pos;
		}
	} 
    my $tuple = $color_values->normalized( $color_space->name );
	for my $axis_nr ($color_space->basis->axis_iterator){
        next unless defined $selected_axis->[$axis_nr];
        if ($color_space->shape->is_axis_euclidean( $axis_nr )){
            $tuple->[$axis_nr] = 0.5 - ($tuple->[$axis_nr] - 0.5);
        } else {
			$tuple->[$axis_nr]++ while $tuple->[$axis_nr] < 0;
			$tuple->[$axis_nr]-- while $tuple->[$axis_nr] > 1;
            $tuple->[$axis_nr] = ($tuple->[$axis_nr] < 0.5)
                                ? $tuple->[$axis_nr] + 0.5
                                : $tuple->[$axis_nr] - 0.5;
        }
	}
    return $color_values->new_from_tuple( $tuple, $color_space->name, 'normal' );
}
 
1;
