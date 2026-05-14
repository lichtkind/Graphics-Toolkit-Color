
# OKHWB color space by Björn Ottosson

package Graphics::Toolkit::Color::Space::Instance::OKHWB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

sub from_hsv {
    my ($hsv) = shift;
    my $w = (1 - $hsv->[1]) * $hsv->[2];
    my $b = 1 - $hsv->[2];
    return [$hsv->[0], $w, $b];
}
sub to_hsv {
    my ($hwb) = shift;
    my $v = 1 - $hwb->[2];
    my $s = ($v < 0.000000001) ? 0 : (1 - ($hwb->[1] /  $v));
    return [$hwb->[0], $s, $v];
}

Graphics::Toolkit::Color::Space->new(
         name => 'OKHWB',
       family => 'HWB',
         axis => [qw/hue whiteness blackness/], 
        range => [360, 1, 1],
    precision => 5,
      convert => {OKHSV => [\&to_hsv, \&from_hsv]},
);
