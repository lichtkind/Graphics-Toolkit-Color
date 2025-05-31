
# CIE LCh(ab) cylindrical color space specific code

package Graphics::Toolkit::Color::Space::Instance::CIELCHab;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util qw/mult_matrix apply_d65 remove_d65/;

my  $hcl_def = Graphics::Toolkit::Color::Space->new(prefix => 'CIE', name => 'LCHab', alias => 'LCH',
                                                      axis => [qw/luminance croma hue/],
                                                     range => [100, 539, 360] );

    $hcl_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($r, $g, $b) = @_;
    my ($x, $y, $z) = mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                                   [0.3575761, 0.7151522, 0.1191920],
                                   [0.1804375, 0.0721750, 0.9503041]],
                                   apply_d65( $r ), apply_d65( $g ), apply_d65( $b ));
    $x /= 0.95047;
    $z /= 0.108883;

    $x = ($x > 0.008856) ? ($x ** (1/3)) : (7.7870689 * $x + 0.137931034);
    $y = ($y > 0.008856) ? ($y ** (1/3)) : (7.7870689 * $y + 0.137931034);
    $z = ($z > 0.008856) ? ($z ** (1/3)) : (7.7870689 * $z + 0.137931034);

    return ((116 * $y) - 16, $a = 500 * ($x - $y), 200 * ($y - $z));
}


sub to_rgb {
    my ($l, $a, $b) = @_;
    my $y = ($l + 16) / 116;
    my $x = ($a / 500) + $y;
    my $z = $y - ($b / 200);
    $x = ($x**3 > 0.008856) ? ($x ** 3) : (($x - 0.137931034) / 7.7870689);
    $y = ($y**3 > 0.008856) ? ($y ** 3) : (($y - 0.137931034) / 7.7870689);
    $z = ($z**3 > 0.008856) ? ($z ** 3) : (($z - 0.137931034) / 7.7870689);
    $x *= 0.95047;
    $z *= 0.108883;
    my ($r, $g, $bl) = mult_matrix([[ 3.2404542, -0.9692660,  0.0556434],
                                    [-1.5371385,  1.8760108, -0.2040259],
                                    [-0.4985314,  0.0415560,  1.0572252]], $x, $y, $z);

    return ( remove_d65($r), remove_d65($g), remove_d65($bl));
}


$hcl_def;
