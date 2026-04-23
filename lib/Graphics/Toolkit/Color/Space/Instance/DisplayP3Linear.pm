
# Display P3, D65, linear (no transfer)

package Graphics::Toolkit::Color::Space::Instance::DisplayP3Linear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_xyz {
    my ($xyz) = shift;
    return [ mult_matrix_vector_3(
               [[  2.4039840,  -0.9899069,  -0.3976415 ],
                [ -0.8422229,   1.7988437,   0.0160354 ], 
                [  0.0482059,  -0.0974068,   1.2740049 ]  ], @$xyz) ];
}
sub to_xyz {
	my ($lrgb) = shift;
    return [ mult_matrix_vector_3(
              [[  0.5151187,  0.2919778,  0.1571035 ],
               [  0.2411892,  0.6922441,  0.0665668 ],
               [ -0.0010505,  0.0418791,  0.7840713 ] ], @$lrgb) ];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'display-p3-linear',
       alias => 'Linear Display P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
