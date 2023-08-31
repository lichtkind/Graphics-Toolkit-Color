use v5.12;
use warnings;

# value objects with space cache

package Graphics::Toolkit::Color::Value;
use Carp;

sub new {
    my ($pkg, $color_val) = @_;

    bless {rgb => []};
}

sub get {
    my ($self, $space, $format, $range) = @_;
}

sub set {
    my ($self, $val_hash) = @_;
}

sub add {
    my ($self, $val_hash) = @_;
}

sub blend {
    my ($self, $c2, $factor, $space ) = @_;
}

sub distance {
    my ($self, $c2, $space, $subspace, $range) = @_;
    my $self = shift;
}


1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value - single color related numerical methods

=head1 SYNOPSIS

Central hub for all color value related math. Can handle vectors of all
spaces mentioned in next paragraph and translates also into and from
different formats such as I<RGB> I<hex> ('#AABBCC').

    use Graphics::Toolkit::Color::Value;

    my @hsl = G.::T.::C.::Value::convert( [20, 50, 70], 'HSL' );    # convert from RGB to HSL
    my @rgb = G.::T.::C.::Value::deconvert( [220, 50, 70], 'HSL' ); # convert from HSL to RGB


=head1 DESCRIPTION

This module is supposed to be used by L<Graphics::Toolkit::Color> and not
directly, thus it exports no symbols and has a much less DWIM API then
the main module.



=head1 METHODS

=head2 deconvert

Converts a value tuple (vector) of any space above into the base space (RGB).
Takes two arguments the vector (array of numbers) and name of the source space.
The result is also a vector in for of a list. The result values will
clamped (changed into acceptable range) to be valid inside the target
color space.


    my @rgb = G.::T.::C.::Value::deconvert( [220, 50, 70], 'HSL' ); # convert from HSL to RGB

=head2 convert

Converts a value vector from base space (RGB) into any space above.
Takes two arguments the vector (array of numbers) and name of the target space.
The result is also a vector in for of a list. The result values will
clamped (changed) to be valid inside the target color space.

    my @hsl = G.::T.::C.::Value::convert( [20, 50, 70], 'HSL' );    # convert from RGB to HSL

=head2 deformat

Transfers values from many formats into a vector (array of numbers - first
return value). The second return value is the name of a color space which
supported this format. All spaces support the following format names:
I<hash>, I<char_hash> and the names and shortcuts of the vector names.
Additonal formats are implemented by the Graphics::Toolkit::Color::Value::*
modules. The values themself will not be changed, even if they are outside
the boundaries of the color space.

    # get [170, 187, 204], 'RGB'
    my ($rgb, $space) = G.::T.::C.::Value::deformat( '#aabbcc' );
    # get [12, 34, 54], 'HSL'
    my ($hsl, $s) = G.::T.::C.::Value::deformat( { h => 12, s => 34, l => 54 } );


=head2 format

Reverse function of I<deformat>.

    # get { h => 12, s => 34, l => 54 }
    my $h = G.::T.::C.::Value::format( [12, 34, 54], 'HSL', 'char_hash' );
    # get { hue => 12, saturation => 34, lightness => 54 }
    my $h = G.::T.::C.::Value::format( [12, 34, 54], 'HSL', 'hash' );
    # '#AABBCC'
    my $str = G.::T.::C.::Value::format( [170, 187, 204], 'RGB', 'hex' );


=head2 distance

Computes a real number which designates the distance between two points
in any color space above. The first two arguments are the two point vectors.
Third (optional) argument is the name of the color space, which defaults
to the base space (RGB).

    my $d = distance([1,1,1], [2,2,2], 'RGB');  # approx 1.7
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
