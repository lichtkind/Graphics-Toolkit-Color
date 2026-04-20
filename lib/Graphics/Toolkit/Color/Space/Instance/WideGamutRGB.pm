
# Wide Gamut RGB, D50 (Adobe)

package Graphics::Toolkit::Color::Space::Instance::WideGamutRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct mult_matrix_vector_3/;

my @D50   = (0.96422, 1, 0.82521);
my $gamma = 563/256;

sub from_xyz {
    my ($xyz) = [ @{$_[0]} ];
    $xyz->[$_] *= $D50[ $_ ] for 0 .. 2;
    my @rgb = mult_matrix_vector_3( [[  1.4628067, -0.1840623, -0.2743606 ],
                                     [ -0.5217933,  1.4472381,  0.0677227 ], 
                                     [  0.0349342, -0.0968930,  1.2884099 ]  ], @$xyz);
    return [map {gamma_correct($_, (1/$gamma))} @rgb];
}
sub to_xyz {
	my $rgb = shift;
	$rgb = [map {gamma_correct($_, $gamma)} @$rgb];
    my @xyz = mult_matrix_vector_3( [[ 0.7161046,  0.1009296,  0.1471858 ],
                                     [ 0.2581874,  0.7249378,  0.0168748 ],
                                     [ 0.0000000,  0.0517813,  0.7734287 ] ], @$rgb) ;
    $xyz[$_] /= $D50[ $_ ] for 0 .. 2;
    return \@xyz;
} 
 
Graphics::Toolkit::Color::Space->new(
        name => 'WideGamutRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
