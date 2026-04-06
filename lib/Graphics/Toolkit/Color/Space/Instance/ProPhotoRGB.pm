
# Pro Photo RGB (illuminant D50, gamma 1.8)

package Graphics::Toolkit::Color::Space::Instance::ProPhotoRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/power mult_matrix_vector_3/;

my $eta = 0.001953;
my $gamma = 1.8;

sub from_xyz {
	my $xyz = shift;
    my @rgb = mult_matrix_vector_3( [[  1.3459433, -0.2556075, -0.0511118 ],
                                     [ -0.5445989,  1.5081673,  0.0205351 ], 
                                     [  0.0000000,  0.0000000,  1.2118128 ]  ], @$xyz);

    return [map { ($_ <= $eta) ? ($_ * 16) : power($_, 1 / $gamma)} @rgb];
}
sub to_xyz {
	my @rgb = map { ($_ <= 16 * $eta) ? ($_ / 16) : power( $_, $gamma ) } @{$_[0]};

    return [ mult_matrix_vector_3( [[ 0.7976749,  0.1351917,  0.0313534 ],
                                    [ 0.2880402,  0.7118741,  0.0000857 ],
                                    [ 0.0000000,  0.0000000,  0.8252100 ] ], @rgb) ];
}

Graphics::Toolkit::Color::Space->new(
        name => 'ProPhotoRGB',
       alias => 'ROMMRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
