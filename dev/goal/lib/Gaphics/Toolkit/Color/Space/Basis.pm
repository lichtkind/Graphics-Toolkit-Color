
# count and names of color space axis (short and long), space name = usr | prefix + axis initials

package Graphics::Toolkit::Color::Space::Basis;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Util qw/is_nr/;

sub new              {} # @~long_axis, @~short_axis, ~space_name, ~space_alias  --> .basis

#### getter ############################################################
sub space_name       {} #   -- ?alias ?given  --> ~space_name
sub long_axis_names  {} #                     --> @~long_names
sub short_axis_names {} #                     --> @~short_names
sub axis_iterator    {} #                     --> 0 .. +count-1
sub axis_count       {} #                     --> +

#### predicates ########################################################
sub is_name             {} # ~space_name      --> ?
sub is_long_axis_name   {} # ~long_name       --> ?
sub is_short_axis_name  {} # ~short_name      --> ?
sub is_axis_name        {} # ~axis_name       --> ?

sub pos_from_long_axis_name  {} # ~long_name  --> +pos
sub pos_from_short_axis_name {} # ~short_name --> +pos
sub pos_from_axis_name       {} # ~axis_name  --> +pos

sub is_hash            {}      # %values      --> ?
sub is_partial_hash    {}      # %some_values --> ?
sub is_value_tuple     {}      # @tuple       --> ?
sub is_number_tuple    {}      # @tuple       --> ?

#### converter #########################################################
sub short_axis_name_from_long  {} # ~long_name  --> ~short_name
sub long_axis_name_from_short  {} # ~short_name --> ~long_name
sub long_name_hash_from_tuple  {} # @tuple      --> %long_name
sub short_name_hash_from_tuple {} # @tuple      --> %short_name
sub tuple_from_hash            {} # %axis_name  --> @tuple
sub tuple_from_partial_hash    {} # %axis_name  --> @tuple

1;
