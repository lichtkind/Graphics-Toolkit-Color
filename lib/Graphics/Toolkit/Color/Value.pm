use v5.12;
use warnings;

# check, convert and measure color values

package Graphics::Toolkit::Color::Value;
use Carp;
my $base_package = 'RGB';
my @space_packages = qw/RGB HSL HSV CMYK CMY/; # LAB HCL
my %space_def = map { $_ => require "Graphics/Toolkit/Color/Value/$_.pm" } @space_packages;

sub space { $space_def{ uc $_[0] } if exists $space_def{ uc $_[0] } }

sub deformat { # convert from any format / space into list of values in base space
    my ($formated_values) = @_;
    for my $space_name (@space_packages) {
        my $color_space = space( $space_name );
        my @val = $color_space->deformat( $formated_values );
        next unless defined $val[0];
        @val = $color_space->convert( \@val, $base_package) unless ($space_name eq $base_package);
        @val = Graphics::Toolkit::Color::Value::RGB::trim( @val ); # hardcoded base
        return \@val, $space_name;
    }
}

sub convert { # @RGB --> @...
    my ($values, $space_name) = @_;
    return carp "got not enough values to format"  unless $space_def{ $base_package }->is_array( $values );
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
                . join ', ', map {lc} @space_packages unless ref $space;
    return carp "got not array with right amount of values to format" unless $space->is_array( $values );
    @format = ('list') unless @format;
    my @values = map { $space->format( $values, $_ ) } @format;
    return @values == 1 ? $values[0] : @values;
}

sub distance {
    my ($values1, $values2, $space_name, $metric) = @_;
    $space_name //= $base_package;
    my $space = space( $space_name );
    return carp "called 'distance' with unknown color space name: $space_name!" unless ref $space;
    my @delta = $space->delta( $values1, $values2 );
    return carp "called 'distance' with bad input values!" unless @delta == $space->dimensions;
    if (defined $metric and $metric){
        my @components = split( '', $metric );
        @components = map { $space->basis->shortcut_pos($_) }
                      grep {defined $space->basis->shortcut_pos($_) } @components;
        return carp "called 'distance' with metric $metric that does not fit color space $space_name!" unless @components;
        @delta = map { $delta [$_] } @components;
    }
    @delta = map {$_ * $_ } @delta;
    my $d = 0;
    for (@delta) {$d += $_}
    return sqrt $d;
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


=head1 COLOR SPACES


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
