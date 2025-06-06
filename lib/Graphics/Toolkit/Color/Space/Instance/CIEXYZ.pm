
# CIEXYZ color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIEXYZ;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/mult_matrix3 apply_d65 remove_d65/;

my @range_max = (0.95047, 1, 1.088830);
my  $xyz_def = Graphics::Toolkit::Color::Space->new( prefix => 'CIE',
                                                       axis => [qw/X Y Z/],
                                                      range => [map {$range_max[$_] * 100} 0 .. 2],
                                                  precision => 3, );

    $xyz_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($rgb) = shift;
    my @RGB = map {apply_d65( $_ )} @$rgb;
    my (@xyz) =  mult_matrix3([[0.4124564, 0.2126729, 0.0193339],
                               [0.3575761, 0.7151522, 0.1191920],
                               [0.1804375, 0.0721750, 0.9503041]], @RGB);

    return (map {$xyz[$_] / $range_max[$_]} 0 .. 2);
}

sub to_rgb {
    my ($xyz) = shift;
    my @XYZ = map { $xyz->[$_] * $range_max[$_] } 0 .. 2;
    my @rgb = mult_matrix3([[ 3.2404542, -0.9692660,  0.0556434],
                            [-1.5371385,  1.8760108, -0.2040259],
                            [-0.4985314,  0.0415560,  1.0572252]], @XYZ);

    return ( map { remove_d65($_) } @rgb );
}


$xyz_def;

