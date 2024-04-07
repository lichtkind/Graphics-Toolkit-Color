use v5.12;
use warnings;

# LAB color space specific code based on XYZ

package Graphics::Toolkit::Color::Space::Instance::LAB;
use Graphics::Toolkit::Color::Space;

my ($i_max, $q_max)   = (0.5959, 0.5227);
my ($i_size, $q_size) = (2 * $i_max, 2 * $q_max);
                                                                    # cyan-orange balance, magenta-green balance
my  $lab_def = Graphics::Toolkit::Color::Space->new( axis => [qw/L* a* b*/],
                                                   prefix => 'CIE',
                                                    range => [1, [-$i_max, $i_max], [-$q_max, $q_max]] );

    $lab_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($r, $g, $b) = @_;
    my $y =           (0.299  * $r) + ( 0.587  * $g) + ( 0.114  * $b);
    my $i = ($i_max + (0.5959 * $r) + (-0.2746 * $g) + (-0.3213 * $b)) / $i_size;
    my $q = ($q_max + (0.2115 * $r) + (-0.5227 * $g) + ( 0.3112 * $b)) / $q_size;
    return ($y, $i, $q);
}


sub to_rgb {
    my ($y, $i, $q) = @_;
    $i = ($i * $i_size) - $i_max;
    $q = ($q * $q_size) - $q_max;
    my $r = $y + ( 0.956 * $i) + ( 0.619 * $q);
    my $g = $y + (-0.272 * $i) + (-0.647 * $q);
    my $b = $y + (-1.106 * $i) + ( 1.703 * $q);
    return ($r, $g, $b);
}

$lab_def;

__END__

sub from_rgb {
    my ($r, $g, $b) = @_;
    $r = ( $r > 0.04045 ) ? ((($r + 0.055) / 1.055 ) ** 2.4) : ($r / 12.92);
    $g = ( $g > 0.04045 ) ? ((($g + 0.055) / 1.055 ) ** 2.4) : ($g / 12.92);
    $b = ( $b > 0.04045 ) ? ((($b + 0.055) / 1.055 ) ** 2.4) : ($b / 12.92);

    my $x =  (0.4124564 * $r) + ( 0.3575761 * $g) + ( 0.1804375 * $b);
    my $y =  (0.2126729 * $r) + ( 0.7151522 * $g) + ( 0.0721750 * $b);
    my $z =  (0.0193339 * $r) + ( 0.1191920 * $g) + ( 0.9503041 * $b);
    return ($x, $y, $z);
}


sub to_rgb {
    my ($x, $y, $z) = @_;
    my $r =  ( 3.2404542 * $x) + (-1.5371385 * $y) + (-0.4985314 * $z);
    my $g =  (-0.9692660 * $x) + ( 1.8760108 * $y) + ( 0.0415560 * $z);
    my $b =  ( 0.0556434 * $x) + (-0.2040259 * $y) + ( 1.0572252 * $z);

    $r = ($r > 0.003131) ? ((($r**0.416666) * 1.055) - 0.055) : $r * 12.92;
    $g = ($g > 0.003131) ? ((($g**0.416666) * 1.055) - 0.055) : $g * 12.92;
    $b = ($b > 0.003131) ? ((($b**0.416666) * 1.055) - 0.055) : $b * 12.92;
    return ($r, $g, $b);
}
