
# public user level API: docs, help and arg cleaning

package Graphics::Toolkit::Color;
our $VERSION = '2.1';

use v5.12;
use warnings;
use Exporter 'import';
use Graphics::Toolkit::Color::Space::Util;
use Graphics::Toolkit::Color::SetCalculator;

my $default_space_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
our @EXPORT_OK = qw/color is_in_gamut/;

sub new          {} # ., *ColorDef --> .GTC
sub color        {} # *ColorDef    --> .GTC

### getter #############################################################
sub values       {} # -- ~in, ~as, ?raw, +|@+precision, +|@+|@@+|%+|%@+range, ~|@~suffix --> *ColorDef / ~name
sub name         {} #       -- ~from, ?all, ?full, +distance                             --> ~|@~name | ~|@~full:name
sub closest_name {} #       -- ~from, ?all, ?full                                        --> ~|@~name | ~|@~full:name
sub distance     {} # *|.to -- ~in, @~select, +|@+|@@+|%+|%@+range                       --> +               # select => only
sub is_in_gamut  {} #       -- ~in, *color                                               --> ?
	
## single color creation methods #######################################
sub apply        {} # +gamma, ~in  --                                 --> .GTC
sub set_value    {} # %_ColorPart  -- ~in                             --> .GTC
sub add_value    {} # %_ColorPart  -- ~in                             --> .GTC
sub mix          {} # *|@*|.|@.to  -- ~in, +@|+amount                 --> .GTC
sub invert       {} #              -- ~in, ~@|~only                   --> .GTC

## color set creation methods ##########################################
sub complement   {} #              --      ~steps, +tilt, %_target    --> @.GTC    # 2.3: ~in,
# sub analogous    {} #              -- ~in, ~steps, +tilt, %_target    --> @.GTC  # 2.3
sub gradient     {} # *|.to        -- ~in, ~steps, +tilt, %_target    --> @.GTC
sub cluster      {} # +radius, +minimal_distance -- ~in               --> @.GTC

1;
