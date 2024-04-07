use v5.12;
use warnings;

# XYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::XYZ;
use Graphics::Toolkit::Color::Space;

my  $xyz_def = Graphics::Toolkit::Color::Space->new( axis => [qw/X Y Z/], #
                                                   prefix => 'CIE',
                                                    range => [0.95047, 1, 1.08883] );

    $xyz_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($r, $g, $b) = @_;
    return mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                        [0.3575761, 0.7151522, 0.1191920],
                        [0.1804375, 0.0721750, 0.9503041]], apply_d65( $r ), apply_d65( $g ), apply_d65( $b ));
}

sub to_rgb {
    my ($x, $y, $z) = @_;
    my ($r, $g, $b) = mult_matrix([[ 3.2404542, -1.5371385, -0.4985314],
                                   [-0.9692660,  1.8760108,  0.0415560],
                                   [ 0.0556434, -0.2040259,  1.0572252]], $x, $y, $z);

    #~ my $r =  ( 3.2404542 * $x) + (-1.5371385 * $y) + (-0.4985314 * $z);
    #~ my $g =  (-0.9692660 * $x) + ( 1.8760108 * $y) + ( 0.0415560 * $z);
    #~ my $b =  ( 0.0556434 * $x) + (-0.2040259 * $y) + ( 1.0572252 * $z);

    return ( remove_d65($r), remove_d65($g), remove_d65($b));
}

sub apply_d65  { $_[0] > 0.04045  ? ((($_[0] + 0.055) / 1.055 ) ** 2.4) : ($_[0] / 12.92) }
sub remove_d65 { $_[0] > 0.003131 ? ((($_[0]**(1/2.4)) * 1.055) - 0.055) : ($_[0] * 12.92) }
sub mult_matrix {
    my ($mat, $v1, $v2, $v3) = @_;
    return unless ref $mat eq 'ARRAY' and defined $v3;
    return ($v1 * $mat->[0][0] + $v2 * $mat->[1][0] + $v3 * $mat->[2][0]) ,
           ($v1 * $mat->[0][1] + $v2 * $mat->[1][1] + $v3 * $mat->[2][1]) ,
           ($v1 * $mat->[0][2] + $v2 * $mat->[1][2] + $v3 * $mat->[2][2]) ;
}

$xyz_def;

__END__
