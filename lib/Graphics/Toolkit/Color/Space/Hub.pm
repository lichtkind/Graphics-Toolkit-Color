
# check, convert and measure color values # hcg eq hsb ?

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;
use Carp;
our $base_package = 'RGB';
my @space_packages = ($base_package, qw/CMY CMYK HSL HSV HSB HWB NCol YIQ XYZ LAB LUV LCHab LCHuv/); # search order ## missing: Ncol
my %space_obj     =  map { $_ => require "Graphics/Toolkit/Color/Space/Instance/$_.pm" } @space_packages; # outer names
my %space_lookup = map { $_->name => $_ } values %space_obj;                                         # full color space names
my @space_names = map { $space_obj{$_}->name } @space_packages;                                      # names in search oder

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

Graphics::Toolkit::Color::Space::Hub - convert, format and (de-)normalize color values

=head1 SYNOPSIS

Central hub for all color value related math. Can handle vectors of all
spaces mentioned in next paragraph and translates also into and from
different formats such as I<RGB> I<hex> ('#AABBCC').

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

    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( '#0000ff' );
    # [0, 0, 255] , 'RGB'

=head1 DESCRIPTION

This module is supposed to be used by L<Graphics::Toolkit::Color> and not
directly, thus it exports no symbols and has a much less DWIM API then
the main module.


=head1 COLOR SPACES

Color space names can be written in any combination of upper and lower case.

=head2 RGB

has three integer values: B<red> (short I<r>) range: 0 .. 255, B<green>
(short I<g>) range: 0 .. 255 and B<blue> (short I<b>) range: 0 .. 255.
All are scaling from no (0) to very much (255) light of that color,
so that (0,0,0) is black, (255,255,255) is white and (0,0,255) is blue.

=head2 CMY

is the inverse of RGB but with the real value range: 0 .. 1.
B<cyan> (short I<c>) is the inverse value of I<red>,
B<magenta> (short I<m> ) is inverse to I<green> and
B<yellow> (short I<y>) is inverse of I<blue>.
Inverse meaning when a color has the maximal I<red> value, it has to
have the minimal I<cyan> value.

=head2 CMYK

is an extension of CMY with a fourth value named B<key> (short I<k>) (also 0 .. 1),
which is basically the amount of black mixed into the CMY color.

=head2 HSL

has three integer values: B<hue> (0 .. 359), B<saturation> (0 .. 100)
and B<lightness> (0 .. 100). Hue (short I<h>) stands for a color on
a rainbow: 0 = red, 15 approximates orange, 60 - yellow 120 - green,
180 - cyan, 240 - blue, 270 - violet, 300 - magenta, 330 - pink.
0 and 360 points to the same coordinate. This module only outputs 0,
even if accepting 360 as input.
I<saturation> (short I<s>) ranges from 0 (White/gray/black) to 100 (clearest color set by hue).
I<lightness> (short I<l>) ranges from 0 (black) over 50 (hue or gray) to 100 (white).

=head2 HSV

Similar to HSL we have B<hue> and B<saturation>, but the third value in
named B<value>. In HSL we always get  white, when I<lightness> is 100.
In HSV additionally I<saturation> has to be zero to get white.
When I<saturation> is 100 and I<value> is 100 we have the brightest,
clearest color of whatever I<hue> sets.

=head2 HSB

It is an alias to HSV, just value being renamed with B<brightness>.

=head2 HWB

An inverted HSV, where the saturated, clean colors are on the center
column of the cylinder. It still has the circular B<hue> dimension,
as described in C<HSL>. The other two, linear dimensions (also 0 .. 100)
are B<whiteness> and B<blackness>, desribing how much white or black are
mixed in. If both are zero, than we have a pure color. I<whiteness> of 100
always leads to white and I<blackness> of 100 always leads to black.

=head2 NCol

Is a human readable derivation of the HWB space with altered B<hue> axis
that consicts of a letter and nwo digits. The letter demarks one of the
six areas around the rainbow B<R> (I<Red>), B<Y> (I<Yellow>), B<G> (I<Green),
B<C> (I<Cyan>), B<B> (I<Blue>), B<M> (I<Magenta). The two digits after this
letter are a percentual value, pointing to a position on the rainbow,
between the stated color by the letter and the next. The B<whiteness> and
B<blackness> axis have values with the suffix I<%>, since they are
percentual values as well.

=head2 YIQ

Has three linear dimensions:
B<luminance> (short I<y>) (sort of brightness with real range of 0 .. 1),
B<in-phase> (short I<i>) (cyan - orange - balance, range -0.5959 .. 0.5959) and
B<quadrature> (short I<q>) (magenta - green - balance, range: -0.5227 .. 0.5227).

=head2 CIEXYZ
Has three real valued dimension named X, Y and Z, (short names are the same),
which aim to reflect the chemical activity of the three type of
colored light receptors in the human eye. Their ranges span from zero to
0.95047, 1 and 1.08883.

=head2 CIELAB

Has three linear real valued dimension named L*, a* and b*, (short names have only
the first letter). Their ranges are 0 .. 100, -500 .. 500 and -200 .. 200.

=head2 CIELUV

Has three linear real valued dimension named L*, u* and v*, (short names have only
the first letter). Their ranges are 0 .. 100, -500 .. 500 and -200 .. 200.

=head2 CIELCHab

Has three linear real valued dimension named B<luminance>, B<croma> and B<hue>.
Their ranges are 0 .. 100, -500 .. 500 and -200 .. 200.

=head2 CIELCHuv

Has three linear real valued dimension named B<luminance>, B<croma> and B<hue>.
Their ranges are 0 .. 100, -500 .. 500 and -200 .. 200.


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
