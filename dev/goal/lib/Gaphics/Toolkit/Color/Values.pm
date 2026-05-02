
# read only store of a single color: name + values in default and original space

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

#### constructor #######################################################
sub new_from_any_input {} #  values => %space_name => tuple ,   ~origin_space, ~color_name --> .values
sub new_from_tuple     {} # @tuple                                                         --> .values

#### getter ############################################################
sub normalized  {} # normalized (0..1) value tuple in any color space                               --> @tuple
sub shaped      {} # in any color space, range and precision                                        --> @tuple
sub formatted   {} # in shape values in any format # _ -- ~space, @~|~format, @~|~range, @~|~suffix --> *ColorDef
sub name        {} #                                                                                --> ~name
sub is_in_gamut {} # -- *color, ~space_name                                                         --> ?

1;
