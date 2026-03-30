
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

my @D65 = (0.95047, 1, 1.088830);

# change normalized RGB values to and from standard observer 2°
sub apply_observer  { $_[0] > 0.04045  ? ((($_[0] + 0.055) / 1.055 ) ** 2.4) : ($_[0] / 12.92) }
sub remove_observer { $_[0] > 0.003131 ? ((($_[0]**(1/2.4)) * 1.055) - 0.055) : ($_[0] * 12.92) }

sub from_rgb {
    my ($rgb) = shift;
    my @rgb = map {apply_observer( $_ )} @$rgb;
    return [ mult_matrix_vector_3([[0.433949941, 0.37620977,  0.18984029], # conversion + normalisation
                                   [0.2126729,   0.7151522,   0.0721750],
                                   [0.017756583, 0.109467961, 0.872775456]], @rgb) ];
}
sub to_rgb {
    my ($xyz) = shift;
    my @rgb = mult_matrix_vector_3([[  3.07996,   -1.53714 , -0.542816 ],
                                    [ -0.921259 ,  1.87601 ,  0.0452475],
                                    [  0.0528874, -0.204026,  1.15114  ]], @$xyz);
    return [ map { remove_observer($_) } @rgb ];
}

Graphics::Toolkit::Color::Space->new(
       alias => 'CIEXYZ',
        axis => [qw/X Y Z/],
       range => [map {$D65[$_] * 100} 0 .. 2],
   precision => 3,
     convert => {RGB => [\&to_rgb, \&from_rgb]},
);

__END__

my $sRGB_to_XYZ = [
    [ 0.4124564390896922,  0.3575760776439085,  0.1804374832663984 ],
    [ 0.2126728514056225,  0.7151521858367423,  0.0721750627576214 ],
    [ 0.0193338955823282,  0.1191920257022860,  0.9503040785363677 ]
];

my $XYZ_to_sRGB = [
    [  3.2404542361, -1.5371385128, -0.4985314095 ],
    [ -0.9692660305,  1.8760108456,  0.0415560173 ],
    [  0.0556434224, -0.2040258530,  1.0572251881 ]
];
