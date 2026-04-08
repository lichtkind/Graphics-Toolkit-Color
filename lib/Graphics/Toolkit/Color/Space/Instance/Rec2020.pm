
# Rec.2020

package Graphics::Toolkit::Color::Space::Instance::AppleRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/power mult_matrix_vector_3/;


my $gamma = 0.45;

sub from_lrgb {
	my $lrgb = shift;
    return [map {power($_, 1 / $gamma)} @rgb];
}
sub to_lrgb {
	my $rgb = shift;
	$rgb = [map {power($_, $gamma)} @$rgb];
    return ;
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'Rec.2020',
       alias => 'BT.2020',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {LinearRGB => [\&to_lrgb, \&from_lrgb]},
);


__END__

For a linear light value L (0 ≤ L ≤ 1):If L ≤ 0.018:
V = 4.5 × L
If L > 0.018:
V = 1.099 × L^0.45 − 0.099

Where:L = normalized linear luminance (scene-referred)
V = non-linear encoded video signal

Notes:The exponent 0.45 is approximately 1/2.22.
Because of the linear segment near black, the overall effective gamma (decoding) is close to ~2.0 (not exactly 2.2 or 2.4).
The reference display EOTF is defined in BT.1886, which uses a pure gamma of 2.4 in many practical implementations.

This is the same formula I gave earlier — it is correct.2. Rec.2020 (BT.2020) – Opto-Electronic Transfer Function (OETF)Official formula (from ITU-R BT.2020-2):For a linear light value L (0 ≤ L ≤ 1):If L ≤ 0.0181 (sometimes listed as 0.018 or β = 0.0181 for higher precision):
V = 4.5 × L
If L > 0.0181:
V = 1.0993 × L^0.45 − 0.0993   (slight difference in constants for more precisio

