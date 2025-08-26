
# Hunter lab color space, pre CIELAB, for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::HunterLAB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my @D65 = (0.95047, 1, 1.08883); # illuminant
my %K   = (a => 172.30, b => 67.20);

sub from_xyz {
    my ($xyz) = shift;
    my $l = sqrt $xyz->[1];
    my $a = ($xyz->[0] - $xyz->[1])/$l;
    my $b = ($xyz->[1] - $xyz->[2])/$l;
    $a = ($a / 2) + .5;
    $b = ($b / 2) + .5;
    return ([$l, $a, $b]);
}
sub to_xyz {
    my ($lab) = shift;
    my $l = $lab->[0];
    my $a = ($lab->[1] - .5) * 2;
    my $b = ($lab->[2] - .5) * 2;
    my $y = $l ** 2;
    my $x = ($a * $l) + $y;
    my $z = $y - ($b * $l);
    return ([$x, $y, $z]);
}

Graphics::Toolkit::Color::Space->new(
         name => 'HunterLAB',
         axis => [qw/L a b/],  # same as short
        range => [100, [-$K{'a'}, $K{'a'}], [-$K{'b'}, $K{'b'}]], # cyan-orange, magenta-green
    precision => 3,
      convert => {XYZ => [\&to_xyz, \&from_xyz]},
);
