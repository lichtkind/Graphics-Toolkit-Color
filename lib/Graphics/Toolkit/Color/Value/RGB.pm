use v5.12;
use warnings;

# check, convert and measure color values in RGB space

package Graphics::Toolkit::Color::Value::RGB;
use Graphics::Toolkit::Color::Util ':all';
use Carp;
use Exporter 'import';
our @EXPORT_OK = qw/check_rgb trim_rgb delta_rgb distance_rgb hex_from_rgb rgb_from_hex/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our @getter = qw/rgb red green glue hex hash/;
our $name = 'rgb';
my $keys = { r => 1, g => 2, b => 3};

sub new {
    my $pkg = shift;
    my @rgb = trim(@_);
    bless \@rgb;
}
sub rgb   { @{$_[0]} }
sub red   { $_[0][0] }
sub green { $_[0][1] }
sub blue  { $_[0][2] }
sub hex   { hex_from_rgb( $_[0]->rgb )  }
sub hash  { as_hash( $_[0]->rgb )  }

sub check_rgb { &check }
sub check { # carp returns 1
    my (@rgb) = @_;
    my $range_help = 'has to be an integer between 0 and 255';
    return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless @rgb == 3;
    return carp "red value $rgb[0] ".$range_help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    return carp "green value $rgb[1] ".$range_help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    return carp "blue value $rgb[2] ".$range_help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    0;
}

sub trim_rgb { &trim }
sub trim { # cut values into the domain of definition of 0 .. 255
    my (@rgb) = @_;
    for (0..2){
        $rgb[$_] =   0 unless exists $rgb[$_];
        $rgb[$_] =   0 if $rgb[$_] <   0;
        $rgb[$_] = 255 if $rgb[$_] > 255;
    }
    $rgb[$_] = round($rgb[$_]) for 0..2;
    pop @rgb until @rgb == 3;
    @rgb;
}

sub delta_rgb { &delta }
sub delta { # \@rgb, \@rgb --> @rgb             distance as vector
    my ($rgb, $rgb2) = @_;
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb differences"
        unless ref $rgb eq 'ARRAY' and @$rgb == 3 and ref $rgb2 eq 'ARRAY' and @$rgb2 == 3;
    check_rgb(@$rgb) and return;
    check_rgb(@$rgb2) and return;
    (abs($rgb->[0] - $rgb2->[0]), abs($rgb->[1] - $rgb2->[1]), abs($rgb->[2] - $rgb2->[2]) );
}

sub distance_rgb { &distance }
sub distance { # \@rgb, \@rgb --> $d
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb distance " if @_ != 2;
    my @delta_rgb = delta( $_[0], $_[1] );
    return unless @delta_rgb == 3;
    sqrt($delta_rgb[0] ** 2 + $delta_rgb[1] ** 2 + $delta_rgb[2] ** 2);
}


sub hex_from_rgb {  return unless @_ == 3;  sprintf "#%02x%02x%02x", @_ }

sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my $hex = shift;
    return carp "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
    unless defined $hex and (length($hex) == 4 or length($hex) == 7) and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    (length $hex == 3) ? (map { CORE::hex($_.$_) } unpack( "a1 a1 a1", $hex))
                       : (map { CORE::hex($_   ) } unpack( "a2 a2 a2", $hex));
}

sub as_hash {
    my (@rgb) = @_;
    check(@rgb) and return;
    return {'red' => $rgb[0], 'green' => $rgb[1], 'blue' => $rgb[2], };
}

sub is_hash { has_hash_key_initials( $keys, $_[0] ) }  # % --> ?       # hash with righ keys
sub as_list { extract_hash_values ( $keys, $_[0] ) }  # % --> @list|0

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value::RGB - converter and getter for the RGB color space

=head1 SYNOPSIS

    my $red = Graphics::Toolkit::Color->new('red'); # create color object
    say $red->add('blue')->name;                    # mix in RGB: 'magenta'
    Graphics::Toolkit::Color->new( 0, 0, 255)->hsl; # 240, 100, 50 = blue
    $blue->blend_with({H=> 0, S=> 0, L=> 80}, 0.1); # mix blue with a little grey in HSL
    $red->rgb_gradient_to( '#0000FF', 10);          # 10 colors from red to blue
    $red->complementary( 3 );                       # get fitting red green and blue


=head1 DESCRIPTION

Read only color holding objects with no additional dependencies.
Create them in many different ways (see section I<CONSTRUCTOR>).
Access its values via methods from section I<GETTER> or measure differences
and create related color objects via methods listed under I<METHODS>.

Humans access colors on hardware level (eye) in RGB, on cognition level
in HSL (brain) and on cultural level (language) with names.
Having easy access to all three and some color math should enable you to get the color
palette you desire quickly.


=head1 CONSTRUCTOR

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

Triplet of integer RGB values (L</red>, L</green> and L</blue> : 0 .. 255).
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

=head2 red

Integer between 0 .. 255 describing the red portion in RGB space.
Higher value means more color and an lighter color.

=head2 green

Integer between 0 .. 255 describing the green portion in RGB space.
Higher value means more color and an lighter color.

=head2 blue

Integer between 0 .. 255 describing the blue portion in RGB space.
Higher value means more color and an lighter color.

=head2 hue

Integer between 0 .. 359 describing the angle (in degrees) of the
circular dimension in HSL space named hue.
0 approximates red, 30 - orange, 60 - yellow, 120 - green, 180 - cyan,
240 - blue, 270 - violet, 300 - magenta, 330 - pink.
0 and 360 point to the same coordinate. This module only outputs 0,
even if accepting 360 as input.

=head2 saturation

Integer between 0 .. 100 describing percentage of saturation in HSL space.
0 is grey and 100 the most colorful (except when lightness is 0 or 100).

=head2 lightness

Integer between 0 .. 100 describing percentage of lightness in HSL space.
0 is always black, 100 is always white and 50 the most colorful
(depending on L</hue> value) (or grey - if saturation = 0).

=head2 rgb

List (no I<ARRAY> reference) with values of L</red>, L</green> and L</blue>.

=head2 hsl

List (no I<ARRAY> reference) with values of L</hue>, L</saturation> and L</lightness>.

=head2 rgb_hex

String starting with character '#', followed by six hexadecimal lower case figures.
Two digits for each of L</red>, L</green> and L</blue> value -
the format used in CSS (#rrggbb).

=head2 rgb_hash

Reference to a I<HASH> containing the keys C<'red'>, C<'green'> and C<'blue'>
with their respective values as defined above.

=head2 hsl_hash

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

