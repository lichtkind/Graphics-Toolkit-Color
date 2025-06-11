
# CIE LUV color space specific code based on XYZ for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::CIELUV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my  $luv_def = Graphics::Toolkit::Color::Space->new( prefix => 'CIE',           # space name is CIELUV, alias LUV
                                                       axis => [qw/L* u* v*/],  # short l u v
                                                      range => [100, [-134, 220], [-140, 122]],
                                                  precision => 3 );

$luv_def->add_converter('CIEXYZ', \&to_xyz, \&from_xyz );

my @D65 = (0.95047, 1, 1.08883); # illuminant
my $eta = 0.008856 ;
my $kappa = 903.3;

sub from_xyz {
    my ($xyz) = shift;
    my @XYZ = map { $xyz->[$_] * $D65[$_] } 0 .. 2;

    my $color_mix = $XYZ[0] + (15 * $XYZ[1]) + (3 * $XYZ[2]);
    my $u_color = 4 * $XYZ[0] / $color_mix;
    my $v_color = 9 * $XYZ[1] / $color_mix;
    my $white_mix = $D65[0] + (15 * $D65[1]) + (3 * $D65[2]);
    my $u_white = 4 * $D65[0] / $white_mix;
    my $v_white = 9 * $D65[1] / $white_mix;

    my $l = ($xyz->[1] > $eta) ? (($xyz->[1] ** (1/3)) * 116 - 16) : ($kappa * $xyz->[1]);
    my $u = 13 * $l * ($u_color - $u_white);
    my $v = 13 * $l * ($v_color - $v_white);
    return ( $l / 100 , ($u+134) / 354, ($v+140) / 262 );
}


sub to_xyz {
    my ($L, $u, $v) = @{$_[0]};

    my $r_nenner = $D65[0] + (15 * $D65[1]) + (3 * $D65[2]);
    my $u0 = 4 * $D65[0] / $r_nenner;
    my $v0 = 9 * $D65[1] / $r_nenner;

    my $Y = ($L > ($kappa*$eta)) ? (($L+.16)/1.16)**3 : $L / $kappa;
    my @xyz;
    if ($Y){
        my $a = (( 52 * $L / ($u + (13 * $L * $u0)) ) -1) / 3;
        my $b = -5 * $Y;
        my $d = $Y * ((39 * $L / ($v + (13 * $L* $v0))) - 5);
        my $X = ($d - $b) / ($a + (1/3));
        @xyz = ($X, $Y, $X * $a + $b);
    } else { @xyz = (0,0,0) }
#say "xyz @xyz";
    # @xyz = map { $xyz[$_] * $D65[$_] } 0 .. 2;
    my (@rgb) = mult_matrix([[ 3.2404542, -0.9692660,  0.0556434],
                             [-1.5371385,  1.8760108, -0.2040259],
                             [-0.4985314,  0.0415560,  1.0572252]], @xyz);

#say "rgb @rgb";
    return ( map { remove_d65($_) } @rgb );
}

$luv_def;
