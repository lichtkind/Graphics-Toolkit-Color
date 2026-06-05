
# public user level API: doc summary, help msg and arg cleaning

package Graphics::Toolkit::Color;
our $VERSION = '2.20';
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Error       qw/error/;
use Graphics::Toolkit::Color::Space::Util qw/is_nr/;
use Graphics::Toolkit::Color::SetCalculator;

## import export, error handling #######################################
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/color is_in_gamut/;

sub import {
    my ($class, @args) = @_;
    my @export_symbols;
    push @export_symbols, shift @args while @args and lc $args[0] ne 'error';
    Graphics::Toolkit::Color::Error::change_mode( $args[1] );
    $class->Exporter::export_to_level(1, $class, @export_symbols);
}

## constructor #########################################################
my $POD_link = ' Type "perldoc Graphics::Toolkit::Color" for more help.';
sub new {
    my ($pkg, @args) = @_;
    my $help = 'method "new" accepts the arguments: "color" (color definition), "raw", '.
               '"range" and "in" (space name). "color" is the required and default argument.'.$POD_link;
	my ($color_def, $space_name, $range_def, $is_raw);
    unless (@args % 2 or not @args){
		my %h = @args;
		($color_def, $space_name, $range_def, $is_raw) = ($h{'color'}, $h{'in'}, $h{'range'}, $h{'raw'} // 0);
	}
    $color_def = _color_def_into_scalar( @args ) unless defined $color_def;
    error($help) unless defined $color_def;
    my $self = _new_from_scalar_def( $color_def, $space_name, $range_def, $is_raw );
	return (ref $self) ? $self : error($self);
}
sub color { 
	my $self = _new_from_scalar_def( _color_def_into_scalar( @_ ) );
	return (ref $self) ? $self : error($self);
}
sub _color_def_into_scalar {
    my (@args) = @_;
    return if @args < 1 or @args > 8 or @args == 5 or @args == 7;
    return $args[0] if @args == 1; # pass names
    return [@args]  if @args < 5;  # lists and named lists --> array and named array
    return {@args};                # hashes without curly braces --> hash
}
sub _new_from_scalar_def {
    my ($color_def, $space_name, $range_def, $is_raw) = @_;
    return $color_def if ref $color_def eq __PACKAGE__;
    return _new_from_value_obj( Graphics::Toolkit::Color::Values->new_from_any_input( $color_def, $space_name, $range_def, $is_raw ) );
}
sub _new_from_value_obj {
    my ($value_obj) = @_;
    return $value_obj unless ref $value_obj eq 'Graphics::Toolkit::Color::Values';
    return bless {values => $value_obj};
}

sub is_in_gamut {
    my ($self, $space_name) = @_;
    return is_in_gamut_sub (@_) if ref $self ne __PACKAGE__;
    my $help = 'The method "is_in_gamut" accepts one optional, positional argument, a color space name, '.
               'which defaults to the space the color was defined in'.$POD_link; 
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
	return error($help) if defined $space_name and not ref $space;
    $self->{'values'}->is_in_gamut( (ref $space) ? $space->name : undef );
}
sub is_in_gamut_sub {
    my (@color) = @_;
	my $values = Graphics::Toolkit::Color::Values->new_from_any_input( 
		_color_def_into_scalar( @_ ), undef, undef, 1 
	);
	return error($values.$POD_link) unless ref $values;
    $values->is_in_gamut( );
}

########################################################################
sub _split_named_args {
    my ($raw_args, $only_parameter, $required_parameter, $optional_parameter, $parameter_alias) = @_;
    @$raw_args = %{$raw_args->[0]} if @$raw_args == 1 and ref $raw_args->[0] eq 'HASH' and not
                  (defined $only_parameter and $only_parameter eq 'to' and ref _new_from_scalar_def( $raw_args ) );

    if (@$raw_args == 1 and defined $only_parameter and $only_parameter){
        return "The one default argument can not cover multiple, required parameter !" if @$required_parameter > 1;
        return "The default argument does not cover the required argument!"
            if @$required_parameter and $required_parameter->[0] ne $only_parameter;

        my %defaults = %$optional_parameter;
        delete $defaults{$only_parameter};
        return {$only_parameter => $raw_args->[0], %defaults};
    }
    my %clean_arg;
    if (@$raw_args % 2) {
        return (defined $only_parameter and $only_parameter)
             ? "Got odd number of arguments, please use key value pairs as arguments or one default argument !\n"
             : "Got odd number of values, please use key value pairs as arguments !\n"
    }
    my %arg_hash = @$raw_args;
    for my $parameter_name (@$required_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        return "Argument '$parameter_name' is missing!\n" unless exists $arg_hash{$parameter_name};
        $clean_arg{ $parameter_name } = delete $arg_hash{ $parameter_name };
    }
    for my $parameter_name (keys %$optional_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        $clean_arg{ $parameter_name } = exists $arg_hash{$parameter_name}
                                      ? delete $arg_hash{ $parameter_name }
                                      : $optional_parameter->{ $parameter_name };
    }
    return "Inserted unknown argument(s): ".(join ',', keys %arg_hash)."\n" if %arg_hash;
    return \%clean_arg;
}

### getter #############################################################
my $default_space_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
sub values       {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [],
                               { in => $default_space_name, as => 'list', raw => 0,
                                 precision => undef, range => undef, suffix => undef } );
    my $help = 'The method "values" returns numeric color values and accepts six named, optional arguments: '.
               '"in" (color space name), "as" (color definition format), "raw", "range", "precision" and "suffix"!';
    return error($arg.$help.$POD_link) unless ref $arg;
    $self->{'values'}->formatted( @$arg{qw/in as suffix range precision raw/} );
}

sub name         {
    my ($self, @args) = @_;
    return $self->{'values'}->name unless @args;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0, distance => 0}, {distance => 'd'});
     my $help = <<EOH;
    GTC method 'name' accepts three optional, named arguments:
    name ( ...
        'CSS',                # color naming scheme works as only positional argument
        from => 'CSS',        # same scheme (defaults to internal: X + CSS + PantoneReport)
        from => ['SVG', 'X'], # more color naming schemes at once, without duplicates
        all => 1,             # returns list of all names with the object's RGB values (defaults 0)
        full => 1,            # adds color scheme name to the color name. 'SVG:red' (defaults 0)
        distance => 3,        # color names from within distance of 3 (defaults 0)
EOH
    return Graphics::Toolkit::Color::Name::from_values( $self->{'values'}->shaped, @$arg{qw/from all full distance/});
}

sub closest_name {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0});
    my $help = <<EOH;
    GTC method 'closest_name' accepts three optional, named arguments:
    closest_name ( ...
        'CSS',                # color naming scheme works as only positional argument
        from => 'CSS',        # same scheme (defaults to internal: X + CSS + PantoneReport)
        from => ['SVG', 'X'], # more color naming schemes at once, without duplicates
        all => 1,             # returns list of all names with the object's RGB values (defaults 0)
        full => 1,            # adds color scheme name to the color name. 'SVG:red' (defaults 0)
EOH
    my ($name, $distance) = Graphics::Toolkit::Color::Name::closest_from_values(
                                $self->{'values'}->shaped, @$arg{qw/from all full/});
    return wantarray ? ($name, $distance) : $name;
}

sub distance {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => $default_space_name, select => undef, range => undef}, 
                                                       {select => 'only'});
    my $help = <<EOH;
    GTC method 'distance' computes the Euclidean distance between two colors (points)
    in a color space. It accepts as arguments either a scalar color definition or
    four named arguments, only the first being required:
    distance ( ...
        to => 'green',        # color object or color definition (required)
        in => 'HSL',          # color space name, defaults to "$default_space_name"
        select => 'red',      # axis name or names (ARRAY ref), default is none
        only => 'red',        # argument alias name to select
        range => 2**16,       # value range definition, defaults come from color space def
EOH
    return $arg.$help unless ref $arg;
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    return "target color definition: $arg->{to} is ill formed" unless ref $target_color;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    if (defined $arg->{'select'}){
        if (not ref $arg->{'select'}){
            return $arg->{'select'}." is not an axis name in color space: ".$color_space->name
                unless $color_space->is_axis_name( $arg->{'select'} );
        } elsif (ref $arg->{'select'} eq 'ARRAY'){
            for my $axis_name (@{$arg->{'select'}}) {
                return "$axis_name is not an axis name in color space: ".$color_space->name
                    unless $color_space->is_axis_name( $axis_name );
            }
        } else { return "The 'select' argument needs one axis name or an ARRAY with several axis names".
                       " from the same color space!" }
    }
    my $range_def = $color_space->shape->try_check_range_definition( $arg->{'range'} );
    return $range_def unless ref $range_def;
    Graphics::Toolkit::Color::Space::Hub::distance(
        $self->{'values'}->normalized, $target_color->{'values'}->normalized, $color_space->name ,$arg->{'select'}, $range_def );
}

## single color creation methods #######################################
sub apply {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['gamma'], {in => 'LinearRGB'} ); 
    my $help = <<EOH;
    GTC method 'apply' accepts one named argument with a numeric value:
    apply ( ...
        gamma => 2.2,          # reverse is with 1 / 2.2
        gamma => {r=> 1, g=> 2, b=> 1.2},  # custom gamma per axis
        in => 'OKLAB',         # compute in oklab space, default is LinearRGB
EOH
    return $arg.$help unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::apply_gamma( $self->{'values'}, $arg->{'gamma'}, $color_space ) );
}

sub set_value {
    my ($self, @args) = @_;
    @args = %{$args[0]} if @args == 1 and ref $args[0] eq 'HASH';
    my $help = <<EOH;
    GTC method 'set_value' needs a value HASH (not a ref) whose keys are axis names or
    short names from one color space. If the chosen axis name(s) is/are ambiguous,
    you might add the "in" argument:
        set_value( green => 20 ) or set( g => 20 ) or
        set_value( hue => 240, in => 'HWB' )
EOH
    return $help if @args % 2 or not @args or @args > 10;
    my $partial_color = { @args };
    my $space_name = delete $partial_color->{'in'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::set_value( $self->{'values'}, $partial_color, $space_name ) );
}

sub add_value {
    my ($self, @args) = @_;
    @args = %{$args[0]} if @args == 1 and ref $args[0] eq 'HASH';
    my $help = <<EOH;
    GTC method 'add_value' needs a value HASH (not a ref) whose keys are axis names or
    short names from one color space. If the chosen axis name(s) is/are ambiguous,
    you might add the "in" argument:
        add_value( blue => -10 ) or set( b => -10 )
        add_value( hue => 100 , in => 'HWB' )
EOH
    return $help if @args % 2 or not @args or @args > 10;
    my $partial_color = { @args };
    my $space_name = delete $partial_color->{'in'};
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $space_name );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::add_value( $self->{'values'}, $partial_color, $space_name ) );
}

# lightweight designer API
my $design_default = 'OKHSL';
sub lighten {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::lighten( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}
sub darken {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::darken( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}
sub saturate {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::saturate( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}
sub desaturate {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::desaturate( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}
sub tint {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::tint( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}
sub tone {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::tone( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}
sub shade {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'by', ['by'], {in => $design_default});
    return "The only argument or named argument 'by' has to be a number between 0 and 1!" unless ref $arg;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::shade( $self->{'values'}, $arg->{'by'}, $arg->{'in'} ) );
}

sub mix {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => 'OKLAB', by => undef}, {by => 'amount'});
    my $help = <<EOH;
    GTC method 'mix' accepts three named arguments, only the first being required:
    mix ( ...
        to => ['HSL', 240, 100, 50],   # scalar color definition or ARRAY ref thereof
        amount => 20,                  # percentage value or ARRAY ref thereof, default is 50
        in => 'HSL',                   # color space name, defaults to "OKLAB"
    Please note that ARRAY for amount makes only sense if to got also an ARRAY.
    Both ARRAY have to have the same length. 'amount' refers to the color(s) picked with 'to'.
    It is possible to give to an ARRAY and amount a SCALAR.
EOH
    return $arg.$help unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( delete $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    my $second_color = _new_from_scalar_def($arg->{'to'});
    if (ref $second_color){ $arg->{'to'} = [$second_color->{'values'}] } 
    else {
        if (ref $arg->{'to'} ne 'ARRAY'){
			return "target color definition (argument 'to'): '$arg->{to}' is ill formed. $second_color";
        } else {
			my @to = ();
			for my $color_def (@{$arg->{'to'}}){
				if (ref $color_def eq __PACKAGE__) { push @to, $color_def->{'values'} }
				else {
					$second_color = Graphics::Toolkit::Color::Values->new_from_any_input( $color_def );
                    return "target color definition (argument 'to'): '$color_def' is ill formed. $second_color" unless ref $second_color;
					push @to, $second_color;
				}
			}
			$arg->{'to'} = \@to;
		}
    }
    # backward compatibility: 'by' > 1 is read as percent (0 .. 100) and mapped to 0 .. 1
    if (defined $arg->{'by'}){
        if (ref $arg->{'by'} eq 'ARRAY') { 
			for (@{$arg->{'by'}}) { $_ /= 100 if is_nr($_) and $_ > 1 } 
		} elsif (is_nr($arg->{'by'}) and $arg->{'by'} > 1) { $arg->{'by'} /= 100 }
    }
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::mix( $self->{'values'}, $arg->{'to'}, $arg->{'amount'}, $color_space ) );
}

sub invert {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'only', [], {in => undef, only => undef});
    my $help = <<EOH;
    GTC method 'invert' accepts one optional argument, which can be positional or named:
    invert ( ...
        in => 'HSL',                    # color space name, defaults to "$default_space_name"
        only => 'Saturation',           # inverts only second value of the tuple
        only => [qw/s l/],              # axis name or names have to match selected space
EOH
    return $arg.$help unless ref $arg and (not ref $arg->{'only'} or ref $arg->{'only'} eq 'ARRAY');
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help if defined $arg->{'in'} and not ref $color_space;
    $arg->{'in'} = $color_space if defined $arg->{'in'};
    my $default_space = Graphics::Toolkit::Color::Space::Hub::get_space( 'OKLAB' );
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::invert( $self->{'values'}, $arg->{'only'}, $arg->{'in'}, $default_space ) );
}

## color set creation methods ##########################################
sub complement {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'steps', [], {steps => 1, tilt => 0, skew => 0, target => {}, in => $design_default});
    my $help = <<EOH;
    GTC method 'complement' is computed in HSL and has two named, optional arguments:
    complement ( ...
        steps => 20,                                # count of produced colors, default is 1
        tilt => 10,                                 # default is 0
        target => {h => 10, s => 20, l => 3},       # sub-keys are independent, default to 0
        in    => 'HSL',          # color space name, defaults to "$design_default"
EOH
    return $arg.$help unless ref $arg;
    return "Optional argument 'steps' has to be a number !\n".$help unless is_nr($arg->{'steps'});
    return "Optional argument 'steps' is zero, no complement colors will be computed !\n".$help unless $arg->{'steps'};
    return "Optional argument 'tilt' has to be a number !\n".$help unless is_nr($arg->{'tilt'});
    return "Optional argument 'target' has to be a HASH ref !\n".$help if ref $arg->{'target'} ne 'HASH';
    my ($target_delta, $space_name);
    if (keys %{$arg->{'target'}}){
        ($target_delta, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_search_partial_hash( $arg->{'target'}, 'HSL' );
        return "Optional argument 'target' got HASH keys that do not fit HSL space (use 'h','s','l') !\n".$help
            unless ref $target_delta;
    } else { $target_delta = [] }
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    return "Need a cylindrical space from the HSL family \n" unless uc($color_space->family) eq 'HSL';
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::complement( $self->{'values'}, $target_delta, @$arg{qw/steps tilt skew/}, $color_space );
}

sub analogous {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {steps => 4, tilt => 0, in => $design_default});
    my $help = <<EOH;
    GTC method 'analogous' accepts four named arguments, only the first is required:
    analogous ( ...
        to    => 'blue',         # scalar color definition or GTC object of next color
        steps => 20,             # count of produced colors, defaults to 4
        tilt  => 1,              # dynamics of color change, defaults to 0
        in    => 'HSL',          # color space name, defaults to "$design_default"
EOH
    return $arg.$help unless ref $arg;
    my @colors = ($self->{'values'});
    my $next_color = _new_from_scalar_def( $arg->{'to'} );
    if  (ref $next_color) { $arg->{'to'} = $next_color }
    else                  { return "Argument 'to' contains malformed color definition!\n".$help}
    return "Argument 'steps' has to be a number greater zero !\n".$help
        unless is_nr($arg->{'steps'}) and $arg->{'steps'} > 0;
    $arg->{'steps'} = int $arg->{'steps'};
    return "Argument 'tilt' has to be a number !\n".$help unless is_nr($arg->{'tilt'});
    return "Number of steps has to be positive !\n".$help unless$arg->{'steps'} > 0;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::analogous( $self->{'values'}, $arg->{'to'}, @$arg{qw/steps tilt/}, $color_space);
}

sub gradient {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {steps => 10, tilt => 0, in => 'OKLAB'});
    my $help = <<EOH;
    GTC method 'gradient' accepts four named arguments, only the first is required:
    gradient ( ...
        to    => 'blue',         # scalar color definition or ARRAY ref thereof
        steps => 20,             # count of produced colors, defaults to 10
        tilt  => 1,              # dynamics of color change, defaults to 0
        in    => 'HSL',          # color space name, defaults to "OKLAB"
EOH
    return $arg.$help unless ref $arg;
    my @colors = ($self->{'values'});
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    if (ref $target_color) {
        push @colors, $target_color->{'values'} }
    else {
        return "Argument 'to' contains malformed color definition!\n".$help if ref $arg->{'to'} ne 'ARRAY' or not @{$arg->{'to'}};
        for my $color_def (@{$arg->{'to'}}){
            my $target_color = _new_from_scalar_def( $color_def );
            return "Argument 'to' contains malformed color definition: $color_def !\n".$help unless ref $target_color;
            push @colors, $target_color->{'values'};
        }
    }
    return "Argument 'steps' has to be a number greater zero !\n".$help
        unless is_nr($arg->{'steps'}) and $arg->{'steps'} > 0;
    $arg->{'steps'} = int $arg->{'steps'};
    return "Argument 'tilt' has to be a number !\n".$help unless is_nr($arg->{'tilt'});
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::gradient( \@colors, @$arg{qw/steps tilt/}, $color_space);
}

sub cluster {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['radius', 'minimal_distance'], {in => 'OKLAB'},
                                 {radius => 'r', minimal_distance => 'min_d'}                              );
    my $help = <<EOH;
    GTC method 'cluster' accepts three named arguments, the first two being required:
    cluster (  ...
        radius => 3                    # ball shaped cluster with cuboctahedral packing or
        r => [10, 5, 3]                # cuboid shaped cluster with cubical packing
        minimal_distance => 0.5        # minimal distance between colors in cluster
        min_d => 0.5                   # short alias for minimal distance
        in => 'HSL'                    # color space name, defaults to "OKLAB"
EOH
    return $arg.$help unless ref $arg;
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    return "Argument 'radius' has to be a number or an ARRAY of numbers".$help
        unless is_nr($arg->{'radius'}) or $color_space->is_number_tuple( $arg->{'radius'} );
    return "Argument 'minimal_distance' (or 'min_d') has to be a number greater zero !\n".$help
        unless is_nr($arg->{'minimal_distance'}) and $arg->{'minimal_distance'} > 0;
    return "Ball shaped cluster works only in spaces with three dimensions !\n".$help
        if $color_space->axis_count > 3 and not ref $arg->{'radius'};
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::cluster( $self->{'values'}, @$arg{qw/radius minimal_distance/}, $color_space);
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - calculate color (sets), IO many spaces and formats

=head1 SYNOPSIS

    use Graphics::Toolkit::Color qw/color is_in_gamut/;

    my $red = Graphics::Toolkit::Color->new('red');  # create color object
    say $red->add_value( 'blue' => 255 )->name;      # red + blue = 'magenta'
    my @blue = color( 0, 0, 255)->values('HSL');     # 240, 100, 50 = blue
    if (is_in_gamut('oklab(14, -106, 3)')) { ..      # check if valid
    $red->mix( to => [HSL => 0,0,80], amount => 10); # mix red with a little grey
    $red->gradient( to => '#0000FF', steps => 10);   # 10 colors from red to blue
    my @base_triadic = $red->complement( 3 );        # get fitting red green and blue
    my @reds = $red->cluster( r => 1.1, min_d => 1 );# 13 shades of red

=head1 DESCRIPTION

Graphics::Toolkit::Color, for short B<GTC>, is the top level API of this
library and the only package a regular user should be concerned with.
Its main purpose is the creation of related colors or sets of them,
such as gradients, complements and more. But if you want to convert, 
quantize, round or reformat color definitions or translate from and to 
color names, it can be helpful too.

This page will give you a quick overview of all GTC methods. 
The L<Manual|Graphics::Toolkit::Color::Manual> contains deeper explanations
and describes every argument and topic of interest in detail. Therefore each
chapter here starts with a link to the appropriate paragraph of a manual page.

While this module can understand and output color values of many (33)
L<color spaces|Graphics::Toolkit::Color::Manual::Space>,
L<RGB|Graphics::Toolkit::Color::Manual::Space/RGB> is the internal and
primary one for input and output, because GTC is about colors that can be 
shown on the screen, and these are usually encoded in I<RGB> (nonlinear standard RGB). 
However, many color calculations are operating by default in 
I<OKLAB> or I<OKHSL> to give perceptually uniform results. 

Each GTC object represents one color and is read-only. It has no runtime 
dependencies. Only L<Test::Simple> and L<Test::Warn> are needed for testing. 
The behavior of L<error messages|Graphics::Toolkit::Color::Manual::Error>
can be chosen, but defaults to using L<Carp>.

=head1 DEPRECATION

The next API cleanup will come with version 3.0. Please see which 
syntax is L<on the way out|Graphics::Toolkit::Color::Manual::Deprecation>.

=head1 CONSTRUCTOR

L<new|Graphics::Toolkit::Color::Manual::Constructor/new> is the universal
constructor to create a GTC object that takes the arguments: 
L<color|Graphics::Toolkit::Color::Manual::Argument/color>, 
L<raw|Graphics::Toolkit::Color::Manual::Argument/raw>, 
L<range|Graphics::Toolkit::Color::Manual::Argument/range> and 
L<in|Graphics::Toolkit::Color::Manual::Argument/in>.
C<color> is the only required argument and the default argument 
(can be provided as the only positional argument).

The importable method L<color|Graphics::Toolkit::Color::Manual::Constructor/color>
is a short alias for calling C<new> just with the argument C<color>.

    use Graphics::Toolkit::Color qw/color/;

    my $color = Graphics::Toolkit::Color->new( 'Emerald' ); # X11 constant
    my $green = Graphics::Toolkit::Color->new( 'SVG:green');# SVG constant (explicit with full name)
    my $navy  = color( 'navy' );                            # just a shortcut, X11 constant
    
    color(  r => 255, g => 0, b => 0 );                     # red (RGB)
    color( {r => 255, g => 0, b => 0});                     # red in char_hash format (RGB)
    color( Red => 255, Green => 0, Blue => 0);              # red in hash format (RGB)
    color( Hue => 0, Saturation => 1, Lightness => .5 );    # red in OKHSL
    color( hue => 0, whiteness => 0, blackness => 0 );      # red in OKHWB

    color(  255, 0, 0 );                # list format, no space name -> RGB
    color( [255, 0, 0] );               # array format, RGB only (as input)
    color( 'RGB',   255, 0, 0  );       # named list format
    color(  RGB =>  255, 0, 0  );       # with fat comma
    color( [RGB =>  255, 0, 0] );       # named_array
    color(  RGB => [255, 0, 0] );       # tuple under named key
    color( [RGB => [255, 0, 0]]);       # nested_array

    color( 'rgb: 255, 0, 0' );          # named string format, commas are not optional
    color( 'HSV: 240, 100, 100' );      # space name is case insensitive
    color( 'hsv(240, 100, 100)' );      # css_string format
    color( 'hsv(240, 100%, 100%)' );    # value suffix is optional
    color( 'rgb(255 0 0)' );            # commas are optional
									    
    color( '#FF0000' );                 # hex_string format, RGB only
    color( '#f00' );                    # hex_string format, short form

    # this color is even outside the RGB16 range
    Graphics::Toolkit::Color->new( color => [100_000,0,0], range => 2**16, raw => 1 );

=head1 GETTER

These methods return information about a color(s) but not a GTC object.

=head2 is_in_gamut

L<is_in_gamut|Graphics::Toolkit::Color::Manual::Getter/is_in_gamut> returns 
a perlish pseudo boolean that answers the question: is this color inside
the value range of the color space (gamut). By I<this color> we mean either
the current color held by the object or another color given as argument.
For that purpose you can pass to this method any color definition C<new>
or C<color> would accept. And like with C<new> you have the option
to use the argument C<color>. That would allow you to add another argument
like C<range>, C<raw> and (unlike C<new>) C<in>. Same as with C<new> you 
have the option to use C<is_in_gamut> as a standalone, importable routine
that works the same way as the method.

C<range> and C<raw> work exactly like with I<new>, only 
L<Graphics::Toolkit::Color::Manual::Argument/raw> defaults
here to true. C<in> is the color space in which the check will be done,
otherwise it is in the space the color was defined in.

    $color->is_in_gamut( in => 'okLab');                    # is current color inside OKLAB ?

    use Graphics::Toolkit::Color qw/is_in_gamut/;
    is_in_gamut('rgb: 0, 0, 300');                          # false, SRGB ranges span up to 255
    is_in_gamut(color =>'rgb: 0, 0, 0', in =>'ProPhotoRGB');# true, black is always included


=head2 values

L<values|Graphics::Toolkit::Color::Manual::Getter/values> returns the 
numeric values of the color, held by the object. It should be able to
output everything which I<new> or I<color> can read, except color names.
Use it to convert, quantize, round and reformat color definitions.
I<values> accepts six optional, named arguments:
C<in> (color space), C<as> (format), C<range>, C<precision>, C<suffix> and C<raw>.
If only one positional argument is provided, it will be understood as C<in>.

L<Graphics::Toolkit::Color::Manual::Argument/in> is the name of a
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
the values will be converted to. It defaults to I<RGB> (standard RGB).

C<as> is setting the output format. Please see the L</CONSTRUCTOR> chapter
above or below, to read about all formats available.

C<range> sets the minimal and maximal values per axis, which are normally
defined by the chosen color space. A single number sets the maximum 
(the minimum will be assumed as zero). An ARRAY with two numbers is 
setting minimum and maximum and an ARRAY with three or four elements sets
the range on a per axis basis.

C<precision> needs an integer (whole number) that tells GTC the amount 
of decimals you wish to see. 0 means no decimals (integer only) and
-1 means all decimals available. You also can use an ARRAY ref to set a 
different I<precision> for each value (axes). If none are provided it
will default to the settings of the color space chosen.

C<suffix> is a small string that will be attached to each value. 
That would be e.g. '%' for saturation in I<HWB> space. Use this argument
to set your own suffix or to remove the suffix by setting it to C<''>.
Use an ARRAY ref to set a different I<suffix> per value.

L<Graphics::Toolkit::Color::Manual::Argument/raw> expects a 
perlish pseudo boolean that defaults to false (0).
When true the values will not be clamped into range and might be out of gamut.

    $blue->values();                                        #  0, 0, 255
    $blue->values( in => 'RGB', as => 'list');              #  0, 0, 255  # explicit arguments
    $blue->values(              as => 'array');             # [0, 0, 255] - RGB only
    $blue->values( in => 'RGB', as => 'named_array');       # ['RGB', 0, 0, 255]
    $blue->values( in => 'RGB', as => 'hash');              # { red => 0, green => 0, blue => 255}
    $blue->values( in => 'RGB', as => 'char_hash');         # { r => 0, g => 0, b => 255}
    $blue->values( in => 'RGB', as => 'named_string');      # 'rgb: 0, 0, 255'
    $blue->values( in => 'RGB', as => 'css_string');        # 'rgb( 0, 0, 255)'
    $blue->values(              as => 'hex_string');        # '#0000ff' - RGB only
    $blue->values(           range => 2**16 );              # 0, 0, 65536
    $blue->values('HSL');                                   # 240, 100, 50 # HSL is only argument
    $blue->values( in => 'HSL',suffix => ['', '%','%']);    # 240, '100%', '50%'
    $blue->values( in => 'HSB',  as => 'hash')->{'hue'};    # 240
   ($blue->values( 'HSB'))[0];                              # 240
    $blue->values( in => 'XYZ', range => 1, precision => 2);# normalized, 2 decimals max.

=head2 name

L<name|Graphics::Toolkit::Color::Manual::Getter/name> returns the
normalized name of the current color, if it (converted to RGB) is
part of the L<default scheme|Graphics::Toolkit::Color::Manual::Name/DEFAULT>.
Otherwise an empty string will be returned.
It has four optional named arguments: C<from>, C<all>, C<full> and C<distance>.

C<from> is the name of the color scheme. You may search in several schemata
for names by passing an ARRAY with several schema names. 
The schema name can also be provided as a positional argument, 
if it is the only one.

C<all> is a perlish pseudo boolean that defaults to false. If set true, 
you might get a list with several names as a result, if the selected 
scheme contains several names associated with the color values.

C<full> is another boolean that defaults to false. If set true, 
the resulting name(s) contain the scheme name ('SCHEMA:NAME').

C<distance> needs a number as argument, which has the same meaning as the
result of the method L</distance>. It defaults to zero. When set to a 
positive number, you get the name of one or all the colors that are defined
within this distance from the given color, including the caller itself.

    $blue->name();                                   # 'blue'
    $blue->name('SVG');                              # 'blue'
    $blue->name( from => [qw/CSS X/], all => 1);     # 'blue', 'blue1'
    $blue->name( from => 'CSS', full => 1);          # 'CSS:blue'
    $blue->name( distance => 3, all => 1);           # all names within the distance

=head2 closest_name

L<closest_name|Graphics::Toolkit::Color::Manual::Getter/closest_name> always
returns a normalized color name (unlike L<name>). 
In list context it also returns the L</distance> between the current color 
and the color belonging to the returned name. 
If several names belong to that color one can still force the method to
list them C<all>. But they will be bundled inside an ARRAY, 
so that the distance is always the second return value.

It has three optional named arguments: C<from>, C<all>, C<full> which 
work the same way as in L</name>.

    my $name = $red_like->closest_name;              # closest name in default scheme
    my $name = $red_like->closest_name('HTML');      # closest HTML constant
    ($name, $distance) = $color->closest_name( from => 'Pantone', all => 1 );

=head2 distance

L<distance|Graphics::Toolkit::Color::Manual::Getter/distance> returns  
a numeric value, the Euclidean distance between two colors in some color
space, which works even in cylindrical spaces. 
It has four optional, named arguments: C<to>, C<range>, C<select> and C<in>.
Only the first one is required and can be provided as a positional argument
if it is the only one.

C<to> defines the second color. It accepts a GTC object or any color 
definition L<new|/CONSTRUCTOR> would read.

C<range> expects a range definition, please read in the L</values> section
how range definitions have to be formatted. It is advisable to use the
range definition 'normal' for results that are easy to compare.

C<select> (alias is C<only>) allows the user to select a certain axis so
that e.g. only a difference in I<lightness> will be shown. One can choose 
several axes or even an axis several times, to heighten the weight of this axis.
To recreate the formula:
C<< $distance =  sqrt( 3 * delta_red**2 + 4 * delta_green**2 + 2 * delta_blue**2) >>
it is necessary to choose: C<< select => [qw/ r r r g g g g b b/] >>

L<Graphics::Toolkit::Color::Manual::Argument/in> is the name of 
the L<color spaces|Graphics::Toolkit::Color::Manual::Space>
the distance will be computed in. Please note that different spaces have 
different default ranges, which changes the size of the distance drastically.

    my $d = $blue->distance( 'lapisblue' );                        # how close is blue to lapis?
    $d = $blue->distance( to => 'airyblue', select => 'b');        # do they have the same amount of blue?
    $d = $color->distance( to => $c2, in => 'HSL', select => 'hue' ); # same hue?
    $d = $color->distance( to => $c2, range => 'normal' );         # distance with values in 0 .. 1 range
    $d = $color->distance( to => $c2, select => [qw/r g b b/]);    # double the weight of blue value differences


=head1 SINGLE COLOR

These methods create one GTC object with a color that is related to the
current one. They can be divided into the simpler, high level convenience
methods on the one side 
(I<lighten>, I<darken>, I<saturate>, I<desaturate>, I<tint>, I<shade>, I<tone>)
and the more powerful low level operations on the other 
(I<apply>, I<set_value>, I<add_value>, I<mix>, I<invert>).

The signature of the high level methods is always the same. 
It understands 2 named arguments: C<by> and C<in>. The first is the 
required one, which can be provided as a positional argument, if it is 
the only one. C<by> needs a number with decimals between 0 and 1.
Usually the method produces the same color again when 0 is provided and
and a fixed predictable outcome when the argument is 1. 
L<Graphics::Toolkit::Color::Manual::Philosophy/in> is as 
always the L<color spaces|Graphics::Toolkit::Color::Manual::Space> the
method is computed in, which defaults here to I<OKHSL>. The first 4 methods
can only operate in a space of the I<HSL> family.

=head2 lighten

L<lighten|Graphics::Toolkit::Color::Manual::Calculation/lighten> 
increases the lightness by an absolute amount, but does not touch saturation.
The result will be clamped, so lighten(1) will always return I<white>.

=head2 darken

L<darken|Graphics::Toolkit::Color::Manual::Calculation/darken> 
decreases the lightness by an absolute amount, but does not touch saturation.
The result will be clamped, so darken(1) will always return I<black>.

=head2 saturate

L<saturate|Graphics::Toolkit::Color::Manual::Calculation/saturate> 
increases the saturation by an absolute amount, but does not touch lightness.
The result will be clamped, so saturate(1) will always return 
the purest possible color.

=head2 desaturate

L<desaturate|Graphics::Toolkit::Color::Manual::Calculation/desaturate> 
decreases the saturation by an absolute amount, but does not touch lightness.
The result will be clamped, so desaturate(1) will always return a shade
of grey with the same lightness as the given color.

=head2 tint

L<tint|Graphics::Toolkit::Color::Manual::Calculation/tint> mixes (L</mix>)
a color with I<white> by the given percentage (0.2 = 20% white, 80% given color).
That lightens and desaturates at once. The result of tint(1) will always be I<white>.

=head2 tone

L<tone|Graphics::Toolkit::Color::Manual::Calculation/tone> mixes (L</mix>)
a color with mid gray (I<gray50>) by the given percentage 
(0.2 = 20% gray50, 80% given color).
That darkens or lightens and desaturates at once. 
The result of tone(1) will always be I<gray50>.

=head2 shade

L<shade|Graphics::Toolkit::Color::Manual::Calculation/shade> mixes (L</mix>)
a color with I<black> by the given percentage (0.2 = 20% black, 80% given color).
That darkens and desaturates at once. The result of shade(1) will always be I<black>.

=head2 apply

L<apply|Graphics::Toolkit::Color::Manual::Calculation/apply> computes a 
gamma correction. 
It has two named arguments: C<gamma> and C<in>.

C<gamma> is the only required argument. It expects a floating point number
(gamma value) or an HASH with axis names as keys that assigns to each 
axis one gamma value. 

L<Graphics::Toolkit::Color::Manual::Argument/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
I<apply> will be computed in. It defaults to I<LinearRGB>. 
So if you like to see the calculated values directly you need to get 
C<$color->values( in => 'LinearRGB');>.


    my $c = $blue->apply( gamma => 2.2 );                          # is the same as :
    my $c = $blue->apply( gamma => {r => 2.2, g =>2.2, b => 2.2}, in => 'LinearRGB' );


=head2 set_value

L<set_value|Graphics::Toolkit::Color::Manual::Calculation/set_value> 
returns a color that differs in some chosen values from the current one.
Its arguments have to be short or long axis names from one selected 
L<color space|Graphics::Toolkit::Color::Manual::Space>.
You may additionally provide the color space in mind with the argument 
L<Graphics::Toolkit::Color::Manual::Philosophy/in> if the axis names 
alone are too ambiguous.

    my $blue = $black->set_value( blue => 255 );                    # same as #0000ff
    my $color = $blue->set_value( saturation => 50, in => 'HSV' );  # would otherwise use OKHSL


=head2 add_value

Works exactly as L</set_value> with only one difference: the provided
axis values will be added to the current ones and not exchanged.

    my $darkblue = $blue->add_value( Lightness => -25 );    # get a darker tone
    my $blue3 = $blue->add_value( l => 10, in => 'LAB' );   # lighter color according CIELAB


=head2 mix

L<mix|Graphics::Toolkit::Color::Manual::Calculation/mix> computes a color
that is a blend between two or more other colors. 
It has three named arguments: C<to>, C<amount>, C<in>.

Only C<to> is required and may be given as a positional argument, if it 
is the only one. It requires as value a GTC object or any scalar 
I<color definition> C<new> would accept. Alternatively you can pass an
ARRAY with any mix of GTC objects and scalar color definitions.

C<amount> tells how many percent of the new color (argument I<to>)
gets mixed in. If there are several new colors the amount may still be
provided as one number. But in most cases you want to provide for each
new color one percentage amount in an ARRAY.

L<Graphics::Toolkit::Color::Manual::Philosophy/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
I<mix> will be computed in. It defaults to I<OKLAB>. 

    $blue->mix( $silver );                                         # 50% silver, 50% blue
    $blue->mix( to => 'silver', amount => .6 );                    # 60% silver, 40% blue
    $blue->mix( to => [qw/silver green/], amount => [.1, .2]);     # 10% silver, 20% green, 70% blue


=head2 invert

L<invert|Graphics::Toolkit::Color::Manual::Calculation/invert> computes 
a color with opposite properties (values). 
It has two optional, named arguments: C<only> and C<in>.

C<only> is a string with one short or long axis name or an ARRAY with
several of them. Only the values of these axes will be inverted. Per 
default all axes get inverted.

L<Graphics::Toolkit::Color::Manual::Philosophy/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
I<invert> will be computed in. It defaults to I<OKHSL>. Please note that
in euclidean spaces inversion means that the value will have the same 
L</distance> to the minimum as it had to the maximum (normalized: 1 - $_). 
On an angular axis, I<invert> will perform a rotation of 180 degrees.

    my $still_gray = $gray->invert();                 # got same color back
    my $blue = $yellow->invert('hue');                # invert hue in 'OKHSL'
    $yellow->invert( in => 'OKHSL', only => 'hue' );  # same result as $yellow->complement();


=head1 COLOR SETS

These methods create sets of colors which are currently just a list of
GTC objects.


=head2 complement 

L<complement|Graphics::Toolkit::Color::Manual::Set/complement> computes 
colors that form a circle of complementary colors.
It understands 4 named arguments: C<steps>, C<tilt>, C<target>, C<in>.

C<steps> is the amount of colors produced. It defaults to 1, giving just
THE complementary color, 2 would include the given and a value of 3
would result in a triadic color set, 4 in a quadratic and so forth. 

With a positive C<tilt> value, the colors will aggregate more around THE
complementary color, with a negative value more around the given. 
To get the classical split complements you use a value of 3.42 
for triadic and 1.585 for quadratic colors.

The argument C<target> works a bit like L</add_value> on THE complement
and thus moving the whole circle.

L<Graphics::Toolkit::Color::Manual::Philosophy/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
the I<complement>s will be computed in. It defaults to I<OKHSL> and can only be
a cylindrical space from the I<HSL> family.

    my @colors = $c->complement( 4 );                       # 'quadratic' colors
    my @colors = $c->complement( steps => 4, tilt => 4 );   # split-complementary colors
    my @colors = $c->complement( steps => 3, tilt => 2, target => { l => -10 } );
    my @colors = $c->complement( steps => 3, tilt => 2, target => { h => 20, s=> -5, l => -10 });


=head2 analogous

L<analogous|Graphics::Toolkit::Color::Manual::Set/analogous> creates a list 
of colors that differ from each other the same way as the two given colors.
It accepts four named arguments: C<to>, C<steps>, C<tilt>, C<in>.

Only C<to> is required and may be given as a positional argument, if it 
is the only one. It requires as value a GTC object or any scalar I<color definition> 
C<new> would accept. This color and the one held by the calling object 
are the two given colors, written about in the paragraph above.

C<steps> is the maximal amount of colors produced. The method stops if 
the calculated colors run out of gamut (L</is_in_gamut>). The number of 
steps defaults to 4.

C<tilt> needs a floating point number that defaults to zero. In that
case the L</distance> between two neighbours in the series will be always 
the same. A value of 0.2 will result in a serious where each distance is
20 percent larger than the previous one.

L<Graphics::Toolkit::Color::Manual::Philosophy/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
the gradient will be computed in. It defaults to I<OKHSL>, but unlike 
I<complement>, this operation can be computed in any space.

    my @colors = $darkblue->analogous( to => $midblue, steps => 5);     # 5 shades of blue
    @colors = $c->gradient( to => [14,10,222], steps => 3, tilt => 0.2, in => 'RGB' );


=head2 gradient

L<gradient|Graphics::Toolkit::Color::Manual::Set/gradient> creates a list 
of colors that are a gradual blend between two or more given colors.
It accepts four named arguments: C<to>, C<steps>, C<tilt>, C<in>.

Only C<to> is required and may be given as a positional argument, if it 
is the only one. It requires as value a GTC object or any scalar 
I<color definition> C<new> would accept. Alternatively you can pass an
ARRAY with any mix of GTC objects and scalar color definitions.

C<steps> is the amount of colors produced. It defaults to 10.

C<tilt> needs a floating point number that defaults to zero. In that
case you get a linear, uniform transition between start and end color.
Greater than zero values start with small color changes, steadily increasing 
the rate. The larger the number - the larger the effect and negative values
work vice versa.

L<Graphics::Toolkit::Color::Manual::Philosophy/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
the gradient will be computed in. It defaults to I<OKLAB>.

    my @colors = $c->gradient( to => $grey, steps => 5);       # we turn to grey
    @colors = $c1->gradient( to => [14,10,222], steps => 10, tilt => 1, in => 'HSL' );
    @colors = $c1->gradient( to => ['blue', 'brown', {h => 30, s => 44, l => 50}] );


=head2 cluster

L<cluster|Graphics::Toolkit::Color::Manual::Set/cluster> creates a list 
of GTC color objects that look similar to the given one but distinctly different.
It accepts three named arguments: C<radius>, C<minimal_distance> and L</in>.
The first two are required and can be written as C<r> and C<min_d>.
The color of the calling object is the center and part of the cluster.

C<radius> accepts a floating point number or an ARRAY of such numbers (one for each axis).
If one number is given, I<radius> is the maximal Euclidean L</distance> 
a color of the cluster can have from the center. In that case the method
uses cuboctahedral packing to fit as many colors as possible into that 
sphere with the given radius. If an ARRAY is provided, a simple cubic grid
of colors is created that extends on each axis by the given distance in 
both directions.

C<minimal_distance> is the minimal L</distance> two neighbours of the
cluster need to have in any direction.

L<Graphics::Toolkit::Color::Manual::Philosophy/in> is the name of the
L<color spaces|Graphics::Toolkit::Color::Manual::Space>
the cluster will be computed in. It defaults to I<OKLAB>.

    my @blues = $blue->cluster( radius => 4, minimal_distance => 0.3 );
    my @c = $color->cluster( r => [2,2,3], min_d => 0.4, in => 'YUV' );


=head1 SEE ALSO

=over 4

=item *

L<PDL::Transform::Color>

=item *

L<PDL::Graphics::ColorSpace>

=item *

L<Color::Scheme>

=item *

L<Graphics::ColorUtils>

=item *

L<Color::Fade>

=item *

L<Graphics::Color>

=item *

L<Graphics::ColorObject>

=item *

L<Color::Calc>

=item *

L<Convert::Color>

=item *

L<Color::Similarity>

=back

=head1 ACKNOWLEDGEMENT

These people contributed by providing patches, bug reports and useful
comments:

=over 4

=item *

Petr Pisar  (ppisar)

=item *

Slaven Rezic (srezic)

=item *

Gabor Szabo (szabgab)

=item *

Gene Boggs (GENE)

=item *

Stefan Reddig (sreagle)

=back

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=head1 COPYRIGHT

Copyright 2022-2026 Herbert Breunung.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
