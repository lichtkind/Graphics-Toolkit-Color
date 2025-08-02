
# calculating related colors

package Graphics::Toolkit::Color::Calculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;


########################################################################
sub set { # %val --> _
    my ($self, $val_hash, $selected_space_name) = @_;
    my $selected_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $selected_space_name );
    return $selected_space unless ref $selected_space;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $val_hash, $selected_space_name );
    return 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my $values = $self->in_shape( $space_name ); # convert and denormalize values
    for my $pos (keys %$pos_hash){
        $values->[$pos] = $pos_hash->{ $pos };
    }
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    __PACKAGE__->new_from_normal_tuple( $color_space->normalize($values), $color_space->name );
}

sub add { # %val --> _
    my ($self, $val_hash, $selected_space_name) = @_;
    my $selected_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $selected_space_name );
    return $selected_space unless ref $selected_space;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $val_hash, $selected_space_name );
    return 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my $values = $self->in_shape( $space_name ); # convert and denormalize values
    for my $pos (keys %$pos_hash){
        $values->[$pos] += $pos_hash->{ $pos };
    }
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    __PACKAGE__->new_from_normal_tuple( $color_space->normalize($values), $space_name);
}

sub mix { #  @%(+percent _values)  -- ~space_name --> _values
    my ($self, $recipe, $space_name ) = @_;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return $color_space unless ref $color_space;
    return if ref $recipe ne 'ARRAY';
    my $percentage_sum = 0;
    for my $ingredient (@{$recipe}){
        return if ref $ingredient ne 'HASH' or not exists $ingredient->{'percent'};
        return if ref $ingredient ne 'HASH' or not exists $ingredient->{'percent'}
               or not exists $ingredient->{'color'} or ref $ingredient->{'color'} ne __PACKAGE__;
        $percentage_sum += $ingredient->{'percent'};
    }
    my $result = [(0) x $color_space->axis_count];
    if ($percentage_sum < 100){
        my $values = $self->in_shape( $space_name );
        my $mix_amount = (100 - $percentage_sum) / 100;
        $result->[$_] +=  $values->[$_] * $mix_amount for 0 .. $#$values;
    } else {
        $percentage_sum /= 100;
        $_->{'percent'} /= $percentage_sum for @{$recipe}; # sum of percentages has to be 100
    }
    for my $ingredient (@$recipe){
        my $values = $ingredient->{'color'}->in_shape ($space_name);
        $result->[$_] +=  $values->[$_] * $ingredient->{'percent'} / 100 for 0 .. $#$values;
    }
    __PACKAGE__->new_from_normal_tuple( $color_space->normalize( $result ), $space_name );
}

sub invert {
    my ($self, $space_name ) = @_;

}

1;
