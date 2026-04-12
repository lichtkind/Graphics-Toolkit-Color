
# Display P3, D65 same transfer function as SRGB

package Graphics::Toolkit::Color::Space::Instance::DisplayP3;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/power mult_matrix_vector_3/;

my $gamma = 2.4;

sub from_xyz {
    my ($xyz) = shift;
    my @rgb = mult_matrix_vector_3(
      [[  2.4039840,  -0.9899069,  -0.3976415 ],
       [ -0.8422229,   1.7988437,   0.0160354 ], 
       [  0.0482059,  -0.0974068,   1.2740049 ]  ], @$xyz);
    return [ map { ($_ > 0.0031308) ? ( (power($_, 1/$gamma) *  1.055) - 0.055) 
		                            :         ($_            * 12.92)          } @rgb ];
}
sub to_xyz {
	my ($rgb) = shift;
	my @rgb = map {  ($_ > 0.04045)  ? power((($_ + 0.055) /  1.055 ), $gamma) 
                                     :        ($_          / 12.92)           } @$rgb;
    return [ mult_matrix_vector_3(
              [[  0.5151187,  0.2919778,  0.1571035 ],
               [  0.2411892,  0.6922441,  0.0665668 ],
               [ -0.0010505,  0.0418791,  0.7840713 ] ], @rgb) ];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'AdobeRGB',
       alias => 'opRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {CIEXYZ => [\&to_xyz, \&from_xyz]},
);
