use v5.12;
use warnings;

# CIE LUV color space specific code based on XYZ for Illuminant D65 and Observer 2\x{00b0}

package Graphics::Toolkit::Color::Space::Instance::LUV;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util qw/mult_matrix apply_d65 remove_d65/;


                                                                    # cyan-orange balance, magenta-green balance
my  $luv_def = Graphics::Toolkit::Color::Space->new( axis => [qw/L* u* v*/],
                                                   prefix => 'CIE',
                                                    range => [1, 1, 1] );

    $luv_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($r, $g, $b) = @_;
    return mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                        [0.3575761, 0.7151522, 0.1191920],
                        [0.1804375, 0.0721750, 0.9503041]], apply_d65( $r ), apply_d65( $g ), apply_d65( $b ));
}

sub to_rgb {
    my ($x, $y, $z) = @_;
    my ($r, $g, $b) = mult_matrix([[ 3.2404542, -0.9692660,  0.0556434],
                                   [-1.5371385,  1.8760108, -0.2040259],
                                   [-0.4985314,  0.0415560,  1.0572252]], $x, $y, $z);

    return ( remove_d65($r), remove_d65($g), remove_d65($b));
}

$luv_def;
