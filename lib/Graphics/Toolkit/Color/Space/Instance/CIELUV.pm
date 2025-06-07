
# CIE LUV color space specific code based on XYZ for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::CIELUV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix3 apply_d65 remove_d65/;

my  $luv_def = Graphics::Toolkit::Color::Space->new( prefix => 'CIE',
                                                       axis => [qw/L* u* v*/], # cyan-orange balance, magenta-green balance
                                                      range => [100, [-100, 175], [-140, 110]] );


$luv_def->add_converter('CIEXYZ', \&to_rgb, \&from_rgb );

my @D65 = (0.95047, 1, 1.08883); # illuminant
my $eta = 0.008856 ;
my $kappa = 903.3 / 100;

sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my (@xyz) = mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                             [0.3575761, 0.7151522, 0.1191920],
                             [0.1804375, 0.0721750, 0.9503041]], apply_d65($r), apply_d65($g), apply_d65($b));

    my $yr = $xyz[1] / $D65[1];
    my $L = ($yr > $eta) ? ((1.16 * ($yr **(1/3)))-.16) : ($kappa * $yr);
#say "XYZ: @xyz $yr";
    return (0,0,0) unless $L;
    my $strich_nenner = $xyz[0] + (15 * $xyz[1]) + (3 * $xyz[2]);
    my $r_nenner      = $D65[0] + (15 * $D65[1]) + (3 * $D65[2]);
    my $u_strich = 4 * $xyz[0] / $strich_nenner;
    my $v_strich = 9 * $xyz[1] / $strich_nenner;
    my $ur       = 4 * $D65[0] / $r_nenner;
    my $vr       = 9 * $D65[1] / $r_nenner;
#say "Luv ", ($L,',', 13 * ($u_strich - $ur),',', 13 * ($v_strich - $vr)), " :: $u_strich - $ur";
    # @{$lab_def->normalize()};
    return ($L, 13 * ($u_strich - $ur), 13 * ($v_strich - $vr)); # Luv
}


sub to_rgb {
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
