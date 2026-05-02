
# utilities for color value calculation

package Graphics::Toolkit::Color::Space::Util;
use v5.12;
use warnings;
sub min    {} # @+ --> +
sub max    {} # @+ --> +
sub uniq   {} # @~ --> @~

sub round_int      {} # +nr             --> I
sub round_decimals {} # +nr, Iprecision --> +
sub mod_real       {} # +nr, +divisor   --> +
sub gamma_correct  {} # +nr, +exponent  --> +
sub is_nr          {} # +nr             --> ?

sub mult_matrix_vector_3 {} # @@+matrix, +c1, +c2, +c3         --> @+

1;
