
# CIE LCh(uv) cylindrical color space variant of CIELUV

package Graphics::Toolkit::Color::Space::Instance::CIELCHuv;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my  $hcl_def = Graphics::Toolkit::Color::Space->new( name => 'CIELCHuv', alias => '',
                                                     axis => [qw/luminance chroma hue/],
                                                    range => [100, 441, 360],
                                                precision => 3 );

    $hcl_def->add_converter('CIELUV', \&to_luv, \&from_luv );

my $TAU = 6.283185307;

sub from_luv {
    my ($luv) = shift;
    my $a = $lab->[1] * 441 - 134;
    my $b = $lab->[2] * 360 - 140;
    my $c = sqrt( ($u**2) + ($v**2));
    my $h = atan2($v, $u);
    $h += $TAU if $h < 0;
    return ($lab->[0], $c / 539, $h / $TAU);
}


sub to_luv {
    my ($lch) = shift;
    my $u = cos($lch->[2] * $TAU);
    my $v = sin($lch->[2] * $TAU);
    return ($lch->[0], ($a + 1) / 2, ($b + 1) / 2);
}

$hcl_def;

