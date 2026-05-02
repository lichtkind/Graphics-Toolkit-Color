
# store all color space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;

#### space API #########################################################
sub is_space_name         {} # ~space_name                                             --> ?
sub all_space_names       {} #                                                         --> @~space_name
sub default_space_name    {} #                                                         --> ~space_name
sub default_space         {} #                                                         --> .space
sub get_space             {} # ~space                                                  --> |.space
sub try_get_space         {} #          -- ~space                                      --> .space
sub add_space             {} # .space                                                  --> !|1
sub remove_space          {} # ~space_name                                             --> .space

#### tuple API #########################################################
sub convert               {} # @rgb_ntuple -- .space, ?normal, @src_tuple, ~src_space  --> |@tuple
sub deconvert             {} # @norm_tuple -- .space, ?normal, @src_tuple, ~src_space  --> |@rgb_tuple
sub deformat              {} # *color_def, @|+range_def, @|~suffix                     --> |@tuple, |~space_name, |~format
sub deformat_partial_hash {} # %values, ~space_name                                    --> |@tuple, |~space_name
sub distance              {} # @tuple_a @tuple_b -- ~space_name @axis, +|@range_def    --> +

1;

