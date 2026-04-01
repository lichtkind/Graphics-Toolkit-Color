
# Adobe RGB (1998) color space, IEC 61966-2-5:2007, ISO 12640-4:2011

package Graphics::Toolkit::Color::Space::Instance::AdobeRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix_vector_3/;

sub from_xyz {
    my ($xyz) = shift;
    return [ mult_matrix_vector_3(
      [[  2.36461385, -0.89654057, -0.46807328 ],
       [ -0.51516621,  1.42640810,  0.08875810 ], 
       [  0.00520370, -0.01440816,  1.00920458 ]  ], @$xyz) ];
}
sub to_xyz {
    my ($rgb) = shift;
    return [ mult_matrix_vector_3(
      [[ 0.49000,  0.31000,  0.20000 ],
       [ 0.17697,  0.81240,  0.01063 ],
       [ 0.00000,  0.01000,  0.99000 ] ], @$rgb) ];
}

Graphics::Toolkit::Color::Space->new(
        name => 'CIERGB',
       alias => 'opRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {CIEXYZ => [\&to_xyz, \&from_xyz]},
);

__END__

my $XYZ_to_A98RGB = [
    [  2.0415879038, -0.5650069743, -0.3447313508 ],
    [ -0.9692436363,  1.8759675015,  0.0415550574 ],
    [  0.0134442803, -0.1183623924,  1.0154095990 ]
];

$gamma = 563/256;

my $A98RGB_to_XYZ = [
    [ 0.5766690422,  0.1855582373,  0.1882286733 ],
    [ 0.2973445754,  0.6273635663,  0.0752919193 ],
    [ 0.0270313614,  0.0706888730,  0.9913375368 ]
];
