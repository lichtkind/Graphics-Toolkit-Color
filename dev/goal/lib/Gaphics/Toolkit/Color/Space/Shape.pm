
# geometry of space: value range checks, normalisation and computing distance

package Graphics::Toolkit::Color::Space::Shape;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util qw/round_decimals is_nr/;

#### constructor #######################################################
sub new {} # .basis, $type, $precision, $constraint   --> .shape

#### object attribute checker ##########################################
sub is_axis_numeric      {} # +axis --> ?
sub is_axis_euclidean    {} # +axis --> ?
sub axis_value_max       {} # +axis --> |+
sub axis_value_min       {} # +axis --> |+
sub axis_value_precision {} # +axis --> |+precision

# all axis
sub is_euclidean         {} #       --> ?
sub is_cylindrical       {} #       --> ?
sub is_int_valued        {} #       --> ?
sub has_constraints      {} #       --> ?

#### value checker #####################################################
sub check_value_shape    {}  # @tuple -- $range, $precision     --> !|@vals
sub is_equal             {}  # @tuple_a, @tuple_b -- $precision --> ? 
sub is_in_constraints    {}  # @tuple                           --> ?
sub is_in_bounds         {}  # @tuple -- $range                 --> ?
sub is_in_linear_bounds  {}  # @tuple -- $range                 --> ?

#### value ops #########################################################
sub clamp             {} # @tuple       -- $range       --> @tuple
sub round             {} # @tuple       -- $precision   --> @tuple
# normalisation
sub normalize         {} # @tuple       -- $range       --> @tuple
sub denormalize       {} # @tuple       -- $range       --> @tuple
sub denormalize_delta {} # @norm_delta_tuple -- $range  --> @delta_tuple
sub delta             {} # @norm_tuple_a, @norm_tuple_b --> @norm_delta_tuple

1;
