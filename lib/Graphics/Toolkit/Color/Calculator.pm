
# methods to compute related color

package Graphics::Toolkit::Color::Calculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;


sub set_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash(
                                        $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : 'any supported color space!';
    }
    my $values = $color_values->shaped( $space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $values->[$pos] = $new_values->[$pos] if defined $new_values->[$pos];
    }
    $color_values->new_from_tuple( $values, $color_space->name );
}

sub add_value { # .values, %newval -- ~space_name --> _
    my ($color_values, $partial_hash, $preselected_space_name) = @_;
    my ($new_values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash(
                                        $partial_hash, $preselected_space_name );
    unless (ref $new_values){
        my $help_start = 'axis names: '.join(', ', keys %$partial_hash).' do not correlate to ';
        return (defined $preselected_space_name) ? $help_start.'the selected color space: '.$preselected_space_name.'!'
                                                 : 'any supported color space!';
    }
    my $values = $color_values->shaped( $space_name );
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    for my $pos ($color_space->basis->axis_iterator) {
        $values->[$pos] += $new_values->[$pos] if defined $new_values->[$pos];
    }
    $color_values->new_from_tuple( $values, $color_space->name );
}

sub mix { #  @%(+percent, _color)  -- ~space_name --> _
    my ($color_values, $recipe, $color_space ) = @_;
    return if ref $recipe ne 'ARRAY';
    my $result_values = [(0) x $color_space->axis_count];
    for my $ingredient (@$recipe){
        return if ref $ingredient ne 'HASH' or not exists $ingredient->{'percent'}
               or not exists $ingredient->{'color'} or ref $ingredient->{'color'} ne ref $color_values;
        my $values = $ingredient->{'color'}->shaped( $color_space->name );
        $result_values->[$_] +=  $values->[$_] * $ingredient->{'percent'} / 100 for 0 .. $#$values;
    }
    $color_values->new_from_tuple( $result_values, $color_space->name );
}

sub apply_gamma {
    my ($color_values, $gamma, $color_space) = @_;
}


sub invert {
    my ($color_values, $color_space ) = @_;
    my $values = $color_values->normalized( $color_space->name );
    $color_values->new_from_tuple( [ map {1 - $_} @$values ], $color_space->name, 'normal' );
}

1;
