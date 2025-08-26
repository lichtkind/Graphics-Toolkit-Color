
# Hunter lab color space, pre CIELAB, for Illuminant D65 and Observer 2 degree

package Graphics::Toolkit::Color::Space::Instance::HunterLAB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my @D65 = (0.95047, 1, 1.08883); # illuminant
my %K   = ( a => 172.30, b => 67.20 );


my  $lab_def = Graphics::Toolkit::Color::Space->new( name  => 'HunterLAB',  #
                                                      axis => [qw/L a b/],  # same as short
                                                     range => [100, [-$K{'a'}, $K{'a'}], [-$K{'b'}, $K{'b'}]],
                                                 precision => 3 );  # lightness, cyan-orange balance, magenta-green balance

$lab_def->add_converter('CIEXYZ', \&to_xyz, \&from_xyz );



sub from_xyz {
    my ($xyz) = shift;
    #~ my @xyz = map {($_ > $eta) ? ($_ ** (1/3)) : ((($kappa * $_) + 16) / 116)} @$xyz;
    #~ my $l = (1.16 * $xyz[1]) - 0.16;
    #~ my $a = ($xyz[0] - $xyz[1] + 1) / 2;
    #~ my $b = ($xyz[1] - $xyz[2] + 1) / 2;
    #~ return ([$l, $a, $b]);
}

sub to_xyz {
    my ($lab) = shift;
    #~ my $fy = ($lab->[0] + 0.16) / 1.16;
    #~ my $fx = $fy - 1 + ($lab->[1] * 2);
    #~ my $fz = $fy + 1 - ($lab->[2] * 2);
    #~ my @xyz = map {my $f3 = $_** 3; ($f3 > $eta) ? $f3 : (( 116 * $_ - 16 ) / $kappa) } $fx, $fy, $fz;
    #~ return \@xyz;
}

$lab_def;
