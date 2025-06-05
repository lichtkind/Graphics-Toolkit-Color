
# YUV color space specific code

package Graphics::Toolkit::Color::Space::Instance::YUV;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

                                                                     # cyan-orange balance, magenta-green balance
my  $yiq_def = Graphics::Toolkit::Color::Space->new( axis  => [qw/luma Cb Cr/],
                                                     short => [qw/Y U V/],
                                                     range => [1, [-.5, .5], [-.5, .5],] );

    $yiq_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($rgb) = @_;

    my (@yuv) =  mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                              [0.3575761, 0.7151522, 0.1191920],
                              [0.1804375, 0.0721750, 0.9503041]], @$rgb);
}


sub to_rgb {
    my ($y, $i, $q) = @{$_[0]};
    #~ $i = ($i * $i_size) - $i_max;
    #~ $q = ($q * $q_size) - $q_max;
    my $r = $y + ( 0.956 * $i) + ( 0.619 * $q);
    my $g = $y + (-0.272 * $i) + (-0.647 * $q);
    my $b = $y + (-1.106 * $i) + ( 1.703 * $q);
    return ($r, $g, $b);
}

$yiq_def;
