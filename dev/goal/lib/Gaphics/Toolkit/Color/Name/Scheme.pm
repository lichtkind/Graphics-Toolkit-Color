
# name space for color names, translate values > names & back, find closest name

package Graphics::Toolkit::Color::Name::Scheme;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Hub;
use Graphics::Toolkit::Color::Space::Util qw/round_int uniq/;

#### constructor #######################################################
sub new               {} #                                   --> .scheme
sub add_color         {} # ~color_name, @rgb_tuple           --> ?

#### exact getter ######################################################
sub all_names         {} #                                   --> @~color_name
sub is_name_taken     {} # ~color_name                       --> ?
sub values_from_name  {} # ~color_name                       --> |@rgb_tuple
sub names_from_values {} # @rgb_tuple                        --> |@~color_name

#### nearness methods ##################################################
sub closest_names_from_values {} # @rgb_tuple                --> |@~color_name, +d
sub names_in_range            {} # @rgb_tuple, +d            --> |@~color_name

1;

