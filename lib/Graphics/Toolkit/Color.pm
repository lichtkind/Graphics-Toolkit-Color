
# public user level API: computing color (sets), measure, IO for many formats and spaces

package Graphics::Toolkit::Color;
our $VERSION = '1.8';

use v5.12;
use warnings;
use Exporter 'import';
use Graphics::Toolkit::Color::Values;
use Graphics::Toolkit::Color::Operation::Set;

our @EXPORT_OK = qw/color/;

## constructor #########################################################

sub color { Graphics::Toolkit::Color->new ( @_ ) }

sub new {
    my ($pkg, @args) = @_;
    my $help = <<EOH;
    constructor new of Graphics::Toolkit::Color object needs either:
    1. a color name: new('red') or new('SVG:red')
    3. RGB hex string new('#FF0000') or new('#f00')
    4. RGB array or ARRAY ref: new( 255, 0, 0 ) or new( [255, 0, 0] )
    5. named array or ARRAY ref:  new( 'HSL', 255, 0, 0 ) or new( ['HSL', 255, 0, 0 ])
    6. named string:  new( 'HSL: 0, 100, 50' ) or new( 'ncol(r0, 0%, 0%)' )
    7. HASH or HASH ref with values from RGB or any other space:
       new(r => 255, g => 0, b => 0) or new({ hue => 0, saturation => 100, lightness => 50 })
EOH
    @args = ([ @args ]) if @args == 3 or Graphics::Toolkit::Color::Space::Hub::is_space_name( $args[0]);
    @args = ({ @args }) if @args == 6 or @args == 8;
    return $help unless @args == 1;
    my $self = _new_from_scalar_def( $args[0] );
    return (ref $self) ? $self : $help;
}
sub _new_from_scalar_def { # color defs for method args
    my ($color_def) = shift;
    return $color_def if ref $color_def eq __PACKAGE__;
    return _new_from_value_obj( Graphics::Toolkit::Color::Values->new_from_any_input( $color_def ) );
}
sub _new_from_value_obj {
    my ($value_obj) = @_;
    return $value_obj unless ref $value_obj eq 'Graphics::Toolkit::Color::Values';
    return bless {values => $value_obj};
}

## deprecated methods - deleted with 2.0
    sub string      { $_[0]{'name'} || $_[0]->{'values'}->string }
    sub rgb         { $_[0]->values( ) }
    sub red         {($_[0]->values( ))[0] }
    sub green       {($_[0]->values( ))[1] }
    sub blue        {($_[0]->values( ))[2] }
    sub rgb_hex     { $_[0]->values( as => 'hex') }
    sub rgb_hash    { $_[0]->values( as => 'hash') }
    sub hsl         { $_[0]->values( in => 'hsl') }
    sub hue         {($_[0]->values( in => 'hsl'))[0] }
    sub saturation  {($_[0]->values( in => 'hsl'))[1] }
    sub lightness   {($_[0]->values( in => 'hsl'))[2] }
    sub hsl_hash    { $_[0]->values( in => 'hsl', as => 'hash') }
    sub distance_to { distance(@_) }
    sub blend       { mix( @_ ) }
    sub blend_with { $_[0]->mix( with => $_[1], amount => $_[2], in => 'HSL') }
    sub gradient_to     { hsl_gradient_to( @_ ) }
    sub rgb_gradient_to { $_[0]->gradient( to => $_[1], steps => $_[2], dynamic => $_[3], in => 'RGB' ) }
    sub hsl_gradient_to { $_[0]->gradient( to => $_[1], steps => $_[2], dynamic => $_[3], in => 'HSL' ) }
    sub complementary { complement(@_) }

sub _split_named_args {
    my ($raw_args, $only_parameter, $required_parameter, $optional_parameter) = @_;
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
        return "Argument '$parameter_name' is missing\n" unless exists $arg_hash{$parameter_name};
        $clean_arg{ $parameter_name } = delete $arg_hash{ $parameter_name };
    }
    for my $parameter_name (keys %$optional_parameter){
        $clean_arg{ $parameter_name } = exists $arg_hash{$parameter_name}
                                      ? delete $arg_hash{ $parameter_name }
                                      : $optional_parameter->{ $parameter_name };
    }
    return "Inserted unknown argument(s): ".(join ',', keys %arg_hash)."\n" if %arg_hash;
    return \%clean_arg;
}

## getter ##############################################################
sub name         { $_[0]{'values'}->name }
sub closest_name {
    my ($self) = shift;
    my ($name, $distance) = $self->{'values'}->closest_name_and_distance;
    return wantarray ? ($name, $distance) : $name;
}

sub values       {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'in', [], {in => 'RGB', as => 'list', precision => undef, range => undef});
    my $help = <<EOH;
    GTC method 'values' accepts either no arguments, one color space name or four optional, named args:
    values (                  # no HASH ref around arguments
        in => 'HSL',          # color space name, defaults to "RGB"
        as => 'css_string',   # output format name, default is "list"
        range => 1,           # value range definition (SCALAR or ARRAY)
        precision => 3,       # value precision definition (SCALAR or ARRAY)

EOH
    return $arg.$help unless ref $arg;
    $self->{'values'}->formatted( @$arg{qw/in as range precision/} );
}

sub distance {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => 'RGB', select => undef, range => undef});
    my $help = <<EOH;
    GTC method 'distance' accepts as arguments either a scalar color definition or
    four named arguments, only the first being required:
    distance (                # no HASH ref around arguments
        to => 'green'         # color object or color definition (required)
        in => 'HSL'           # color space name, defaults to "RGB"
        select => 'red'       # axis name or names (ARRAY ref), default is none
        range => 2**16        # value range definition, defaults come from color space def
EOH
    return $arg.$help unless ref $arg;
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    return "target color definition: $arg->{'to'} is ill formed" unless ref $target_color;
    $self->{'values'}->distance( $target_color->{'values'}, @$arg{qw/in select range/} );
}

## single color creation methods #######################################
sub set {
    my ($self, @args) = @_;
    return <<EOH if @args % 2 or not @args or @args > 10;
    GTC method 'set' needs a value HASH (not a ref) whose keys are axis names or
    short names from one color space. If the chosen axis name(s) is/are ambiguous,
    you might add the "in" argument:
        set( green => 20 ) or set( g => 20 ) or
        set( hue => 240, in => 'HWB' )
EOH
    my $partial_color = { @args };
    my $color_space = delete $partial_color->{'in'};
    _new_from_value_obj( $self->{'values'}->set( $partial_color, $color_space ) );
}

sub add {
    my ($self, @args) = @_;
    return <<EOH if @args % 2 or not @args or @args > 10;
    GTC method 'add' needs a value HASH (not a ref) whose keys are axis names or
    short names from one color space. If the chosen axis name(s) is/are ambiguous,
    you might add the "in" argument:
        add( blue => -10 ) or set( b => -10 )
        add( hue => 100 , in => 'HWB' )
EOH
    my $partial_color = { @args };
    my $color_space = delete $partial_color->{'in'};
    _new_from_value_obj( $self->{'values'}->add( $partial_color, $color_space ) );
}

sub mix {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'with', ['with'], {in => 'RGB', amount => 50});
    my $help = <<EOH;
    GTC method 'mix' accepts three named arguments, only the first being required:
    mix (                              # no HASH ref around arguments
        with => ['HSL', 240, 100, 50]  # scalar color definition or ARRAY ref thereof
        amount => 20                   # percentage value or ARRAY ref thereof, default is 50
        in => 'HSL'                    # color space name, defaults to "RGB"
    Please note that either both or none of the first two arguments has to be an ARRAY.
    Both ARRAY have to have the same length.
EOH
    return $arg.$help unless ref $arg;
    my $recipe = _new_from_scalar_def( $arg->{'with'} );
    if (ref $recipe){
        $recipe = [{color => $recipe->{'values'}, percent => 50}];
        return "Amount argument has to be a sacalar value if only one color is mixed !\n".$help if ref $arg->{'amount'};
        $recipe->[0]{'percent'} = $arg->{'amount'} if defined $arg->{'amount'};
    } else {
        if (ref $arg->{'with'} ne 'ARRAY'){
            return "target color definition (argument 'with'): $arg->{'with'} is ill formed";
        } else {
            $recipe = [];
            for my $color_def (@{$arg->{'with'}}){
                my $color = _new_from_scalar_def( $color_def );
                return "target color definition: '$color_def' is ill formed" unless ref $color;
                push @$recipe, { color => $color->{'values'}, percent => 50};
            }
            if (exists $arg->{'amount'}){
                return "Amount argument has to be an ARRAY of values if multiple colors are mixed in !\n".$help if ref $arg->{'amount'} ne 'ARRAY'
                             or @{$arg->{'amount'}} != @{$arg->{'with'}};
                for my $amount_nr (0 .. $#{$arg->{'amount'}}){
                    $recipe->[$amount_nr]{'percent'} = $arg->{'amount'}[$amount_nr];
                }
            }
        }
    }
    _new_from_value_obj( $self->{'values'}->mix( $recipe, $arg->{'in'} ) );
}

## color set creation methods ##########################################
sub gradient {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'to', ['to'], {in => 'RGB', steps => 10, tilt => 0});
    my $help = <<EOH;
    GTC method 'gradient' accepts four named arguments, only the first is required:
    gradient (                    # no HASH ref around arguments
        to => 'blue'              # scalar color definition or ARRAY ref thereof
        steps =>  20              # count of produced colors, defaults to 10
        tilt  =>  1               # dynamics of color change, defaults to 0
        in => 'HSL'               # color space name, defaults to "RGB"
EOH
    return $arg.$help unless ref $arg;
    my @colors = ($self->{'values'});
    my $target_color = _new_from_scalar_def( $arg->{'to'} );
    if (ref $target_color) { push @colors, $target_color }
    else {
        return "Argument 'to' contains malformed color definition!\n".$help if ref $arg->{'to'} ne 'ARRAY';
        for my $color_def (@{$arg->{'to'}}){
            my $target_color = _new_from_scalar_def( $arg->{'to'} );
            return "Argument 'to' contains malformed color definition!\n".$help unless ref $target_color;
            push @colors, $target_color;
        }
    }
    return "Value of argument 'steps' has to be a whole number greater than zero !\n".$help if ref $arg->{'steps'} or $arg->{'steps'} < 1;
    $arg->{'steps'} = int $arg->{'steps'};
    $arg->{'tilt'} = 0 unless exists $arg->{'tilt'};
    map {_new_from_value_obj( $_ )} Graphics::Toolkit::Color::Operation::Set::gradient( \@colors, @$arg{qw/steps tilt in/} );
}

sub complement {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, 'steps', [], {steps => 1, tilt => 0});
    my $help = <<EOH;
    GTC method 'complement' is computed in HSL and has two named, optional arguments:
    complement (                       # no HASH ref around arguments
        steps => 20                    # count of produced colors, default is 1
        tilt => 10                     # default is 0
        tilt => {hue => 10, saturation => 20, lightness => 3} # or
        tilt => {hue => 10, s => {hue => -20, amount => 20 }, l => {hue => -10, amount => 3}}
EOH
    return $arg.$help unless ref $arg;
    return "Argument 'tilt' is malformed, has  !\n".$arg if ref $arg->{'tilt'} and ref $arg->{'tilt'} ne 'HASH';
    if (ref $arg->{'tilt'} eq 'HASH'){
        my @keys = sort keys( %{$arg->{'tilt'}} );
        return "Argument 'tilt' needs hash with three keys: 'h', 's' and 'l' !\n".$help unless @keys == 3;
        return "Argument 'tilt' got HASH ref which is missing key: 'hue' or 'h' !\n".$help
            unless lc $keys[0] eq 'h' or lc $keys[0] eq 'hue';
        return "Argument 'tilt' got HASH ref which is missing key: 'lightness' or 'l' !\n".$help
            unless lc $keys[0] eq 'l' or lc $keys[0] eq 'lightness';
        return "Argument 'tilt' got HASH ref which is missing key: 'saturation' or 's' !\n".$help
            unless lc $keys[0] eq 's' or lc $keys[0] eq 'saturation';


        return "Argument 'tilt' got HASH ref with 'hue' value which is not a integer number !\n".$help
            if ref $arg->{'tilt'}{$keys[0]} or not $arg->{'tilt'}{$keys[0]} =~ /^\d+$/;
        return "Argument 'tilt' got HASH ref with malformed 'lightness' value !\n".$help
            if ref $arg->{'tilt'}{$keys[1]} and $arg->{'tilt'}{$keys[1]} ne 'HASH';
        return "Argument 'tilt' got HASH ref with malformed 'saturation' value !\n".$help
            if ref $arg->{'tilt'}{$keys[2]} and $arg->{'tilt'}{$keys[2]} ne 'HASH';

        if (ref $arg->{'tilt'}{$keys[1]}){
            my @keys = sort keys( %{$arg->{'tilt'}{$keys[1]}} );
            return "Argument 'tilt' key 'lightness' needs values 'hue' and 'amount' !\n".$help
                if @keys != 2 or lc $keys[0] ne 'amount' or (lc $keys[1] ne 'h' and lc $keys[1] ne 'hue');
        }
        if (ref $arg->{'tilt'}{$keys[2]}){
            my @keys = sort keys( %{$arg->{'tilt'}{$keys[2]}} );
            return "Argument 'tilt' key 'saturation' needs values 'hue' and 'amount' !\n".$help
                if @keys != 2 or lc $keys[0] ne 'amount' or (lc $keys[1] ne 'h' and lc $keys[1] ne 'hue');
        }

    } else {
    }
    map {_new_from_value_obj( $_ )} Graphics::Toolkit::Color::Operation::Set::complement( @$arg{qw/steps tilt/} );
}

sub cluster {
    my ($self, @args) = @_;
    my $arg = _split_named_args( \@args, undef, ['radius', 'distance'], {in => 'RGB'});
    my $help = <<EOH;
    GTC method 'cluster' accepts three named arguments, the first two being required:
    cluster (                          # no HASH ref around arguments
        radius => [10, 5, 3]           # cuboid shaped cluster or
        radius => 3                    # ball shaped cluster
        distance => 0.5                # minimal distance between colors in cluster
        in => 'HSL'                    # color space name, defaults to "RGB"
EOH
    return $arg.$help unless ref $arg;
    return "Argument radius has to be a SCALAR or ARRAY ref\n".$help
                     if ref $arg->{'ardius'} and ref $arg->{'ardius'} ne 'ARRAY' and @{$arg->{'ardius'}} != 3;
    map {_new_from_value_obj( $_ )} Graphics::Toolkit::Color::Operation::Set::complement( @$arg{qw/radius distance in/});
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - calculate color (sets), IO many spaces and formats

=head1 SYNOPSIS

    use Graphics::Toolkit::Color qw/color/;

    my $red = Graphics::Toolkit::Color->new('red');  # create color object
    say $red->add( 'blue' => 255 )->name;            # add blue value: 'fuchsia'
    my @blue = color( 0, 0, 255)->values('HSL');     # 240, 100, 50 = blue
    $red->mix( with => [HSL => 0,0,80], amount => 10);# mix red with a little grey
    $red->gradient( to => '#0000FF', steps => 10);   # 10 colors from red to blue
    my @base_triple = $red->complement( 3 );         # get fitting red green and blue


=head1 WARNING

deprecated methods of the old API ( I<string>, I<rgb>, I<red>,
I<green>, I<blue>, I<rgb_hex>, I<rgb_hash>, I<hsl>, I<hue>, I<saturation>,
I<lightness>, I<hsl_hash>, I<blend>, I<blend_with>, I<gradient_to>,
I<rgb_gradient_to>, I<hsl_gradient_to>, I<complementary>)
will be removed with release of version 2.0.

=head1 DESCRIPTION

Graphics::Toolkit::Color, for short GTC, is the top level API of this
release and the only one a regular user should be concerned with.
Its main purpose is the creation of related colors or sets of them,
such as gradients, complements and others. But you can use it also to
convert and/or reformat color definitions.

GTC are read only, color holding objects with no additional dependencies.
Create them in many different ways (see section L</CONSTRUCTOR>).
Access its values via methods from section L</GETTER>.
Measure differences with the L</distance> method. L</SINGLE-COLOR>
methods create one new object that is related to the current one and
L</COLOR-SETS> methods will create a group of colors, that are not
only related to the current color but also have relations between each other.
Error messages will appear as return values.

While this module can understand and output color values in many spaces,
such as LAB, NCol, YIQ and many more, RGB is the (internal) primal one,
because GTC is about colors that can be shown on the screen, and these
are usually encoded in RGB.
Humans access colors on hardware level (eye) in RGB, on cognition level
in HSL (brain) and on cultural level (language) with names.
Having easy access to all of those plus some color math and many formats
should enable you to get the color palette you desire quickly.


=head1 CONSTRUCTOR

There are many options to create a color object. In short you can
either use the name of a constant or provide values, which are coordinates
in one of several L<color spaces|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>.
The latter can also be formatted in many ways as described
L<here|Graphics::Toolkit::Color::Space::Hub/FORMATS>.
From now on any input that the constructor method C<new> accepts,
is called a B<color definition>.

=head2 new('name')

Get a color by providing a name from the X11, HTML (CSS) or SVG standard
or a Pantone report. UPPER or CamelCase will be normalized to lower case
and inserted underscore letters ('_') will be ignored as perl does in
numbers (1_000 == 1000). All available names are listed
L<here | Graphics::Toolkit::Color::Name::Constant/NAMES>.

    my $color = Graphics::Toolkit::Color->new('Emerald');
    my @names = Graphics::Toolkit::Color::Name::all(); # select from these

=head2 new('scheme:color')

Get a color by name from a specific scheme or standard as provided by an
external module L<Graphics::ColorNames>::* , which has to be installed
separately. * is a placeholder for the pallet name, which might be:
Crayola, CSS, EmergyC, GrayScale, HTML, IE, Mozilla, Netscape, Pantone,
PantoneReport, SVG, VACCC, Werner, Windows, WWW or X. In latter case
I<Graphics::ColorNames::X> has to be installed. You can get them all at
once via L<Bundle::Graphics::ColorNames>.
The color name will be  normalized as above.

    my $color = Graphics::Toolkit::Color->new('SVG:green');
    my @schemes = Graphics::ColorNames::all_schemes();      # look up the installed

=head2 new('#rgb')

Color definitions in hexadecimal format as widely used in the web, are
also acceptable.

    my $color = Graphics::Toolkit::Color->new('#FF0000');
    my $color = Graphics::Toolkit::Color->new('#f00');    # works too

=head2 new('rgb($r,$g,$b)')

Variant of string format that is supported by CSS.

    my $red = Graphics::Toolkit::Color->new( 'rgb(255, 0, 0)' );
    my $blue = Graphics::Toolkit::Color->new( 'hsv(240, 100, 100)' );

=head2 new('rgb: $r, $g, $b')

String format (good for serialisation) that maximizes readability.

    my $red = Graphics::Toolkit::Color->new( 'rgb: 255, 0, 0' );
    my $blue = Graphics::Toolkit::Color->new( 'HSV: 240, 100, 100' );

=head2 new( [$r, $g, $b] )

Triplet of integer RGB values (red, green and blue : 0 .. 255).
Out of range values will be corrected to the closest value in range.

    my $red = Graphics::Toolkit::Color->new(         255, 0, 0 );
    my $red = Graphics::Toolkit::Color->new(        [255, 0, 0]); # does the same
    my $red = Graphics::Toolkit::Color->new( 'RGB',  255, 0, 0 ); # named tuple syntax
    my $red = Graphics::Toolkit::Color->new([ RGB => 255, 0, 0]); # named ARRAY

The named array syntax of the last example, as any here following,
work for any supported color space.


=head2 new({ r => $r, g => $g, b => $b })

Hash with the keys 'r', 'g' and 'b' does the same as shown in previous
paragraph, only more declarative. Casing of the keys will be normalised
and only the first letter of each key is significant.

    my $red = Graphics::Toolkit::Color->new( r => 255, g => 0, b => 0 );
    my $red = Graphics::Toolkit::Color->new({r => 255, g => 0, b => 0}); # works too
                        ... ->new( Red => 255, Green => 0, Blue => 0);   # also fine
              ... ->new( Hue => 0, Saturation => 100, Lightness => 50 ); # same color
                  ... ->new( Hue => 0, whiteness => 0, blackness => 0 ); # still the same

=head2 color

If writing

    Graphics::Toolkit::Color->new( ...);

is too much typing for you or takes to much space, import the subroutine
C<color>, which takes all the same arguments as described above.

    use Graphics::Toolkit::Color qw/color/;
    my $green = color('green');
    my $darkblue = color([20, 20, 250]);


=head1 GETTER

giving access to different parts of the objects data.

=head2 name

Returns the normalized name (lower case, without I<'_'>) of the color,
held by the object - even when the object was created with numerical values.
It returns an empty string when no color constant with the exact same values
was found in the I<X11> or I<HTML> (I<SVG>) standard or the I<Pantone report>.
If several constants have matching values, the shortest name will be returned.
All names are listed: L<here|Graphics::Toolkit::Color::Name::Constant/NAMES>.
(See also: L</new('name')>)

=head2 closest_name

Returns in list context two values, in scalar conext only one:
a color name as the method L</name> does, which has the shortst distance
in HSL to the currnt color. In list context you can additionally the
just mentioned L</distance> as a second return value.

=head2 values

Returns the numeric values of the color, held by the object. With fitting
arguments, the values from
L<all supported color spaces|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>
can be accessed and the values can be presented in many different
L<formats|Graphics::Toolkit::Color::Space::Hub/FORMATS>.
When given no arguments, the method returns a list with the I<red>, I<greem>
and I<blue> values, since I<RGB> is the default color space of this module.

The next possibility is to give exactly one argument: the name or alias name
of a L<color space|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>.
Then you get the of values in list form according to this space.
In other words: C<$color->values()> and C<$color->values('RGB')>
give you the same result.

The third and most powerful option is based upon named arguments, whithout
surrounding curly braces. Here you have four named, optional arguments:
L</in> (color space), C<as> (format), L</range> and C<precision>.
C<in> and C<range> work as describd behind the links.

C<as> has to be followed by the name of a recognized
L<format|Graphics::Toolkit::Color::Space::Hub/FORMATS>. Among these are
C<list> (default), C<hash>, C<char_hash>, C<array>, C<named_string> and C<css_string>.
Please note that C<hex_string> is only supported by I<RGB>

C<precision> is really exotic but sometimes you need to escape the numeric
precision set by a color spaces definition.
For instance C<LAB> values will have three decimals, no matter how precise
the input was. In case you prefer 4 decimals, just use C<precision => 4>.
A zero means no decimals and -1 is maximal precision which can spit out
more decimals than you prefer. Different precisions per axis ([1,2,3])
are possible.

    $blue->values();                                   # get list in RGB: 0, 0, 255
    $blue->values( in => 'RGB', as => 'list');         # same call
    $blue->values( in => 'RGB', as => 'named_array');  # ['rgb', 0, 0, 255]
    $blue->values( in => 'RGB', as => 'hash');         # { red => 0, green => 0, blue => 255}
    $blue->values( in => 'RGB', as => 'char_hash');    # { r => 0, g => 0, b => 255}
    $blue->values( in => 'RGB', as => 'named_string'); # 'rgb: 255, 0, 0'
    $blue->values( in => 'RGB', as => 'css_string');   # 'rgb(255, 0, 0)'
    $blue->values(              as => 'hex_string');   # '#0000ff'
    $red->values('HSL');                               # 0, 100, 50
    $red->values(            range => 2**16);          # 65536, 0, 0
    $red->values( in => 'HSB',  as => 'hash')->{'hue'};# 0
   ($red->values( 'HSB'))[0];                          # same, but shorter
    $color->values( range => 1, precision => 2);       # 0.66, 1, 0.5


=head2 distance

Is a floating point number that measures the Euclidean distance between
two colors, which represent two points in a color space. One color
is the calling object itself and the second one has to be provided as
either the only argument or the named argument L</to>, which is the only
required one.

The C<distance> is measured in I<RGB> color space unless told otherwise
by the argument L</in>.

The third argument is named C<select>. It's useful if you want to regard
only certain dimensions (axis). For instance if you want to know only
the difference in brightness between two colors, you type
C<select => 'lightness'> or C<select => 'l'>. This works of course only
if you choose I<HSL> or something similar like I<LAB> as color space.
Long or short axis names are accepted, but they all have to come from one
color space. You also can mention one axis several times for heightened
emphasis on this dimension.

The last argument is named L</range>, which can change the result drasticly.

    my $d = $blue->distance( 'lapisblue' );                 # how close is blue to lapis?
    $d = $blue->distance( to => 'airyblue', select => 'b'); # have they the same amount of blue?
    $d = $color->distance( to => $c2, in => 'HSL', select => 'hue' );  # same hue?
    $d = $color->distance( to => $c2, range => 'normal' );  # distance with values in 0 .. 1 range
    $d = $color->distance( to => $c2, select => [qw/r g b b/]); # double the weight of blue value differences


=head1 SINGLE COLOR

Methods to construct colors that are related to the current object.

=head2 set

Creates a new GTC color object that shares some values with the current one,
but differs in others. The altered values are provided as absoltue numbers.
If the resulting color will be outside of the given color space, the values
will be clamped so it will become a regular color of that space.

The axis of
L<all supported color spaces|Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>
have long and short names. For instance I<HSL> has I<hue>, I<sturation>
and I<lightness>. The short equivalents are I<h>, I<s> and I<l>. This
method accepts these axis names as named arguments and disregards if
characters are written upper or lower case. This method can not work,
if you mix axis names from different spaces or choose one axis more than once.
One solvable issue is when axis in different spaces have the same name.
For instance I<HSL> and I<HSV> have a I<saturation> axis. To disambiguate
you can add the named argument L</in>.

    $black->set( blue => 255 )->name;                  # blue, same as #0000ff
    my $new_color = $blue->set( saturation => 50 );    # pale blue, same as $blue->set( s => 50 );
    my $new_color = $blue->set( saturation => 50, in => 'HSV' );  # same, computed in HSL

=head2 add

Creates a new GTC color object that shares some values with the current one,
but differs in others. The altered values are provided relative to the current
ones. The rest works as described in L</set>.

    my $blue = Graphics::Toolkit::Color->new('blue');
    my $darkblue = $blue->add( Lightness => -25 );      # dim it down
    my $blue2 = $blue->add( blue => 10 );               # can it get bluer than blue ?
    my $blue3 = $blue->add( l => 10, in => 'LAB' );     # lighter color according in CIELAB

This method was mainly created to get lighter, darker or more saturated
colors by using it like:

    my $new_color = $color->add( saturation => 10);

=head2 mix

Create a new GTC object, that has the average values
between the calling object and another color (or several colors),
which is the only required input.
It takes three named arguments: C<with> (L</to>), C<amount> and L</in>.

C<with> works like L</to> in other methods with the exception that it
also accepts an ARRAY ref with several color definitions C<to> would get.

Per default I<mix> computes a 50-50 (1:1) mix. In order to change that,
employ the C<amount> argument which is the amount of the other color(s)
in percent. Again, if you want to mix more than two colors, the previous
and this argument has to hold an ARRAY reference with the same amount
of values in the same order. This means the first amount value corresponds
to the first color mentioned by argument C<with>.
If the amounts add up to more than 100 percent the current color will not
be present in the mix and the values will be recalculated by keeping the ratio.

    $color->mix( with => 'silver', amount => 60 );
    $color->mix( with => [qw/silver green/], amount => [10, 20]);      # mix three colors
    $blue->mix( with => {H => 240, S =>100, L => 50}, in => 'RGB' );   # teal


=head1 COLOR SETS

construct several interrelated color objects at once.

=head2 gradient

Creates a gradient (a list of color objects that build a transition)
between the current color held by the object and a second color,
provided by the named argument L</to>, which is a required.
Optionally C<to> accepts an ARRAY ref (square braces) with a list of
colors in order to create the most fancy, custom and nonlinear gradients.

Also required is the named argument C<steps>, which is the gradient length
or count of colors, which are part of this gradient. Included in there
are the start color (given by this object) and end color (given with C<to>).

The optional, floating point valued argument C<dynamic> makes the gradient
skewed toward one or the other end. Default is zero, which results in
a linear, uniform transition between start and stop.
Greater values of the argument let the color change rate start small,
steadily getting bigger. Negative values work vice versa.
The bigger the numeric value the bigger the effect.

Optional is the named argument L</in> (color space - details behind the link).

    # we turn to grey
    my @colors = $c->gradient( to => $grey, steps => 5);
    # none linear gradient in HSL space :
    @colors = $c1->gradient( to =>[14,10,222], steps => 10, dynamic => 3, in => 'HSL' );
    @colors = $c1->gradient( to =>['blue', 'brown', {h => 30, s => 44, l => 50}] );

=head2 complement

Creates a set of complementary colors, which will be computed in I<HSL>
color space. The method accepts two optional, named arguments.
Complementary colors normally have a different I<hue> value but same
I<saturation> and I<lightness>. They form a circle in I<HSL>, which will
be referenced  often in this paragraph.

If called with no arguments the method returns just THE complementary
color on the opposite "side" of the circle.

The named argument C<steps> (as in L</gradient>) sets the number of colors
computed, by dividing the perimeter of the circle in N equal parts
If you for instance use C<steps => 3> you will get the triadic colors,
that form a equilateral triangle on top of the circle. If no other named
arguments are used, you may omit the arguments name and type just C<complement(3)>.

The second argument is C<tilt>, can skew the circle in any direction and
provides several options to do that. In its simplest form you provide just
one number to skew the hue values of the complements. Positive values
move the complementary colors nearest to the given color even nearer -
negative values do the opposite. The same can be achieved by using the
form C<tilt => {hue => nnn}>. Into that HASH reference you could insert
the keys C<saturation> (or C<s>) and C<lightness> (or C<l>) to tilt the
circle along two more axis. They move the opposite "side" of the cirle
(THE complement color, lets call it TC) as the method L</add> would do.
With C<s => -10> you move TC towards the point, which was previously
the center of the circle, making some resulting colors more saturated
than others. C<l => 10> would move TC a bit up, making some colors lighter.
To get even more control you could determine to not move the circle
at the TC point but also at any hue position. In order to do that,
you have to provide the C<saturation> and C<lightness> keys with a HASH
reference that has two keys: C<amount> and C<hue> (or C<h>). C<amount>
does the same movements as just described. But the C<hue> value lets you
select the point on the circe you actually want to move. Too large or
negative C<hue> values will be rotated into the expected range of 0 ..359.

    my @colors = $c->complement( 4 );    # $self + 3 compementary (square) colors
    my @colors = $c->complement( steps => 3, tilt => {s => 20, l => -10} );
    my @colors = $c->complement( steps => 3, tilt => { hue => -40,
                                                         s => {amount => 300, hue => -50},
                                                         l => {amount => -10, hue => 30} });

=head2 cluster

Computes a set of colors that are all similar but not the same.
The method accepts three named arguments: C<radius>, C<distance> and L</in>,
of which the first two are required.

The produced colors form a ball or cuboid around the given color, depending
on what the argument C<radius> got. If it is a single number, it will be
a ball with the given radius. If it is an ARRAY of values you get the a
cuboid with the given dimensions.

The minimal distance between the colors is set by the argument C<distance>,
which is computed the same way as the method with that name. In a cuboid
shaped cluster the colors will be in a cubic grid inside the ball they
form a cuboctahedral grid, which is packed tighter but still obey the
demanded minimal distance.

    my @colors = $c->cluster( radius => [2,2,3], distance => 0.4, in => YUV );


=head1 ARGUMENTS

Some named arguments of the above listed methods reappear in several methods.
Thus they are explained here once. Please note that you must NOT wrap
the named args in curly braces (HASH ref).

=head2 in (with)

Expects the name of a color space as listed here:
L<Graphics::Toolkit::Color::Space::Hub/COLOR-SPACES>. The default color
space in this module is I<RGB>. Depending on the space the results
can be very different, since colors are very differently arranged and
have different distances to each other. Some colors might not even exists
in some spaces.

=head2 range

Every color space comes with range definitions for its values.
For instance I<red>, I<green> and I<blue> in I<RGB> go usually from zero
to 255 (0..255). In order to change that, many methods accept the named
argument C<range>. When only one interger value provided, it changes the
upper bound on all three axis and as lower bound is assumed zero.
Let's say you need I<RGB16> values with a range of 0 .. 65536,
then you type C<range => 65536> or C<range => 2**16>.

If you provide an ARRAY ref you can change the upper bounds of all axis
individually and in order to change even the lower boundaries, use ARRAY
refs even inside that. For instance in C<HSL> the C<hue> is normally
0 .. 359 and the other two axis are 0 .. 100. In order to set C<hue>
to -100 .. 100 but keep the other two untouched you would have to insert:
C<range => [[-100,100],100,100]>.

=head2 to

This argument receives a second or target color. It may come in form of
another GTC object or a color definition that is acceptable to the
constructor. But it has to be a scalar (string or (HASH) reference),
not a value list or hash.

=head1 SEE ALSO

=over 4

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

=head1 COPYRIGHT & LICENSE

Copyright 2022-2025 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut

