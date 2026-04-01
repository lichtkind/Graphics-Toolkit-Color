
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_Lrgb {
    my ($rgb) = shift;
    return [ mult_matrix_vector_3(
      [[ 0.4124564390896922,  0.3575760776439085,  0.1804374832663984 ],
       [ 0.2126728514056225,  0.7151521858367423,  0.0721750627576214 ],
       [ 0.0193338955823282,  0.1191920257022860,  0.9503040785363677 ] ], @$rgb) ];
}
sub to_Lrgb {
    my ($xyz) = shift;
    return [ mult_matrix_vector_3(
      [[  3.2404542361, -1.5371385128, -0.4985314095 ],
       [ -0.9692660305,  1.8760108456,  0.0415560173 ],
       [  0.0556434224, -0.2040258530,  1.0572251881 ] ], @$xyz) ];
}

Graphics::Toolkit::Color::Space->new(
       alias => 'CIEXYZ',
        axis => [qw/X Y Z/],
       range => [95.047, 100, 108.8830],
   precision => 3,
     convert => {LinearRGB => [\&to_Lrgb, \&from_Lrgb]},
);
