
# CIE LAB color space specific code based on XYZ for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::CIELAB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util qw/mult_matrix apply_d65 remove_d65/;

my  $lab_def = Graphics::Toolkit::Color::Space->new( prefix => 'CIE',           # space name is CIELAB
                                                       axis => [qw/L* a* b*/],  # short l a b
                                                      range => [100, [-500, 500], [-200, 200]],
                                                  precision => 3 );

    $lab_def->add_converter('CIEXYZ', \&to_rgb, \&from_rgb );

my @D65 = (0.95047, 1, 1.08883); # illuminant
my $eta = 0.008856 ;
my $kappa = 903.3 / 100;

sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my (@xyz) = mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                             [0.3575761, 0.7151522, 0.1191920],
                             [0.1804375, 0.0721750, 0.9503041]], apply_d65($r), apply_d65($g), apply_d65($b));
    @xyz = map { $xyz[$_] / $D65[$_] } 0 .. 2;
    @xyz = map { $_ > $eta ? ($_ ** (1/3)) : ((($kappa * $_) + .16) / 1.16) } @xyz;

    return ((1.16 * $xyz[1]) - .16, ($xyz[0] - $xyz[1] + 1) / 2, (($xyz[1] - $xyz[2] + 1) / 2)); # l a b
}


sub to_rgb {
    my ($l, $a, $b) = @{$_[0]};
    my $y = ($l + .16) / 1.16;
    my $x = $y + (($a * 2)-1);
    my $z = $y - (($b * 2)-1);

    $x = ($x**3 > $eta)            ? ($x ** 3) : ($kappa * (($x * 1.16) - .16));
    $y = ($y**3 > ($eta * $kappa)) ? ($y ** 3) : ($kappa * $l);
    $z = ($z**3 > $eta)            ? ($z ** 3) : ($kappa * (($z * 1.16) - .16));

    $x *= $D65[0];
    $z *= $D65[2];
    my (@rgb) = mult_matrix([[ 3.2404542, -0.9692660,  0.0556434],
                             [-1.5371385,  1.8760108, -0.2040259],
                             [-0.4985314,  0.0415560,  1.0572252]], $x, $y, $z);

    return ( map { remove_d65($_) } @rgb );
}

$lab_def;
