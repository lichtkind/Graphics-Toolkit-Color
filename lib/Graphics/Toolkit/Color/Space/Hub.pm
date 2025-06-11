
# check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;
use Carp;
our $base_package = 'RGB';
my @space_packages = ( $base_package,
                       qw/CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/,   # CubeHelix OKLAB
                       qw/CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/); # search order
my %space_obj    =  map { $_ => require "Graphics/Toolkit/Color/Space/Instance/$_.pm" } @space_packages; # outer names
my %space_lookup = map { $_->name => $_ } values %space_obj;                                         # full color space names
my @space_names  = map { $space_obj{$_}->name } @space_packages;                                      # names in search oder

sub get_space { $space_lookup{ uc $_[0] } if exists $space_lookup{ uc $_[0] } }
sub is_space  { (defined $_[0] and ref get_space($_[0])) ? 1 : 0 }
sub base_space { $space_lookup{ $base_package } }
sub space_names { @space_names }

#### space API #########################################################

sub add_space {
    my $space = shift;
    return 'got no Graphics::Toolkit::Color::Space object' unless ref $space eq 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    return "space objct has no name" unless $name;
    return "name $name is already taken as color space name" if ref get_space( $name );
    $space_lookup{ $name } = $space;
    $space_lookup{ $space->alias } = $space if $space->alias and not ref get_space( $space->alias );
}

sub remove_space {
    my $name = shift;
    return "got no name as argument" unless defined $name and $name;
    return "no known color space with name $name" unless ref get_space( $name );
    delete $space_lookup{ $name };
}

sub check_space_name {
    return unless defined $_[0];
    my $error = "called with unknown color space name '$_[0]', please try one of: " . join (', ', @space_packages);
    is_space( $_[0] ) ? 0 : carp $error;
}
sub _check_values_and_space {
    my ($sub_name, $values, $space_name) = @_;
    $space_name //= $base_package;
    check_space_name( $space_name ) and return;
    my $space = get_space($space_name);
    $space->is_value_tuple( $values ) ? $space
                                : 'need an ARRAY ref with '.$space->axis." $space_name values as first argument of $sub_name";
}

#### value API #########################################################

sub read {
    my ($color, $range, $precision, $suffix) = @_;
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my @res = $color_space->read( $color, $range, $precision, $suffix );
        next unless @res;
        return wantarray ? ($res[0], $color_space->name, $res[1]) : $res[0];
    }
    return undef;
}

sub write {
    my ($color, $space_name, $format_name, $range, $precision, $suffix) = @_;
    my $color_space = get_space( $space_name );
    return unless ref $color_space;
    $color_space->write( $color, $format_name, $range, $precision, $suffix );
}

sub partial_hash_deformat { # convert partial hash into
    my ($value_hash) = @_;
    return unless ref $value_hash eq 'HASH';
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my $pos_hash = $color_space->basis->deformat_partial_hash( $value_hash );
        next unless ref $pos_hash eq 'HASH';
        return wantarray ? ($pos_hash, $color_space->name) : $pos_hash;
    }
    return undef;
}

sub deformat { # convert from any format into list of values of any space
    my ($formated_values) = @_;
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my @val = $color_space->deformat( $formated_values );
        return \@val, $space_name if defined $val[0];
    }
}

sub format { # @tuple --> % | % |~ ...
    my ($values, $space_name, $format_name) = @_;

    my $space = _check_values_and_space( 'format', $values, $space_name );
    return unless ref $space;
    my @values = $space->format( $values, $format_name // 'list' );
    return @values, carp "got unknown format name: '$format_name'" unless defined $values[0];
    return @values == 1 ? $values[0] : @values;
}

sub denormalize { # result clamped, alway in space
    my ($values, $space_name, $range) = @_;
    my $space = _check_values_and_space( 'denormalize', $values, $space_name );
    return unless ref $space;
    $values = $space->clamp($values, 'normal');
    $space->denormalize( $values, $range);
}

sub normalize {
    my ($values, $space_name, $range) = @_;
    my $space = _check_values_and_space( 'normalize', $values, $space_name );
    return unless ref $space;
    $values = $space->clamp($values, $range);
    return $values unless ref $values;
    $space->normalize( $values, $range);
}

sub deconvert { # @... --> @RGB (base color space) # normalized values only
    my ($values, $space_name) = @_;
    my $space = _check_values_and_space( 'deconvert', $values, $space_name );
    return unless ref $space;
    $values = $space->clamp( $values, 'normal', -1);
    return $values if $space->name eq base_space->name;
    $space->convert( $values, $base_package);
}

sub convert { # @RGB --> $@...|!~                     # normalized values only
    my ($values, $space_name) = @_;
    my $space = _check_values_and_space( 'convert', $values, $space_name );
    return $space unless ref $space;
    $values = base_space->clamp( $values, 'normal', -1);
    return $values if $space->name eq base_space->name;
    $space->deconvert( $values, $base_package);
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space::Hub - convert, (de-)normalize and format color value tuples

=head1 SYNOPSIS

Central store for all color space objects, which hold color space specific
information and algorithms.

    use Graphics::Toolkit::Color::Space::Hub;

    my $true = Graphics::Toolkit::Color::Space::Hub::is_space( 'HSL' );
    my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space( 'HSL');
    my $RGB = Graphics::Toolkit::Color::Space::Hub::base_space();
    Graphics::Toolkit::Color::Space::Hub::space_names();     # all space names

    $HSL->normalize([240,100, 0]);         # 2/3, 1, 0
    $HSL->convert([240, 100, 0], 'RGB');   #   0, 0, 1
    $HSL->deconvert([0, 0, 1], 'RGB');     # 2/3, 1, 0
    $RGB->denormalize([0, 0, 1]);          #   0, 0, 255
    $RGB->format([0, 0, 255], 'hex');      #   '#0000ff'

    # [0, 0, 255] , 'RGB'
    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( '#0000ff' );

=head1 DESCRIPTION

This module is supposed to be used internally and not directly by the user,
unless he wants to add his own color space.
Therefore it exports no symbols and the methods are much less DWIM then
the main module.



=head1 COLOR SPACES

Up next, a listing of all supported color spaces. These are mathematical
constructs that associate each color with a point inside this space.
The numerical values of a color definition become coordinates along
axis that express different properties. The closer two
colors are along an axis the more similar are they in that property.
All color spaces are finite and only certain value ranges along an
axis are acceptable. Many spaces have 3 dimensions (axis) and are
completely lineary like in Euclidean (everyday) geometry.
A few spaces have more axis and some spaces are cylindrical. That
means that some axis are not lines but circles and the associated value
descibes an angle.

Color definitions contain either the name of a space or the names
of its axis (long or short). If the space name or its abbreviated alias
is used, the values have to be provided in the same order as the axis
described here.

Color space or axis names may be written in any combination of upper and
lower case characters, but I recommended to use the spelling presented here.
Each axis has also two specific names, one long and one short, which are
in rare cases equal. In order to define a color in that space you need
to provide for each axis one value that is inside the required value range
and of a specificed type (int or real with amount of decimals).

While I acknowledge that some of the spaces below should be called systems
to be technically correct, they still will be called spaces here, because
the main goal of this software is seamless interoperabilitiy between them.


=head2 RGB

... is the default color space of this CPAN module. It is used
by most computer hardware like monitors and follows the logic of additive
color mixing as produced by an overlay of three colored light beams.
Its is a completely Cartesian (Euclidean) 3D space and thus a RGB tuple
consists of three integer values: B<red> (short B<r>) range: 0 .. 255, B<green>
(short B<g>) range: 0 .. 255 and B<blue> (short B<b>) range: 0 .. 255.
A higher value means a stronger beam of that base color flows into the mix
above a black background, so that black is (0,0,0), white (255,255,255)
and a pure red (fully saturated color) is (255, 0, 0).


=head2 CMY

is the complement of L<RGB> since it follows the logic of subtractive
color mixing as used in printing. Think of it as the amount of colored
ink on white paper, so that white is (0,0,0) and black (1,1,1).
It uses normalized real value ranges: 0 .. 1.
An CMY tuple has also three values:
B<cyan> (short B<c>) is the inverse of I<red>,
B<magenta> (short B<m> ) is inverse to I<green> and
B<yellow> (short B<y>) is inverse of I<blue>.

=head2 CMYK

is an extension of L<CMY> with a fourth value named B<key> (short B<k>),
which is the amount of black ink mixed into the CMY color.
It also has an normalized range of 0 .. 1.


=head2 HSL

.. is a cylindrical space that orders colors along cognitive properties.
The first dimension is the angular one and it rotates in 360 degrees around
the rainbow of fully saturated colors: 0 = red, 15 approximates orange,
60 - yellow 120 - green, 180 - cyan, 240 - blue, 270 - violet,
300 - magenta, 330 - pink. 0 and 360 points to the same coordinate.
This module only outputs 0, even if accepting 360 as input. Thes second,
linear dimension (axis) measures the distance between a point the the center
column of the cylinder at the same height, no matter in which direction.
The center column has the value 0 (white .. gray .. black) and the outer
mantle of the cylinder contains the most saturated, purest colors.
The third, vertical axis reaches from bottom value 0 (always black no
matter the other values) to 100 (always white no matter the other values).
In summary: HSL needs three integer values: B<hue> (short B<h>) (0 .. 359),
B<saturation> (short B<s>) (0 .. 100) and B<lightness> (short B<l>) (0 .. 100).

=head2 HSV

... is also cylindrical but can be shaped like a cone.
Similar to HSL we have B<hue> and B<saturation>, but the third axis is
named B<value> (short B<v>). In L<HSL> we always get white, when I<lightness>
is 100. In HSV additionally I<saturation> has to be zero to get white.
When I<saturation> is 100 and I<value> is 100 we have the purest, most
sturated color of whatever I<hue> sets.

=head2 HSB

Is an alias to L<HSV>, just the I<value> axis is renamed with B<brightness> (B<b>).

=head2 HWB

An inverted L<HSV>, where the saturated, pure colors are on the center
column of the cylinder. It still has the circular B<hue> dimension,
as described in C<HSL>. The other two, linear dimensions (also 0 .. 100)
are B<whiteness> (B<w>) and B<blackness> (B<b>), desribing how much white
or black are mixed in. If both are zero, than we have a pure color.
I<whiteness> of 100 always leads to white and I<blackness> of 100 always
leads to black. The space is truncated as a cone so the sum of I<whiteness>
and I<blackness> can never be greater than 100.

=head2 NCol

Is a more human readable derivation of the L<HWB> space with an altered
B<hue> axis, whith values that consists of a letter and two digits.
The letter demarks one of the six areas around the rainbow B<R> (I<Red>),
B<Y> (I<Yellow>), B<G> (I<Green), B<C> (I<Cyan>), B<B> (I<Blue>),
B<M> (I<Magenta). The two digits after this letter are an angular value,
measuring the distance between the pure color (as stated by the letter)
and the described color (toward the next color on the rainbow).
The B<whiteness> and B<blackness> axis have values with the suffix I<%>,
since they are percentual values as well.

=head2 YIQ

Is a space developed for I<NTSC> to broadcast a colored television signal,
which is still compatible with black and white TV. It achieves this by
sending the B<luminance> (short I<y>) (sort of brightness with real range
of 0 .. 1) in channel number one, which is all black and white TV needs.
Additionally we have the axis of B<in-phase> (short B<i>)
(cyan - orange - balance, range -0.5959 .. 0.5959) and
B<quadrature> (short B<q>) (magenta - green - balance, range: -0.5227 .. 0.5227).

=head2 YUV

Is a slightly altered version of L<YIQ> for the I<PAL> TV standard.
We use  here the variant called B<YCbCr> (can also be used as space name),
because of it's computation friendly value ranges and because it is still
relevant in video and image formats and compression algorithms.
It has three Cartesian axis: 1. B<luma> (short B<y>) with a real value
range of 0..1, 2. B<Cb> (short I<u>, -0.5 .. 0.5) and 3. C<Cr>
(short I<v>, -0.5 .. 0.5). (see also L<CIELUV>)

=head2 CIEXYZ

this space (alias name B<XYZ>) has the axis B<X>, B<Y> and B<Z> that
refer to the red, green and blue receptors (cones) in the retina (on the
back side of the eye), because they measure a lot more than than just
exactly those colors. The values in that space tell you about the amount
of chemical and neurological activity a color produces inside the eye.
In this space short and long names of the linear axis are the same and
the values range from zero to to 0.95047, 1 and 1.08883 respectively.
These values are due to the use of the standard luminant I<D65>.

=head2 CIELAB

Is a derivate of L<CIEXYZ> that reorderes the colors to positions that
reflect how the brain processes them. It uses three information channels.
One named B<L> (lightness) with a real value range of (0 .. 100).
Second is channel B<a>, that reaches from red to green (-500 .. 500) and
thirdly B<b> from yellow to blue (-200 .. 200). The long names of the axis
names contain a '*' and are thus: B<L*>, B<a*> and B<b*>. The I<a> and I<b>
axis reflect the opponent color theory and the short alias name of this
space is B<LAB>.

=head2 CIELUV

Is a more perceptually uniform  version of L<CIELAB> and the axis I<a>
and I<b> got renamed to I<u> and I<v >but did not change their meaning.
It has also three Cartesian dimension named L*, u* and v*, (short names
have only the first letter). Their real valued ranges are 0 .. 100,
-134 .. 220 and -140 .. 122. The short alias name of this space is B<LUV>.

=head2 CIELCHab

.. is the cylindrical version of the L<CIELAB> with the dimensions
B<luminance> (short B<l>), B<chroma> (short B<c>) and B<hue> (short B<h>).
The real valued ranges are from zero to 100, 539 and 360 respectively.
Like with the L<HSL> and L<HSV>, hue is the circular dimensions and its
values are meant as degrees in a circle.
The short alias name of this space is B<LCH>.

=head2 CIELCHuv

.. is the cylindrical version of the L<CIELUV> and works similar to
L<CIELCHab> except the real valued range of B<chroma> is (0 .. 441) and
the space has no alias name.


=head1 RANGES

As pointed out in the previous paragraph, each dimension of color space has
its default range. However, one can demand custom value ranges, if the method
accepts a range decriptor as argument. If so, the following values are accepted:

    'normal'          real value range from 0 .. 1 (default)
    number            integer range from zero to that number
    [0 1]             real number range from 0 to 1, same as 'normal'
    [min max]         range from min .. max, int if both numbers are int
    [min max 'int']   integer range from min .. max
    [min max 'real']  real number range from min .. max

The whole definition has to be an ARRAY ref. Each element is the range definition
of one dimension. If the definition is not an ARRAY but a single value it is applied
as definition of every dimension.


=head1 FORMATS

These formats are available in all color spaces.

=head2 list

Is the default format and the only one not containing the name of th
color space.

    (10, 20, 30)

=head2 named_string

    'RGB: 10, 20, 30'

=head2 css_string

    'rgb(10, 20, 30)'

=head2 named_array

    [RGB => 10, 20, 30]

=head2 hash

    { red => 10, green => 20, blue => 30 }

=head2 char_hash

    { r => 10, g => 20, b => 30 }

=head1 ROUTINES

This package provides two sets of routines. Thes first is just a lookup
of what color space objects are available. The second set consists of three
pairs or routines about 3 essential operations of number values and their
reversal. The full pipeline for the translation of color values is:

    1. deformat (into a value list)
    2. normalize (into 0..1 range), remove sufix
    3. convert/deconvert (into target color space)
    4. denormalize (into target range), add suffix
    5. format (into target format)


=head2 space_names

Returns a list of string values, which are the names of all available
color space. See L</COLOR-SPACES>.

=head2 is_space

Needs one argument, that supposed to be a color space name.
If it is, the result is an 1, otherwise 0 (perlish pseudo boolean).

=head2 get_space

Needs one argument, that supposed to be a color space name.
If it is, the result is the according color space object, otherwise undef.

=head2 base_space

Return the color space object of (currently) RGB name space.
This name space is special since every color space object provides
converters from and to RGB, but the RGB itself has no converter.


=head2 normalize

Normal in a mathematical sense means the range of acceptable values are
between zero and one. Normalization means there for altering the values
of numbers to fit in that range. For instance standard RGB values are
integers between zero and 255. Normalizing them essentially means
just dividing them with 255.


    my @rgb = Graphics::Toolkit::Color::Space::Hub::normalize( [0,10,255], 'RGB' );

It has one required and two optional arguments. The first is an ARRAY ref
with the vector or values of a color. The seond argument is name of a color
space. This is in most cases necessary, since all color space know their
standard value ranges (being e.g. 3 x 0 .. 255 for RGB). If you want to
normalize from special ranges like RGB16 you have use the third argument,
which has to be a valid value range definition.

    my @rgb = Graphics::Toolkit::Color::Space::Hub::normalize( [0, 1000, 34000], 'RGB', 2**16 );
    # which is the same as:
    my @rgb = Graphics::Toolkit::Color::Space::Hub::normalize( [0, 1000, 34000], 'RGB', [[0,65536].[0,65536].[0,65536]] );

=head2 denormalize

Reverse function of I<normalize>, taking the same arguments.
If result has to be an integer (range maximum above 1), it will be rounded.

    my @rgb = Graphics::Toolkit::Color::Space::Hub::denormalize( [0,0.1,1], 'RGB' );
    my @rgb = Graphics::Toolkit::Color::Space::Hub::denormalize( [0,0.1,1], 'RGB', 2**16 );


=head2 convert

Converts a value vector (first argument) from base space (RGB) into any
space mentioned space (second argument - see L</COLOR-SPACES>).
The values have to be normalized (inside 0..1). If there are outside
the acceptable range, there will be clamped, so that the result will
also normal.

    # convert from RGB to  HSL
    my @hsl = Graphics::Toolkit::Color::Space::Hub::convert( [0.1, 0.5, .7], 'HSL' );

=head2 deconvert

Converts a value tuple (vector - firs argument) of any color space
(second argument) into the base space (RGB).

    # convert from HSL to RGB
    my @rgb = Graphics::Toolkit::Color::Space::Hub::deconvert( [0.9, 0.5, 0.5], 'HSL' );

=head2 format

Putting a list of values (inside an ARRAY ref - first argument) from any
supported color space (second argument) into another data format
(third argument, see I</FORMATS>).


    my $hex = Graphics::Toolkit::Color::Space::Hub::format( [255, 0, 10], 'hex' );       # 'ff00a0'
    my $string = Graphics::Toolkit::Color::Space::Hub::format( [255, 0, 10], 'string' ); # 'RGB: 255, 0, 10'

=head2 deformat

Reverse function of I<format>, but also guesses the color space. That's
why it takes only one argument, a scalar that can be a string, ARRAY ref
or HASH ref. The result will be two values. The first is a ARRAY with
all the unaltered, not clamped and not normalized values. The second
is the name of the recognized color name space.

    my ($values, $space) =  Graphics::Toolkit::Color::Space::Hub::deformat( 'ff00a0' );
    # [255, 10 , 0], 'RGB'
    ($values, $space) =  Graphics::Toolkit::Color::Space::Hub::deformat( [255, 10 , 0] ); # same result


=head2 partial_hash_deformat

This is a special case I<deformat> routine for the I<hash> and I<char_hash>
format (see I</FORMATS>). It can tolerate missing values. The
The result will also be a hash


=head1 SEE ALSO

=over 4

=item *

L<Convert::Color>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
