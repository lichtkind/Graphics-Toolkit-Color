
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_Lrgb {
    [ mult_matrix_vector_3(
      [[ 0.41245643909,  0.3575760776,  0.1804374833 ],
       [ 0.21267285141,  0.7151521858,  0.0721750628 ],
       [ 0.01933389558,  0.1191920257,  0.9503040785 ] ], @{$_[0]}) ];
}
sub to_Lrgb {
    [ mult_matrix_vector_3(
      [[  3.2404542361, -1.5371385128, -0.4985314095 ],
       [ -0.9692660305,  1.8760108456,  0.0415560173 ],
       [  0.0556434224, -0.2040258530,  1.0572251881 ] ], @{$_[0]}) ];
}

Graphics::Toolkit::Color::Space->new(
       alias => 'CIEXYZ',  # name is XYZ
        axis => [qw/X Y Z/],
       range => [95.047, 100, 108.883],
   precision => 3,
     convert => {LinearRGB => [\&to_Lrgb, \&from_Lrgb, {from => {in => 1, out => 0}, to => {in => 0, out => 1}}] },
);
