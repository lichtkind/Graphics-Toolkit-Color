
# color value operation generating color sets

package Graphics::Toolkit::Color::SetCalculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Calculator;

sub complement {} # .start +steps +tilt %target_delta .space --> @.values
sub analogous  {} # .start +steps +tilt %next_color .space   --> @.values
sub gradient   {} # @.colors, +steps, +tilt,       .space    --> @.values
sub cluster    {} # .center, +radius @+|+distance, .space    --> @.values

1;
