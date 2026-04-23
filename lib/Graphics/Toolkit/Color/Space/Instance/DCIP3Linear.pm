
# DCI-P3

package Graphics::Toolkit::Color::Space::Instance::DCIP3Linear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;


sub from_xyz {
    my ($xyz) = shift;
    return [ mult_matrix_vector_3(
               [[  2.7253940305, -1.0180030062, -0.4401631952 ]
                [ -0.7951680258,  1.6897320548,  0.0226471906 ]
                [  0.0412418914, -0.0876390192,  1.1009293786 ] ], @$xyz) ];
}
sub to_xyz {
	my ($lrgb) = shift;
    return [ mult_matrix_vector_3(
              [[ 0.4451698156,  0.2771344092,  0.1722826698 ]
               [ 0.2094916779,  0.7215952542,  0.0689130679 ]
               [ 0.0000000000,  0.0470605601,  0.9073553944 ] ], @$lrgb) ];
}

 
Graphics::Toolkit::Color::Space->new(
        name => 'DCI-P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
