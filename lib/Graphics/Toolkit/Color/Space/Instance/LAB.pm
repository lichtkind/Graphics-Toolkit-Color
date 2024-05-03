use v5.12;
use warnings;

# CIE LAB color space specific code based on XYZ for Illuminant D65 and Observer 2\x{00b0}

package Graphics::Toolkit::Color::Space::Instance::LAB;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util qw/mult_matrix apply_d65 remove_d65/;

my  $lab_def = Graphics::Toolkit::Color::Space->new( prefix => 'CIE',           # space name is CIELAB
                                                       axis => [qw/L* a* b*/],  # short l a b
                                                      range => [100, [-500, 500], [-200, 200]],
                                                  precision => 3 );

    $lab_def->add_converter('RGB', \&to_rgb, \&from_rgb );

my @xyz_range = (0.95047, 1, 1.08883);

sub from_rgb {
    my ($r, $g, $b) = @{$_[0]};
    my ($x, $y, $z) = mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                                   [0.3575761, 0.7151522, 0.1191920],
                                   [0.1804375, 0.0721750, 0.9503041]],
                                   apply_d65( $r ), apply_d65( $g ), apply_d65( $b ));
say "x y z $x, $y, $z";
    $x /= 0.95047;
    $z /= 0.108883;

    $x = ($x > 0.008856) ? ($x ** (1/3)) : (7.7870689 * $x + 0.137931034);
    $y = ($y > 0.008856) ? ($y ** (1/3)) : (7.7870689 * $y + 0.137931034);
    $z = ($z > 0.008856) ? ($z ** (1/3)) : (7.7870689 * $z + 0.137931034);

    return ((116 * $y) - 16, $a = 500 * ($x - $y), 200 * ($y - $z));
}


sub to_rgb {
    my ($l, $a, $b) = @{$_[0]};
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

$lab_def;
