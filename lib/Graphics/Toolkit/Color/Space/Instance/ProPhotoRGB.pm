
# Pro Photo RGB (illuminant D50, gamma 1.8)

package Graphics::Toolkit::Color::Space::Instance::ProPhotoRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct mult_matrix_vector_3/;

my @D50   = (0.96422, 1, 0.82521);
my $eta   =  0.001953;
my $gamma =  1.8;

sub from_xyz {
    my ($xyz) = [ @{$_[0]} ];
    $xyz->[$_] *= $D50[ $_ ] for 0 .. 2;
    my @rgb = mult_matrix_vector_3( [[  1.3459433, -0.2556075, -0.0511118 ],
                                     [ -0.5445989,  1.5081673,  0.0205351 ], 
                                     [  0.0000000,  0.0000000,  1.2118128 ]  ], @$xyz);

    return [map { (abs($_) <= $eta) ? ($_ * 16) : gamma_correct($_, 1 / $gamma)} @rgb];
}
sub to_xyz {
	my @rgb = map { (abs($_) <= 16 * $eta) ? ($_ / 16) : gamma_correct( $_, $gamma ) } @{$_[0]};

    my @xyz = mult_matrix_vector_3( [[ 0.7976749,  0.1351917,  0.0313534 ],
                                     [ 0.2880402,  0.7118741,  0.0000857 ],
                                     [ 0.0000000,  0.0000000,  0.8252100 ] ], @rgb);
    $xyz[$_] /= $D50[ $_ ] for 0 .. 2;
    return \@xyz;
}

Graphics::Toolkit::Color::Space->new(
        name => 'ProPhotoRGB',
       alias => 'ROMMRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);


# (( 0,096422 * -0,5445989)+(0,01 * 1,5081673 )+(0,7839495 * 0,0205351))^(1÷1,8)
# (( 0,096422 * )+(0,01 * )+(0,7839495*)) ^(1÷1,8)
# ^(1÷1,8)
#
