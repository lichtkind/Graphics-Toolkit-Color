
# methods to compute one related color

package Graphics::Toolkit::Color::Calculator;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Values;


sub apply_gamma {} # .values, +gamma, ~space                       -->  .values
sub set_value   {} # .values, %newval        -- ~space_name        -->  .values
sub add_value   {} # .values, %newval        -- ~space_name        -->  .values
sub mix         {} #  @%(+percent, .color)   -- ~space_name        -->  .values
sub invert      {} # .values                 -- ~space_name, @axis -->  .values

1;
