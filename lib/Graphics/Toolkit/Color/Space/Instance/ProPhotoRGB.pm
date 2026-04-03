
# 

package Graphics::Toolkit::Color::Space::Instance::ProPhotoRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_xyz {
    [ mult_matrix_vector_3( [[  2.36461385, -0.89654057, -0.46807328 ],
                             [ -0.51516621,  1.42640810,  0.08875810 ], 
                             [  0.00520370, -0.01440816,  1.00920458 ]  ], @{$_[0]}) ];
}
sub to_xyz {
    [ mult_matrix_vector_3( [[ 0.49000,  0.31000,  0.20000 ],
                             [ 0.17697,  0.81240,  0.01063 ],
                             [ 0.00000,  0.01000,  0.99000 ] ], @{$_[0]}) ];
}

Graphics::Toolkit::Color::Space->new(
        name => 'ProPhotoRGB',
       alias => 'ROMMRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
