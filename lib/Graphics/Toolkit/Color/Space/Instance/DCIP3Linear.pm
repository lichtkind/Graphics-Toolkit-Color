
# DCI-P3, with original Theater-Whitepoint [0.89459, 1.0, 0.95442]

package Graphics::Toolkit::Color::Space::Instance::DCIP3Linear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_xyz {
    my ($xyz) = shift;
    return [ mult_matrix_vector_3(
               [[  2.7253940305, -1.0180030062, -0.4401631952 ],
                [ -0.7951680258,  1.6897320548,  0.0226471906 ],
                [  0.0412418914, -0.0876390192,  1.1009293786 ], ], @$xyz) ];
}
sub to_xyz {
	my ($lrgb) = shift;
    return [ mult_matrix_vector_3(
              [[ 0.4451698156,  0.2771344092,  0.1722826698 ],
               [ 0.2094916779,  0.7215952542,  0.0689130679 ],
               [ 0.0000000000,  0.0470605601,  0.9073553944 ], ], @$lrgb) ];
}

 
Graphics::Toolkit::Color::Space->new(
        name => 'dci-p3-linear',
       alias => 'Linear DCI-P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);

__END__

[  2.6901363967, -1.0940624767, -0.4250723022 ],
[ -0.8200938994,  1.7505139921,  0.0265979630 ],
[  0.0362539300, -0.0785946720,  0.9589526318 ],

[  0.4592758400,  0.2958171474,  0.1953770175 ],
[  0.2151608649,  0.7091342514,  0.0757048839 ],
[  0.0002710702,  0.0469362492,  1.0416226857 ],
