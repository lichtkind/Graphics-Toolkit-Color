
# public user level API: docs, help and arg cleaning

package Graphics::Toolkit::Color;
our $VERSION = '2.2';

use v5.12;
use warnings;
use Exporter 'import';
use Graphics::Toolkit::Color::Space::Util qw/is_nr/;
use Graphics::Toolkit::Color::SetCalculator;
use Graphics::Toolkit::Color::Error;

my $default_space_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
our @EXPORT_OK = qw/color is_in_gamut/;

## constructor #########################################################

sub color       { Graphics::Toolkit::Color->new ( @_ ) }

sub new {
    my ($pkg, @args) = @_;
    my $help = <<EOH;
     constructor new of Graphics::Toolkit::Color object needs either:
     1. a color name: 'red' or 'SVG:red'
     2. RGB hex string '#FF0000' or '#f00'
     3. RGB list or ARRAY ref: ( 255, 0, 0 ) or ( [255, 0, 0] )
     4. named list or named ARRAY:  ( 'HSL', 255, 0, 0 ) or ( ['HSL', 255, 0, 0 ])
        which works even nested: 'HSL' => [ 255, 0, 0 ] or ['HSL' => [ 255, 0, 0 ]]
     5. string:  new( 'HSL: 0, 100, 50' ) or new( 'ncol(r0, 0%, 0%)' )
     6. HASH or HASH ref with values from RGB or any other space:
        (r => 255, g => 0, b => 0) or { hue => 0, saturation => 100, lightness => 50 }
     7. or use the key 'color' with any SCALAR color definition in order to add
        the option 'raw' and/or 'range'
EOH
    my ($color_def, $range_def, $raw) = _compact_color_def_into_scalar( @args );
    return $help unless defined $color_def;
    my $self = _new_from_scalar_def( $color_def, $range_def, $raw );
    return (ref $self) ? $self : $help;
}
sub _compact_color_def_into_scalar {
    my (@args) = @_;
    return unless @args;
    if (not(@args % 2) and ($args[0] eq 'range' or $args[0] eq 'color' or $args[0] eq 'raw')){
		if (@args == 2 and $args[0] eq 'color'){ shift @args } # ->new (color => ...) is allowed
		elsif (@args > 2) {
			my %h = @args;
			return (delete( $h{'color'} ), delete( $h{'range'} ), delete( $h{'raw'} )) if @args == (scalar keys %h) * 2; # prevent double use of a key
	    }
	    else { return; }
	}
    my $first_arg_is_color_space = Graphics::Toolkit::Color::Space::Hub::is_space_name( $args[0] );
    @args = ([ $args[0], @{$args[1]} ]) if @args == 2 and $first_arg_is_color_space and ref $args[1] eq 'ARRAY';
    @args = ([ @args ])                 if @args == 3 or (@args > 3 and $first_arg_is_color_space);
    @args = ({ @args })                 if @args == 6 or  @args == 8;
    return (@args == 1) ? $args[0] : undef;
}
sub _new_from_scalar_def { # color defs of method arguments
    my ($color_def, $range_def, $raw) = @_;
    return $color_def if ref $color_def eq __PACKAGE__;
    return _new_from_value_obj( Graphics::Toolkit::Color::Values->new_from_any_input( $color_def, $range_def, $raw ) );
}
sub _new_from_value_obj {
    my ($value_obj) = @_;
    return $value_obj unless ref $value_obj eq 'Graphics::Toolkit::Color::Values';
    return bless {values => $value_obj};
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
             ? "Got odd number of values, please use key value pairs as arguments or one default argument !\n"
             : "Got odd number of values, please use key value pairs as arguments !\n"
    }
    my %arg_hash = @$raw_args;
    for my $parameter_name (@$required_parameter){
        if (ref $parameter_alias eq 'HASH' and exists $parameter_alias->{ $parameter_name }
            and exists $arg_hash{ $parameter_alias->{$parameter_name} }){
            $arg_hash{ $parameter_name } = delete $arg_hash{ $parameter_alias->{$parameter_name} };
        }
        return "Argument '$parameter_name' is missing\n" unless exists $arg_hash{$parameter_name};
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
sub values       {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [],
                               { in => $default_space_name, as => 'list', raw => 0,
                                 precision => undef, range => undef, suffix => undef } );
    my $help = <<EOH;
    GTC method 'values' accepts either no arguments, one color space name or four optional, named args:
    values ( ...
        in => 'HSL',          # color space name, defaults to "$default_space_name"
        as => 'css_string',   # output format name, default is "list"
        range => 1,           # value range (SCALAR or ARRAY), default set by space def
        precision => 3,       # value precision (SCALAR or ARRAY), default set by space
        suffix => '%',        # value suffix (SCALAR or ARRAY), default set by color space
        raw => 1,             # no value clamping, rounding and scaling only by arg request

EOH
    return $arg.$help unless ref $arg;
    $self->{'values'}->formatted( @$arg{qw/in as suffix range precision raw/} );
}

sub name         {
    my ($self, @args) = @_;
    return $self->{'values'}->name unless @args;
    my $arg = _split_named_args( \@args, 'from', [], {from => 'default', all => 0, full => 0, distance => 0});
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


sub is_in_gamut {
    my ($self, @args) = @_;
    my $help = <<EOH;
    GTC method 'is_in_gamut' returns a perlish pseudo boolean (0/1),
    telling you if a color is inside the gamut (range) of a color space or not.
    It accepts any color definition 'new' would. And like 'new' you have to give
    the color as value of the argument 'color', if you want to add information 
    about the color. If no color definition is provided, the method will operate
    upon the current color, held by the object.
    Unlike 'new', the argument 'raw' defaults here to true (1).
    is_in_gamut ( ...
        color => [12,1000,5], # color definition
        range => 2**16,       # observe these value ranges while reading the color definition
        in => 'HSL',          # check if color is in gamut of that space
                              # if no space name is provided, the color will be checked 
                              # against the boundaries of the space the color was defined in 
        raw => 0,             # clamp values to boundaries of the space, the color was defined in,
                              # before converting it into the space you check against
EOH
    unshift @args, $self unless ref $self eq __PACKAGE__;
    return $help if not ref $self and not @args;
    my ($color_def, $space_name, $range_def, $raw);
    if (not @args % 2 and @args and ($args[0] eq 'color' or $args[0] eq 'range' or $args[0] eq 'in' or $args[0] eq 'raw')){
		my %args = @args;
		$color_def = delete $args{'color'};
		$range_def = delete $args{'range'};
		$raw = delete $args{'raw'};
		$space_name = delete $args{'in'};
		return "Got no color definition!\n\n".$help unless defined $color_def or ref $self;
	} else {
		$color_def = _compact_color_def_into_scalar(@args);
		return "Got no valid color definition!\n\n".$help if @args and not defined $color_def;
	}
	my $values = (defined $color_def) 
	           ? Graphics::Toolkit::Color::Values->new_from_any_input( $color_def, $range_def, $raw // 1 )
	           : $self->{'values'};
	return $values unless ref $values;
    $values->is_in_gamut( $space_name );
}
	
## single color creation methods #######################################
sub apply {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['gamma'], {in => $default_space_name} ); 
    my $help = <<EOH;
    GTC method 'apply' accepts one named argument with a numeric value:
    apply ( ...
        gamma => 2.2,          # reverse is with 1 / 2.2
        gamma => {r=> 1, g=> 2, b=> 1.2},  # custom gamma per axis
        in => 'OKLAB',         # compute in oklab space
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
sub lighten {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::lighten( $self->{'values'}, $amount, $space_name ) );
}
sub darken {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::darken( $self->{'values'}, $amount, $space_name ) );
}
sub saturate {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::saturate( $self->{'values'}, $amount, $space_name ) );
}
sub desaturate {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::desaturate( $self->{'values'}, $amount, $space_name ) );
}
sub tint {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::tint( $self->{'values'}, $amount, $space_name ) );
}
sub shade {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::shade( $self->{'values'}, $amount, $space_name ) );
}
sub tone {
    my ($self, $amount, $space_name) = @_;
	_new_from_value_obj( Graphics::Toolkit::Color::Calculator::tone( $self->{'values'}, $amount, $space_name ) );
}

sub mix {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => $default_space_name, amount => undef});
    my $help = <<EOH;
    GTC method 'mix' accepts three named arguments, only the first being required:
    mix ( ...
        to => ['HSL', 240, 100, 50],   # scalar color definition or ARRAY ref thereof
        amount => 20,                  # percentage value or ARRAY ref thereof, default is 50
        in => 'HSL',                   # color space name, defaults to "$default_space_name"
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
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::mix( $self->{'values'}, $arg->{'to'}, $arg->{'amount'}, $color_space ) );
}

sub invert {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [], {in => $default_space_name, only => undef});
    my $help = <<EOH;
    GTC method 'invert' accepts one optional argument, which can be positional or named:
    invert ( ...
        in => 'HSL',                    # color space name, defaults to "$default_space_name"
        only => 'Saturation',           # inverts only second value of the tuple
        only => [qw/s l/],              # axis name or names have to match selected space
EOH
    return $arg.$help unless ref $arg and (not ref $arg->{'only'} or ref $arg->{'only'} eq 'ARRAY');
    my $color_space = Graphics::Toolkit::Color::Space::Hub::try_get_space( $arg->{'in'} );
    return "$color_space\n".$help unless ref $color_space;
    _new_from_value_obj( Graphics::Toolkit::Color::Calculator::invert( $self->{'values'}, $arg->{'only'}, $color_space ) );
}

## color set creation methods ##########################################
sub complement {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'steps', [], {steps => 1, tilt => 0, target => {}});
    my $help = <<EOH;
    GTC method 'complement' is computed in HSL and has two named, optional arguments:
    complement ( ...
        steps => 20,                                # count of produced colors, default is 1
        tilt => 10,                                 # default is 0
        target => {h => 10, s => 20, l => 3},       # sub-keys are independent, default to 0
EOH
    return $arg.$help unless ref $arg;
    return "Optional argument 'steps' has to be a number !\n".$help unless is_nr($arg->{'steps'});
    return "Optional argument 'steps' is zero, no complement colors will be computed !\n".$help unless $arg->{'steps'};
    return "Optional argument 'tilt' has to be a number !\n".$help unless is_nr($arg->{'tilt'});
    return "Optional argument 'target' has to be a HASH ref !\n".$help if ref $arg->{'target'} ne 'HASH';
    my ($target_values, $space_name);
    if (keys %{$arg->{'target'}}){
        ($target_values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $arg->{'target'}, 'HSL' );
        return "Optional argument 'target' got HASH keys that do not fit HSL space (use 'h','s','l') !\n".$help
            unless ref $target_values;
    } else { $target_values = [] }
    map {_new_from_value_obj( $_ )}
        Graphics::Toolkit::Color::SetCalculator::complement( $self->{'values'}, @$arg{qw/steps tilt/}, $target_values );
}

sub gradient {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {steps => 10, tilt => 0, in => $default_space_name});
    my $help = <<EOH;
    GTC method 'gradient' accepts four named arguments, only the first is required:
    gradient ( ...
        to    => 'blue',         # scalar color definition or ARRAY ref thereof
        steps => 20,             # count of produced colors, defaults to 10
        tilt  => 1,              # dynamics of color change, defaults to 0
        in    => 'HSL',          # color space name, defaults to "$default_space_name"
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
    my $arg = _split_named_args( \@args, undef, ['radius', 'minimal_distance'], {in => $default_space_name},
                                 {radius => 'r', minimal_distance => 'min_d'}                              );
    my $help = <<EOH;
    GTC method 'cluster' accepts three named arguments, the first two being required:
    cluster (  ...
        radius => 3                    # ball shaped cluster with cuboctahedral packing or
        r => [10, 5, 3]                # cuboid shaped cluster with cubical packing
        minimal_distance => 0.5        # minimal distance between colors in cluster
        min_d => 0.5                   # short alias for minimal distance
        in => 'HSL'                    # color space name, defaults to "$default_space_name"
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

GTC is a read only, one color representing object with no additional 
dependencies. This page will give you a quick overview of its methods. 
The  L<Manual|Graphics::Toolkit::Color::Manual> contains deeper explanations
and describes every argument and topic of interest in detail.
The behavior of error messages can be chosen, but defaults to using L<Carp>.

While this module can understand and output color values of many (30+)
L<color spaces|Graphics::Toolkit::Color::Manual::Space>,
L<RGB|Graphics::Toolkit::Color::Manual::Space/RGB>
is the (internal) primary one, because GTC is about colors that can be
shown on the screen, and these are usually encoded in I<RGB> (nonlinear standard RGB).
Humans access colors at hardware level (eye) in I<RGB>, at cognition level
in I<HSL> or I<LAB> (brain) and at the cultural level (language) with names.
With all these options available you can express easily and intuitively
with which color to start. And with a wealth of functions that understand
lots of arguments you can arrive at the desired color (palette) quickly.

=head1 CONSTRUCTOR

You create I<GTC> objects either with B<new> or the importable routine 
B<color>, which is a mere alias for convenience. It understands every
input I<new> would do. Because I<new> caters to many needs, there are
plenty of options to use it, but they can be divided into two groups.
The first group consists of a variety of I<color definitions>.
In simple terms: you just tell I<GTC> a color name or some number values
that define a color in one of the supported 
L<color spaces|Graphics::Toolkit::Color::Manual::Space> using one of the
below listed formats.
Please ensure that you have installed e.g. L<Graphics::ColorNames::SVG> or
L<Bundle::Graphics::ColorNames> if you want to use a color name from the 
I<SVG> standard. Read more about that subject L<here|Graphics::Toolkit::Color::Manual::Name>

    use Graphics::Toolkit::Color qw/color/;

    my $color = Graphics::Toolkit::Color->new( 'Emerald' );
    my $green = Graphics::Toolkit::Color->new( 'SVG:green');  
    my $navy  = color( 'navy' );                           # just a shortcut
    
    color(  r => 255, g => 0, b => 0 );                    # red (RGB)
    color( {r => 255, g => 0, b => 0});                    # red in char_hash format (RGB)
    color( Red => 255, Green => 0, Blue => 0);             # red in hash format (RGB)
    color( Hue => 0, Saturation => 100, Lightness => 50 ); # red in HSL
    color( Hue => 0, whiteness => 0, blackness => 0 );     # red in HWB

    color(  255, 0, 0 );                # list format, no space name -> RGB
    color( [255, 0, 0] );               # array format, RGB only (as input)
    color( 'RGB',   255, 0, 0  );       # named list format
    color(  RGB =>  255, 0, 0  );       # with fat comma
    color( [RGB =>  255, 0, 0] );       # named_array
    color(  RGB => [255, 0, 0] );       # nested_array
    color( [RGB => [255, 0, 0]]);       # even inside an ARRAY
    color(  YUV => .299,-0.168736, .5); # same color in YUV

    color( 'rgb: 255, 0, 0' );          # named string format, commas are not optional
    color( 'HSV: 240, 100, 100' );      # space name is case insensitive
    color( 'hsv(240, 100, 100)' );      # css_string format
    color( 'hsv(240, 100%, 100%)' );    # value suffix is optional
    color( 'rgb(255 0 0)' );            # commas are optional
									    
    color( '#FF0000' );                 # hex_string format, RGB only
    color( '#f00' );                    # hex_string format, short form

In order to add information to a color definition you have to provide the
color definition via the named argument B<color>. Then you can also use
the named argument B<range>, which allows you to set value ranges that 
override the color space standard. With the argument B<raw> you can force
GTC to accept values outside the defined value ranges. This might cause
unwanted behaviour for some operations.

    # this color is even outside the RGB16 range
    Graphics::Toolkit::Color->new( color => [100_000,0,0], range => 2**16, raw => 1 );

=head1 GETTER

These methods return information about a color, the relationship between 
colors, or the relationship between a color and its space.

=head2 values

=head2 name

=head2 closest_name

=head2 distance

=head2 is_in_gamut
    
B<values>

Returns the numeric values of the color, held by the object.
The method accepts six optional, named arguments:
L</in> (color space), C<as> (format), L</range>, C<precision>, C<suffix>. and I<raw>.
In most cases, only the first one is needed.

=head1 SINGLE COLOR

very simple high level functions
more powerful low level methods

=head2 lighten

=head2 darken

=head2 saturate

=head2 desaturate

=head2 tint

=head2 shade

=head2 tone

=head2 apply

=head2 set_value

=head2 add_value

=head2 mix

=head2 invert

=head1 COLOR SETS

These methods create sets of colors which are currently just a list of
GTC objects.

=head2 complement 

Produces a circle of complementary colors, currently only computed in HSL.
It listens to 3 named arguments: C<steps>, C<tilt>, C<target>
and creates THE complementary color if none are provided. 

C<steps> is the amont of colors produced, so a value of 3 would result in
triadic color set, 4 in a quadratic and so forth. 

With a positive C<tilt> value, the colors will aggregate more around THE
complementary color, with a negative value more around the given. 
To get the classical split complements you use a value of 3.42 
for triadic and 1.585 for quadratic colors.

The argument C<target> works a bit like L</add_value> on THE complement
and thus moving the whole circle.

    my @colors = $c->complement( 4 );                       # 'quadratic' colors
    my @colors = $c->complement( steps => 4, tilt => 4 );   # split-complementary colors
    my @colors = $c->complement( steps => 3, tilt => 2, target => { l => -10 } );
    my @colors = $c->complement( steps => 3, tilt => 2, target => { h => 20, s=> -5, l => -10 });

=head2 gradient

Creates a list of colors that are a gradual blend between two or more
colors. Its accepts four named arguments: C<to>, C<steps>, C<tilt>, C<in>.
Only the first one is required and may be provided as the only positional argument.

 

    # we turn to grey
    my @colors = $c->gradient( to => $grey, steps => 5);
    # none linear gradient in HSL space :
    @colors = $c1->gradient( to =>[14,10,222], steps => 10, tilt => 1, in => 'HSL' );
    @colors = $c1->gradient( to =>['blue', 'brown', {h => 30, s => 44, l => 50}] );


=head2 cluster


    my @blues = $blue->cluster( radius => 4, minimal_distance => 0.3 );
    my @c = $color->cluster( r => [2,2,3], min_d => 0.4, in => YUV );


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

