
# linear standard (S)RGB, RGB with removed gamma

package Graphics::Toolkit::Color::Space::Instance::LinearRGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

# change normalized RGB values to and from standard observer 2°

sub from_rgb {
    my ($rgb) = shift;
    return [ map {  ($_ > 0.04045)  ? ((($_ + 0.055) / 1.055 ) ** 2.4) 
		                            : ($_ / 12.92)                     } @$rgb ];
}
sub to_rgb {
    my ($lrgb) = shift;
    return [ map { ($_ > 0.0031308) ? ((($_**(1/2.4)) * 1.055) - 0.055) 
		                            : ($_ * 12.92)                     } @$lrgb ];
}

Graphics::Toolkit::Color::Space->new(
       alias => 'LinearRGB',
       alias => 'linRGB',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {RGB => [\&to_rgb, \&from_rgb]},
);
