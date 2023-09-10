use v5.12;
use warnings;

# YIQ color space specific code

package Graphics::Toolkit::Color::Space::Instance::YIQ;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util ':all';
                                                                    # Cyan-Orange Balance, Magenta-Grün Balance
my  $hwb_def = Graphics::Toolkit::Color::Space->new( axis => [qw/luminance in-phase quadrature/],
                                                     short => [qw/Y I Q/]
                                                     range => [1, [-0.5959,0.5959], [-0.5227,0.5227]] );

    $hwb_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($r, $g, $b) = @_;
    my $y = (0.299  * $r) + ( 0.587  * $g) + ( 0.114  * $b);
    my $i = (0.5959 * $r) + (-0.2746 * $g) + (-0.3213 * $b);
    my $q = (0.2115 * $r) + (-0.5227 * $g) + ( 0.3112 * $b);
    return ($y, $i, $q);
}


sub to_rgb {
    my ($y, $i, $q) = @_;
    my $r = $y + ( 0.956 * $i) + ( 0.619 * $q);
    my $g = $y + (-0.272 * $i) + (-0.647 * $q);
    my $b = $y + (-1.106 * $i) + ( 1.703 * $q);
    return ($r, $g, $b);
}

$hwb_def;
