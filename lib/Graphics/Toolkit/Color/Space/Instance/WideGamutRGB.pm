
# Wide Gamut RGB, D50

package Graphics::Toolkit::Color::Space::Instance::WideGamutRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/power mult_matrix_vector_3/;

my $gamma = 563/256;

sub from_xyz {
    my ($xyz) = shift;
    my @rgb = mult_matrix_vector_3(
      [[  1.4628067, -0.1840623, -0.2743606 ],
       [ -0.5217933,  1.4472381,  0.0677227 ], 
       [  0.0349342, -0.0968930,  1.2884099 ]  ], @$xyz);
    return [map {power($_, (256/563))} @rgb];
}
sub to_xyz {
	my $rgb = shift;
	$rgb = [map {power($_, 563/256)} @$rgb];
    return [ mult_matrix_vector_3(
      [[ 0.7161046,  0.1009296,  0.1471858 ],
       [ 0.2581874,  0.7249378,  0.0168748 ],
       [ 0.0000000,  0.0517813,  0.7734287 ] ], @$rgb) ];
} 
 
Graphics::Toolkit::Color::Space->new(
        name => 'WideGamutRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {CIEXYZ => [\&to_xyz, \&from_xyz]},
);
