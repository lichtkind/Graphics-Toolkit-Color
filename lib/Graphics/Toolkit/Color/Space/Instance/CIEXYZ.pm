
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_Lrgb {
    my ($rgb) = shift;
    return [ mult_matrix_vector_3([[0.433949941, 0.37620977,  0.18984029], # conversion + normalisation
                                   [0.2126729,   0.7151522,   0.0721750],
                                   [0.017756583, 0.109467961, 0.872775456]], @$rgb) ];
}
sub to_Lrgb {
    my ($xyz) = shift;
    return [ mult_matrix_vector_3([[  3.07996,   -1.53714 , -0.542816 ],
                                   [ -0.921259 ,  1.87601 ,  0.0452475],
                                   [  0.0528874, -0.204026,  1.15114  ]], @$xyz) ];
}

Graphics::Toolkit::Color::Space->new(
       alias => 'CIEXYZ',
        axis => [qw/X Y Z/],
       range => [95.047, 100, 108.8830],
   precision => 3,
     convert => {LinearRGB => [\&to_Lrgb, \&from_Lrgb]},
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
