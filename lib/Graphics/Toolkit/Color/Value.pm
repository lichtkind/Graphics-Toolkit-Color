use v5.12;
use warnings;

# check, convert and measure color values

package Graphics::Toolkit::Color::Value;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Value::RGB  ':all';
use Graphics::Toolkit::Color::Value::HSL  ':all';
use Graphics::Toolkit::Color::Value::HSV  ':all';
use Graphics::Toolkit::Color::Value::CMYK ':all';

use Carp;
use Exporter 'import';
our @EXPORT_OK = (@Graphics::Toolkit::Color::Value::RGB::EXPORT_OK,
                  @Graphics::Toolkit::Color::Value::HSL::EXPORT_OK,
                  @Graphics::Toolkit::Color::Value::CMYK::EXPORT_OK,
);
our %EXPORT_TAGS = (all => [@EXPORT_OK],
                    rgb => \@Graphics::Toolkit::Color::Value::RGB::EXPORT_OK,
                    hsl => \@Graphics::Toolkit::Color::Value::HSL::EXPORT_OK,
                   cmyk => \@Graphics::Toolkit::Color::Value::CMYK::EXPORT_OK,
);



sub exists_space {

}

sub get_object {

}


1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value - check, convert and measure color values

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Value;         # import nothing
    use Graphics::Toolkit::Color::Value ':all';  # import all routines
    use Graphics::Toolkit::Color::Value ':rgb';  # import RGB related routines
    use Graphics::Toolkit::Color::Value ':hsl';  # import HSL related routines

    check_rgb( 256, 10, 12 ); # throws error 255 is the limit
    my @hsl = hsl_from_rgb( 20, 50, 70 ); # convert from RGB to HSL space


=head1 DESCRIPTION

A set of helper routines to handle RGB and HSL values: bound checks,
conversion, measurement. Most subs expect three numerical values,
or sometimes two triplet. This module is supposed to be used by
Graphics::Toolkit::Color and not directly.


=head1 ROUTINES

=head2 check_rgb

Carp error message if RGB value triplet is not valid (or out of value range).

=head2 check_hsl

Carp error message if HSL value triplet is not valid (or out of value range).

=head2 trim_rgb

Change RGB triplet to the nearest valid values.

=head2 trim_hsl

Change HSL triplet to the nearest valid values.

=head2 hsl_from_rgb

Converting an rgb value triplet into the corresponding hsl

Red, Green and Blue are integer in 0 .. 255.
Hue is an integer between 0 .. 359 (hue)
and saturation and lightness are 0 .. 100 (percentage).
A hue of 360 and 0 (degree in a cylindrical coordinate system) is
considered to be the same, this modul deals only with the ladder.

=head2 rgb_from_hsl

Converting an hsl value triplet into the corresponding rgb
(see rgb_from_name and hsl_from_name). Please not that back and forth
conversion can lead to drifting results due to rounding.

    my @rgb = rgb_from_hsl( 0, 90, 50 );
    my @rgb = rgb_from_hsl( [0, 90, 50] ); # works too
    # for real (none integer results), any none zero value works as second arg
    my @rgb = rgb_from_hsl( [0, 90, 50], 'real');

=head2 hex_from_rgb

Converts a red green blue triplet into format: '#rrggbb'
(lower case hex digits).

=head2 rgb_from_hex

Converts '#rrggbb' or '#rgb' (CSS short format) hex values into regular
RGB triple of 0..255 integer.

=head2 distance_rgb

Distance (real) in (linear) rgb color space between two coordinates.


    my $d = distance_rgb([1,1,1], [2,2,2]);  # approx 1.7


=head2 distance_hsl

Distance (real) in (cylindrical) hsl color space between two coordinates.

    my $d = distance_rgb([1,1,1], [356, 3, 2]); # approx 6


=head1 SEE ALSO

=over 4

=item *

L<Color::Library>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2022-23 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
