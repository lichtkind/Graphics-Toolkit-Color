
# translate color names to values and vice versa

package Graphics::Toolkit::Color::Name;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name::Scheme;
use Graphics::Toolkit::Color::Space::Util qw/uniq round_decimals/;

#### public API ########################################################
sub all                 {} #                                        --> @~name
sub get_values          {} # ~name                                  --> @rgb_tuple
sub from_values         {} # @rgb_tuple -- ~scheme, ?all, ?full, +d --> @~name
sub closest_from_values {} # @rgb_tuple -- ~scheme, ?all, ?full     --> @~name

#### color scheme API ##################################################
sub try_get_scheme      {} #                   -- ~scheme           --> .scheme
sub add_scheme          {} # .scheme, ~scheme                       --> |.scheme 

1;

