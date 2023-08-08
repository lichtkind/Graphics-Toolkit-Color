use v5.12;
use warnings;

# check, convert and measure color values

package Graphics::Toolkit::Color::Value;
use Carp;
my $base_package = 'RGB';
my @space_packages = qw/RGB HSL HSV CMYK CMY/; # LAB HCL HWB
my %space_obj = map { $_ => require "Graphics/Toolkit/Color/Value/$_.pm" } @space_packages;

sub space { $space_obj{ uc $_[0] } if exists $space_obj{ uc $_[0] } }
sub base_space { $space_obj{$base_package} }
sub space_names { @space_packages }

sub deformat { # convert from any format and space into list of values in base space
    my ($formated_values) = @_;
    for my $space_name (space_names()) {
        my $color_space = space( $space_name );
        my @val = $color_space->deformat( $formated_values );
        return \@val, $space_name if defined $val[0];
    }
}

sub deconvert { # @... --> @RGB
    my ($values, $space_name) = @_;
    return carp "got not enough values to format"  unless base_space()->is_array( $values );
    return @$values if not defined $space_name or uc($space_name) eq $base_package;
    my $space = space( $space_name );
    return carp "required unknown color space '$space_name', please try one of: "
                . join ', ', map {lc} @space_packages unless ref $space;
    $space->convert( $values, $base_package);
}

sub convert { # @RGB --> @...
    my ($values, $space_name) = @_;
    return carp "got not enough values to format"  unless space( $base_package )->is_array( $values );
    return @$values if not defined $space_name or uc($space_name) eq $base_package;
    my $space = space( $space_name );
    return carp "required unknown color space '$space_name', please try one of: "
                . join ', ', map {lc} @space_packages unless ref $space;
    $space->deconvert( $values, $base_package);
}

sub format { # @tuple --> % | % |~ ...
    my ($values, $space_name, @format) = @_;
    my $space = space( $space_name // $base_package );
    return carp "required unknown color space '$space_name', please try one of: "
                . join ', ', map {lc} space_names() unless ref $space;
    unless ($space->is_array( $values )) {
        carp "need array with right amount of values to format";
        return ();
    }
    @format = ('list') unless @format;
    my @values = map { $space->format( $values, $_ ) } @format;
    return @values == 1 ? $values[0] : @values;
}

sub distance { # @vector x @vector -- ~color_space_name, ~subspace   --> +d
    my ($values1, $values2, $space_name, $subspace) = @_;
    $space_name //= $base_package;
    my $space = space( $space_name );
    return - carp "called 'distance' with unknown color space name: $space_name!" unless ref $space;
    my @delta = $space->delta( $values1, $values2 );
    return - carp "called 'distance' with bad input values!" unless @delta == $space->dimensions;
    if (defined $subspace and $subspace){
        my @components = split( '', $subspace );
        my $pos = $space->basis->key_pos( $subspace );
        @components = defined( $pos )
                    ? ($pos)
                    : (map  { $space->basis->shortcut_pos($_) }
                       grep { defined $space->basis->shortcut_pos($_) } @components);
        return - carp "called 'distance' for subspace $subspace that does not fit color space $space_name!" unless @components;
        @delta = map { $delta [$_] } @components;
    }
    # Euclidean distance:
    @delta = map {$_ * $_} @delta;
    my $d = 0;
    for (@delta) {$d += $_}
    return sqrt $d;
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value - convert, format and measure color values

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Value;


    my @hsl = G.::T.::C.::Value::convert( [20, 50, 70], 'HSL' );    # convert from RGB to HSL
    my @rgb = G.::T.::C.::Value::deconvert( [220, 50, 70], 'HSL' ); # convert from HSL to RGB


=head1 DESCRIPTION

Central hub for all color value related math. Can handle vectors of all
spaces mentioned in next paragraph and translates also into and from
different formats such as I<RGB> I<hex> ('#AABBCC'). This module is
supposed to be used by L<Graphics::Toolkit::Color> and not directly.


=head1 COLOR SPACES

Color space names can be written in any combination of upper and lower case.

=head2 RGB

has three integer values: I<red> (0 .. 255), I<green> (0 .. 255) and I<blue> (0 .. 255).
All are scaling from no (0) to very much (255) light of that color,
so that (0,0,0) is black, (255,255,255) is white and (0,0,255) is blue.

=head2 CMY

is the inverse of RGB but with the range: 0 .. 1. I<cyan> is the inverse
value of I<red>, I<magenta> is inverse green and I<yellow> is inverse of
I<blue>. Inverse meaning when a color has the maximal I<red> value,
it has to have the minimal I<cyan> value.

=head2 CMYK

is an extension of CMY with a fourth value named I<key> (also 0 .. 1),
which is basically the amount of black mixed into the CMY color.

=head2 HSL

has three integer values: I<hue> (0 .. 359), I<saturation> (0 .. 100)
and I<lightness> (0 .. 100). Hue stands for a color on a rainbow: 0 = red,
15 approximates orange, 60 - yellow 120 - green, 180 - cyan, 240 - blue,
270 - violet, 300 - magenta, 330 - pink. 0 and 360 point to the same
coordinate. This module only outputs 0, even if accepting 360 as input.
I<saturation> ranges from 0 = gray to 100 - clearest color set by hue.
I<lightness> ranges from 0 = black to 50 (hue or gray) to 100 = white.

=head2 HSV

Similar to HSL with the difference that the third value in named I<value>
and in HSL the color white is always achieved when I<lightness> = 100.
In HSV additionally I<saturation> has to be zero.
When in HSV I<lightness> is 100 and I<saturation> is also 100, than we
have the brightest clearest color of whatever I<hue> sets.

=head1 ROUTINES

=head2 deconvert

=head2 convert

=head2 deformat

=head2 format

=head2 distance


Distance (real) in (linear) rgb color space between two coordinates.


    my $d = distance([1,1,1], [2,2,2], 'RGB');  # approx 1.7


=head2 distance_hsl

Distance (real) in (cylindrical) hsl color space between two coordinates.

    my $d = distance([1,1,1], [356, 3, 2], 'HSL'); # approx 6


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
