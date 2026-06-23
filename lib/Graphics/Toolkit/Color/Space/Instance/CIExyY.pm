
# CIExyY color space specific code for Illuminant D65 and Observer 2°

package Graphics::Toolkit::Color::Space::Instance::CIExyY;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

my $min = 1e-6;

sub from_xyY {
	my ($xyY) = @_;
	my $Y = $xyY->[2];
	my $y = $xyY->[1];
	return [0, 0, 0] if $Y < $min;   # black
	$y = $min if $y < $min;          # singularity guard
	my $sum = $Y / $y;
	my $X = $xyY->[0] * $sum;
	my $Z = $sum - $X - $Y;
    return [$X, $Y, $Z];
}
sub to_xyY {
	my ($xyz) = @_;
    my $sum = $xyz->[0] + $xyz->[1] + $xyz->[2];
    return [0.3127266147, 0.3290231303, 0] if $sum < $min;
    return [$xyz->[0] / $sum,  $xyz->[1] / $sum,  $xyz->[1] ];
}

Graphics::Toolkit::Color::Space->new(
     alias_name => 'CIExyY', 
           axis => [qw/x y Y/],
      precision => 5,
        convert => {XYZ => [\&from_xyY, \&to_xyY] },
);
