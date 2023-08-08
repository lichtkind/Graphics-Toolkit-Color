
# read only color holding object with methods for relation, mixing and transitions

package Graphics::Toolkit::Color;
our $VERSION = '1.50';
use v5.12;

use Carp;
use Graphics::Toolkit::Color::Constant;
use Graphics::Toolkit::Color::Value;

use Exporter 'import';
our @EXPORT_OK = qw/color/;

my $new_help = 'constructor of Graphics::Toolkit::Color object needs either:'.
        ' 1. hash or ref (RGB, HSL or any other): ->new(r => 255, g => 0, b => 0), ->new({ h => 0, s => 100, l => 50 })'.
        ' 2. RGB array or ref: ->new( [255, 0, 0 ]) or >new( 255, 0, 0 )'.
        ' 3. hex form "#FF0000" or "#f00" 4. a name: "red" or "SVG:red".';

## constructor #########################################################

sub color { Graphics::Toolkit::Color->new ( @_ ) }

sub new {
    my ($pkg, @args) = @_;
    @args = ([@args]) if @args == 3;
    @args = ({ $args[0] => $args[1], $args[2] => $args[3], $args[4] => $args[5] }) if @args == 6;
    @args = ({ $args[0] => $args[1], $args[2] => $args[3], $args[4] => $args[5], $args[6] => $args[7] }) if @args == 8;
    return carp $new_help unless @args == 1;
    _new_from_scalar($args[0]);
}
sub _new_from_scalar {
    my ($color_def) = shift;
    my (@rgb, $name, $origin);
    if (not ref $color_def and substr($color_def, 0, 1) =~ /\w/){
        $name = $color_def;
        $origin = 'name';
        my $i = index( $color_def, ':');
        if ($i > -1 ){                        # resolve pallet:name
            my $pallet_name = substr $color_def, 0, $i;
            my $color_name = Graphics::Toolkit::Color::Constant::_clean_name(substr $color_def, $i+1);
            my $module_base = 'Graphics::ColorNames';
            eval "use $module_base";
            return carp "$module_base is not installed, but it's needed to load external colors" if $@;
            my $module = $module_base.'::'.$pallet_name;
            eval "use $module";
            return carp "$module is not installed, but needed to load color '$pallet_name:$color_name'" if $@;

            my $pallet = Graphics::ColorNames->new( $pallet_name );
            @rgb = $pallet->rgb( $color_name );
            return carp "color '$color_name' was not found, propably not part of $module" unless @rgb == 3;
        } else {                              # resolve name ->
            @rgb = Graphics::Toolkit::Color::Constant::rgb_from_name( $color_def );
            return carp "'$color_def' is an unknown color name, please check Graphics::Toolkit::Color::Constant::all_names()." unless @rgb == 3;
        }
    } elsif (ref $color_def eq __PACKAGE__) { # enables color objects to be passed as arguments
        ($name, @rgb, $origin) = @$color_def;
    } else {                                  # define color by numbers in any format
        my ($val, $origin) = Graphics::Toolkit::Color::Value::deformat( $color_def );
        return carp $new_help unless ref $val;
        @rgb = Graphics::Toolkit::Color::Value::deconvert( $val, $origin );
        return carp $new_help unless @rgb == 3;
        $name = Graphics::Toolkit::Color::Constant::name_from_rgb( @rgb );
    }
    bless [$name, @rgb, $origin];
}

## getter ##############################################################

sub name        { $_[0][0] }
sub string      { $_[0]->name ? $_[0]->name : $_[0]->values('rgb', 'hex') }

    sub rgb         { $_[0]->values('rgb') }
    sub red         { $_[0]->values('rgb', 'red') }
    sub green       { $_[0]->values('rgb', 'green') }
    sub blue        { $_[0]->values('rgb', 'blue') }
    sub rgb_hex     { $_[0]->values('rgb', 'hex') }
    sub rgb_hash    { $_[0]->values('rgb', 'hash') }
    sub hsl         { $_[0]->values('hsl') }
    sub hue         { $_[0]->values('hsl', 'hue') }
    sub saturation  { $_[0]->values('hsl', 'saturation') }
    sub lightness   { $_[0]->values('hsl', 'lightness') }
    sub hsl_hash    { $_[0]->values('hsl', 'hash') }

sub _rgb    { [@{$_[0]}[1 .. 3]] }
sub _origin {    $_[0][4] }
sub values      {
    my ($self, $space, @format) = @_;
    my @val = Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space);
    Graphics::Toolkit::Color::Value::format( \@val, $space, @format);
}

## measurement methods ##############################################################

sub distance_to { distance(@_) }
sub distance {
    my ($self) = shift;
    my ($c2, $space, $subspace) = @_;
    if (ref $c2 eq 'HASH' and exists $c2->{'to'}){
        ($c2, $space, $subspace) = ($c2->{'to'}, $c2->{'in'}, $c2->{'notice_only'});
    }
    return croak "missing argument: color object or scalar color definition" unless defined $c2;
    $c2 = color( $c2 );
    return croak "distance: second color badly defined" unless ref $c2 eq __PACKAGE__;
    $space //= 'HSL';
    return croak "color space $space is unknown" unless ref Graphics::Toolkit::Color::Value::space( $space );
    my @rgb1 =  Graphics::Toolkit::Color::Value::convert( $self->_rgb, $space );
    my @rgb2 =  Graphics::Toolkit::Color::Value::convert( $c2->_rgb, $space );
    Graphics::Toolkit::Color::Value::distance( \@rgb1, \@rgb2, $space, $subspace);
}

## single color creation methods #######################################

sub set {
    my ($self, @args) = @_;

}

sub add {
    my ($self, @args) = @_;
    my $add_help = 'Graphics::Toolkit::Color->add argument options: 1. a color object with optional factor as second arg, '.
        '2. a color name as string, 3. a color hex definition as in "#FF0000"'.
        '4. a list of thre values (RGB) (also in an array ref)'.
        '5. a hash with RGB and HSL keys (as in new, but can be mixed) (also in an hash ref).';
    if ((@args == 1 or @args == 2) and ref $args[0] ne 'HASH'){
        my @add_rgb;
        if (ref $args[0] eq __PACKAGE__){
            @add_rgb = $args[0]->rgb;
        } elsif (ref $args[0] eq 'ARRAY'){
            @add_rgb = @{$args[0]};
            return carp "array ref argument needs to have 3 numerical values (RGB) in it." unless @add_rgb == 3;
        } elsif (not ref $args[0] and not $args[0] =~ /^\d/){
            @add_rgb = _rgb_from_name_or_hex($args[0]);
            return unless @add_rgb > 1;
        } else { return carp $add_help }
        @add_rgb = ($add_rgb[0] * $args[1], $add_rgb[1] * $args[1], $add_rgb[2] * $args[1]) if defined $args[1];
        @args = @add_rgb;
    }
    my @rgb = $self->rgb;
    if (@args == 3) {
        @rgb = Graphics::Toolkit::Color::Value::RGB::trim( $rgb[0] + $args[0], $rgb[1] + $args[1], $rgb[2] + $args[2]);
        return new( __PACKAGE__, @rgb );
    }
    return carp $add_help unless @args and ((@args % 2 == 0) or (ref $args[0] eq 'HASH'));
    my %arg = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;
    my %named_arg = map {_shrink_key($_) =>  $arg{$_}} keys %arg; # clean keys
    $rgb[0] += delete $named_arg{'r'} // 0;
    $rgb[1] += delete $named_arg{'g'} // 0;
    $rgb[2] += delete $named_arg{'b'} // 0;
    return new( __PACKAGE__, trim_rgb( @rgb ) ) unless %named_arg;
    my @hsl = Graphics::Toolkit::Color::Value::HSL::_from_rgb( @rgb ); # withound rounding
    $hsl[0] += delete $named_arg{'h'} // 0;
    $hsl[1] += delete $named_arg{'s'} // 0;
    $hsl[2] += delete $named_arg{'l'} // 0;
    if (%named_arg) {
        my @nrkey = grep {/^\d+$/} keys %named_arg;
        return carp "wrong number of numerical arguments (only 3 needed)" if @nrkey;
        carp "got unknown hash key starting with", map {' '.$_} keys %named_arg;
    }
    @hsl = Graphics::Toolkit::Color::Value::HSL::trim( @hsl );
    color( { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
}

sub _shrink_key { lc substr( $_[0], 0, 1 ) }

sub blend {}

sub blend_with {
    my ($self, $c2, $pos) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : _new_from_scalar( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $pos //= 0.5;
    my $delta_hue = $c2->hue - $self->hue;
    $delta_hue -= 360 if $delta_hue >  180;
    $delta_hue += 360 if $delta_hue < -180;
    my @hsl = ( $self->hue        + ($pos * $delta_hue),
                $self->saturation + ($pos * ($c2->saturation - $self->saturation)),
                $self->lightness  + ($pos * ($c2->lightness  - $self->lightness))
    );
    @hsl = Graphics::Toolkit::Color::Value::HSL::trim( @hsl );
    color( H => $hsl[0], S => $hsl[1], L => $hsl[2] );
}

## color set creation methods ##########################################

# for compatibility
sub gradient {

}

sub gradient_to { hsl_gradient_to( @_ ) }

sub hsl_gradient_to {
    my ($self, $c2, $steps, $power) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = color( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $steps //= 3;
    $power //= 1;
    return carp "third argument (dynamics), has to be positive (>= 0)" if $power <= 0;
    return $self if $steps == 1;
    my @colors = ();
    my @delta_hsl = ($c2->hue - $self->hue, $c2->saturation - $self->saturation,
                                            $c2->lightness - $self->lightness  );
    $delta_hsl[0] -= 360 if $delta_hsl[0] >  180;
    $delta_hsl[0] += 360 if $delta_hsl[0] < -180;
    for my $i (1 .. $steps-2){
        my $pos = ($i / ($steps-1)) ** $power;
        my @hsl = ( $self->hue        + ($pos * $delta_hsl[0]),
                    $self->saturation + ($pos * $delta_hsl[1]),
                    $self->lightness  + ($pos * $delta_hsl[2]));
        @hsl = Graphics::Toolkit::Color::Value::HSL::trim( @hsl );
        push @colors, color( H => $hsl[0], S => $hsl[1], L => $hsl[2] );
    }
    $self, @colors, $c2;
}

sub rgb_gradient_to {
    my ($self, $c2, $steps, $power) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = color( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $steps //= 3;
    $power //= 1;
    return carp "third argument (dynamics), has to be positive (>= 0)" if $power <= 0;
    return $self if $steps == 1;
    my @colors = ();
    my @delta_rgb = ($c2->red - $self->red, $c2->green - $self->green, $c2->blue - $self->blue );
    for my $i (1 .. $steps-2){
        my $pos = ($i / ($steps-1)) ** $power;
        my @rgb = ( $self->red   + ($pos * $delta_rgb[0]),
                    $self->green + ($pos * $delta_rgb[1]),
                    $self->blue  + ($pos * $delta_rgb[2]));
        push @colors, color( @rgb);
    }
    $self, @colors, $c2;
}

sub complementary {
    my ($self) = shift;
    my ($count) = int ((shift // 1) + 0.5);
    my ($saturation_change) = shift // 0;
    my ($lightness_change) = shift // 0;
    my @hsl2 = my @hsl_l = my @hsl_r = $self->hsl;
    $hsl2[0] += 180;
    $hsl2[1] += $saturation_change;
    $hsl2[2] += $lightness_change;
    @hsl2 = Graphics::Toolkit::Color::Value::HSL::trim( @hsl2 ); # HSL of C2
    my $c2 = color( h => $hsl2[0], s => $hsl2[1], l => $hsl2[2] );
    return $c2 if $count < 2;
    my (@colors_r, @colors_l);
    my @delta = (360 / $count, (($hsl2[1] - $hsl_r[1]) * 2 / $count), (($hsl2[2] - $hsl_r[2]) * 2 / $count) );
    for (1 .. ($count - 1) / 2){
        $hsl_r[$_] += $delta[$_] for 0..2;
        $hsl_l[0] -= $delta[0];
        $hsl_l[$_] = $hsl_r[$_] for 1,2;
        $hsl_l[0] += 360 if $hsl_l[0] <    0;
        $hsl_r[0] -= 360 if $hsl_l[0] >= 360;
        push @colors_r, color( H => $hsl_r[0], S => $hsl_r[1], L => $hsl_r[2] );
        unshift @colors_l, color( H => $hsl_l[0], S => $hsl_l[1], L => $hsl_l[2] );
    }
    push @colors_r, $c2 unless $count % 2;
    $self, @colors_r, @colors_l;
}

sub bowl {

}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color - color palette creation helper

=head1 SYNOPSIS

    my $red = Graphics::Toolkit::Color->new('red'); # create color object
    say $red->add('blue')->name;                    # mix in RGB: 'magenta'
    Graphics::Toolkit::Color->new( 0, 0, 255)->hsl; # 240, 100, 50 = blue
    $blue->blend_with({H=> 0, S=> 0, L=> 80}, 0.1); # mix blue with a little grey in HSL
    $red->rgb_gradient_to( '#0000FF', 10);          # 10 colors from red to blue
    $red->complementary( 3 );                       # get fitting red green and blue


=head1 DESCRIPTION

ATTENTION: deprecated methods of the old API will be removed on version 2.0.

Graphics::Toolkit::Color, for short GTC, is the top level API of this
module. It is designed to get a fast access to a set of related colors,
that serve your need. While it can understand and output many color
formats, its primary (internal) format is RGB, because this it is
about colors that can be shown on the screen.

Humans access colors on hardware level (eye) in RGB, on cognition level
in HSL (brain) and on cultural level (language) with names.
Having easy access to all three and some color math should enable you to get the color
palette you desire quickly.

GTC are read only color holding objects with no additional dependencies.
Create them in many different ways (see section I<CONSTRUCTOR>).
Access its values via methods from section I<GETTER> or measure differences
and create related color objects via methods listed under I<METHODS>.



=head1 CONSTRUCTOR

An GTC object
There are many options to create a color objects.  In short you can
either use the name of a predefined constant or provide values in RGB
or HSL color space.

=head2 new( 'name' )

Get a color by providing a name from the X11, HTML (CSS) or SVG standard
or a Pantone report. UPPER or CamelCase will be normalized to lower case
and inserted underscore letters ('_') will be ignored as perl does in
numbers (1_000 == 1000). All available names are listed under
L<Graphics::Toolkit::Color::Constant/NAMES>. (See also: L</name>)

    my $color = Graphics::Toolkit::Color->new('Emerald');
    my @names = Graphics::Toolkit::Color::Constant::all_names(); # select from these

=head2 new( 'scheme:color' )

Get a color by name from a specific scheme or standard as provided by an
external module L<Graphics::ColorNames>::* , which has to be installed
separately. * is a placeholder for the pallet name, which might be:
Crayola, CSS, EmergyC, GrayScale, HTML, IE, Mozilla, Netscape, Pantone,
PantoneReport, SVG, VACCC, Werner, Windows, WWW or X. In ladder case
Graphics::ColorNames::X has to be installed. You can get them all at once
via L<Bundle::Graphics::ColorNames>. The color name will be  normalized
as above.

    my $color = Graphics::Toolkit::Color->new('SVG:green');
    my @s = Graphics::ColorNames::all_schemes();          # look up the installed

=head2 new( '#rgb' )

Color definitions in hexadecimal format as widely used in the web, are
also acceptable.

    my $color = Graphics::Toolkit::Color->new('#FF0000');
    my $color = Graphics::Toolkit::Color->new('#f00');    # works too


=head2 new( [$r, $g, $b] )

Triplet of integer RGB values (red, green and blue : 0 .. 255).
Out of range values will be corrected to the closest value in range.


    my $red = Graphics::Toolkit::Color->new( 255, 0, 0 );
    my $red = Graphics::Toolkit::Color->new([255, 0, 0]); # does the same


=head2 new( {r => $r, g => $g, b => $b} )

Hash with the keys 'r', 'g' and 'b' does the same as shown in previous
paragraph, only more declarative. Casing of the keys will be normalised
and only the first letter of each key is significant.

    my $red = Graphics::Toolkit::Color->new( r => 255, g => 0, b => 0 );
    my $red = Graphics::Toolkit::Color->new({r => 255, g => 0, b => 0}); # works too
    ... Color->new( Red => 255, Green => 0, Blue => 0);   # also fine

=head2 new( {h => $h, s => $s, l => $l} )

To define a color in HSL space, with values for L</hue>, L</saturation> and
L</lightness>, use the following keys, which will be normalized as decribed
in previous paragraph. Out of range values will be corrected to the
closest value in range. Since L</hue> is a polar coordinate,
it will be rotated into range, e.g. 361 = 1.

    my $red = Graphics::Toolkit::Color->new( h =>   0, s => 100, l => 50 );
    my $red = Graphics::Toolkit::Color->new({h =>   0, s => 100, l => 50}); # good too
    ... ->new( Hue => 0, Saturation => 100, Lightness => 50 ); # also fine

=head2 color

If writing

    Graphics::Toolkit::Color->new( ...);

is too much typing for you or takes to much space, import the subroutine
C<color>, which takes all the same arguments as described above.


    use Graphics::Toolkit::Color qw/color/;
    my $green = color('green');
    my $darkblue = color([20, 20, 250]);


=head1 GETTER / ATTRIBUTES

are read only methods - giving access to different parts of the
objects data.

=head2 name

String with normalized name (lower case without I<'_'>) of the color as
in X11 or HTML (SVG) standard or the Pantone report.
The name will be found and filled in, even when the object
was created with RGB or HSL values.
If no color is found, C<name> returns an empty string.
All names are at: L<Graphics::Toolkit::Color::Constant/NAMES>
(See als: L</new(-'name'-)>)

=head2 string

String that can be serialized back into a color an object
(recreated by Graphics::Toolkit::Color->new( $string )).
It is either the color L</name> (if color has one) or result of L</rgb_hex>.

=head2 values

Returns the color values.

First argument is the name of a color space: The options are:
'rgb' (default), hsl, cmyk and cmy.

Second argument is the format. That can vary from space to space but
generally available are C<list> (default), C<hash>, C<char_hash>
and names or initials of the value names of that particular space.
RGB also provides the option C<hex> to get values like '#aabbcc'.

    say $color->values();                      # get list of rgb : 0, 0, 255
    say $blue->values('RGB', 'hash');          # { red => 0. green => 0, blue => 255}
    say $blue->values('RGB', 'char_hash');     # { r => 0. g => 0, b => 255}
    say $blue->values('RGB', 'hex');           # '#00FFFF'
    say $color->values('HSL', 'saturation');   # 100

=head2 hue

DEPRECATED:
Integer between 0 .. 359 describing the angle (in degrees) of the
circular dimension in HSL space named hue.
0 approximates red, 30 - orange, 60 - yellow, 120 - green, 180 - cyan,
240 - blue, 270 - violet, 300 - magenta, 330 - pink.
0 and 360 point to the same coordinate. This module only outputs 0,
even if accepting 360 as input.

=head2 saturation

DEPRECATED:
Integer between 0 .. 100 describing percentage of saturation in HSL space.
0 is grey and 100 the most colorful (except when lightness is 0 or 100).

=head2 lightness

DEPRECATED:
Integer between 0 .. 100 describing percentage of lightness in HSL space.
0 is always black, 100 is always white and 50 the most colorful
(depending on L</hue> value) (or grey - if saturation = 0).

=head2 rgb

DEPRECATED:
List (no I<ARRAY> reference) with values of L</red>, L</green> and L</blue>.

=head2 hsl

DEPRECATED:
List (no I<ARRAY> reference) with values of L</hue>, L</saturation> and L</lightness>.

=head2 rgb_hex

DEPRECATED:
String starting with character '#', followed by six hexadecimal lower case figures.
Two digits for each of L</red>, L</green> and L</blue> value -
the format used in CSS (#rrggbb).

=head2 rgb_hash

DEPRECATED:
Reference to a I<HASH> containing the keys C<'red'>, C<'green'> and C<'blue'>
with their respective values as defined above.

=head2 hsl_hash

DEPRECATED:
Reference to a I<HASH> containing the keys C<'hue'>, C<'saturation'> and C<'lightness'>
with their respective values as defined above.


=head1 COLOR RELATION METHODS

create new, related color (objects) or compute similarity of colors

=head2 distance_to

A number that measures the distance (difference) between two colors:
1. the calling object (C1) and 2. a provided first argument C2 -
color object or scalar data that is acceptable by new method :
name or #hex or [$r, $g, $b] or {...} (see chapter L<CONSTRUCTOR>).

If no second argument is provided, than the difference is the Euclidean
distance in cylindric HSL space. If second argument is 'rgb' or 'RGB',
then its the Euclidean distance in RGB space. But als subspaces of both
are possible, as r, g, b, rg, rb, gb, h, s, l, hs, hl, and sl.

    my $d = $blue->distance_to( 'lapisblue' ); # how close to lapis color?
    # how different is my blue value to airy_blue
    $d = $blue->distance_to( 'airyblue', 'Blue'); # same amount of blue?
    $d = $color->distance_to( $c2, 'Hue' ); # same hue ?
    $d = $color->distance_to( [10, 32, 112 ], 'rgb' );
    $d = $color->distance_to( { Hue => 222, Sat => 23, Light => 12 } );

=head2 add

Create a Graphics::Toolkit::Color object, by adding any RGB or HSL values to current
color. (Same rules apply for key names as in new - values can be negative.)
RGB and HSL can be combined, but please note that RGB are applied first.

If the first argument is a Graphics::Toolkit::Color object, than RGB values will be added.
In that case an optional second argument is a factor (default = 1),
by which the RGB values will be multiplied before being added. Negative
values of that factor lead to darkening of result colors, but its not
subtractive color mixing, since this module does not support CMY color
space. All RGB operations follow the logic of additive mixing, and the
result will be rounded (trimmed), to keep it inside the defined RGB space.

    my $blue = Graphics::Toolkit::Color->new('blue');
    my $darkblue = $blue->add( Lightness => -25 );
    my $blue2 = $blue->add( blue => 10 );
    $blue->distance( $blue2 );           # == 0, can't get bluer than blue
    my $color = $blue->add( $c2, -1.2 ); # subtract color c2 with factor 1.2

=head2 blend_with

Create Graphics::Toolkit::Color object, that is the average of two colors in HSL space:
1. the calling object (C1) and 2. a provided argument C2 (object or a
refrence to data that is acceptable definition).

The second argument is the blend ratio, which defaults to 0.5 ( 1:1 ).
0 represents here C1 and 1 C2. Numbers below 0 and above 1 are possible,
and will be applied, as long the result is inside the finite HSL space.
There is a slight overlap with the add method which mostly operates in
RGB (unless told so), while this method always operates in HSL space.

    my $c = $color->blend_with( Graphics::Toolkit::Color->new('silver') );
    $color->blend_with( 'silver' );                        # same thing
    $color->blend_with( [192, 192, 192] );                 # still same
    my $difference = $color->blend_with( $c2, -1 );

=head1 COLOR SET CREATION METHODS

=head2 rgb_gradient_to

Creates a gradient (a list of colors that build a transition) between
current (C1) and a second, given color (C2).

The first argument is C2. Either as an Graphics::Toolkit::Color object or a
scalar (name, hex or reference), which is acceptable to a constructor.

Second argument is the number $n of colors, which make up the gradient
(including C1 and C2). It defaults to 3. These 3 colors C1, C2 and a
color in between, which is the same as the result of method blend_with.

Third argument is also a positive number $p, which defaults to one.
It defines the dynamics of the transition between the two colors.
If $p == 1 you get a linear transition - meaning the distance in RGB
space is equal from one color to the next. If $p != 1,
the formula $n ** $p starts to create a parabola function, which defines
a none linear mapping. For values $n > 1 the transition starts by sticking
to C1 and slowly getting faster and faster toward C2. Values $n < 1 do
the opposite: starting by moving fastest from C1 to C2 (big distances)
and becoming slower and slower.

    my @colors = $c->rgb_gradient_to( $grey, 5 );         # we turn to grey
    @colors = $c1->rgb_gradient_to( [14,10,222], 10, 3 ); # none linear gradient

=head2 hsl_gradient_to

Same as L</rgb_gradient_to> (what you normally want), but in HSL space.

=head2 complementary

Creates a set of complementary colors.
It accepts 3 numerical arguments: n, delta_S and delta_L.

Imagine an horizontal circle in HSL space, whith a center in the (grey)
center column. The saturation and lightness of all colors on that
circle is the same, they differ only in hue. The color of the current
color object ($self a.k.a C1) lies on that circle as well as C2,
which is 180 degrees (half the circumference) apposed to C1.

This circle will be divided in $n (first argument) equal partitions,
creating $n equally distanced colors. All of them will be returned,
as objects, starting with C1. However, when $n is set to 1 (default),
the result is only C2, which is THE complementary color to C1.

The second argument moves C2 along the S axis (both directions),
so that the center of the circle is no longer in the HSL middle column
and the complementary colors differ in saturation. (C1 stays unmoved. )

The third argument moves C2 along the L axis (vertical), which gives the
circle a tilt, so that the complementary colors will differ in lightness.

    my @colors = $c->complementary( 3, +20, -10 );

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

Copyright 2022-2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut

