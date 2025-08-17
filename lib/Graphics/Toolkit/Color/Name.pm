
# translate color names to values and vice versa

package Graphics::Toolkit::Color::Name;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name::Scheme;


my %color_scheme = (default => Graphics::Toolkit::Color::Name::Scheme->new());
my $default_names = require Graphics::Toolkit::Color::Name::Constant;
$color_scheme{'default'}->add_color( $_, [ @{$default_names->{$_}}[0,1,2] ] ) for keys %$default_names;
my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

########################################################################
sub get_values {
    my ($color_name, $scheme_name) = @_;
    my $scheme = try_get_scheme( $scheme_name );
    return $scheme unless ref $scheme;
    return $scheme->values_from_name( $color_name );
}

sub from_values {
    my ($values, $scheme_name, $get_all) = @_;
    my $scheme = try_get_scheme( $scheme_name );
    return '' unless ref $scheme;
    my $names = $scheme->names_from_values( $values );
    return '' unless ref $names;
    return (defined $get_all and $get_all) ? @$names : $names->[0];
}

sub closest {
    my ($values, $scheme_name, $get_all) = @_;
    my $scheme = try_get_scheme( $scheme_name );
    return '' unless ref $scheme;
    my $names = $scheme->closest_names_from_values( $values );
    return '' unless ref $names;
    return (defined $get_all and $get_all) ? @$names : $names->[0];
}

sub all {
    my ($scheme_name) = @_;
    my $scheme = try_get_scheme( $scheme_name );
    return '' unless ref $scheme;
    return $scheme->all_names;
}

########################################################################
sub try_get_scheme {
    my $scheme_name = shift // 'default';
    unless (exists $color_scheme{ $scheme_name }){
        my $module_base = 'Graphics::ColorNames';
        eval "use $module_base";
        return "$module_base is not installed, but it's needed to load external color schemes!" if $@;
        my $module = $module_base.'::'.$scheme_name;
        eval "use $module";
        return "Perl module $module is not installed, but needed to load color scheme '$scheme_name'" if $@;
        my $palette = eval "$module::NamesRgbTable();";
        return "Could not use Perl module $module , it seems to be damaged!" if $@;

        my $scheme = $color_scheme{ $scheme_name } = Graphics::Toolkit::Color::Name::Scheme->new();
        $scheme->add_color( $_, $RGB->deformat( $palette->{$_} ) ) for keys %$palette;
    }
    return $color_scheme{ $scheme_name };
}
########################################################################

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Name - access values of color constants

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Name qw/:all/;
    my @names = Graphics::Toolkit::Color::Name::all();
    my @rgb  = rgb_from_name('darkblue');
    my @hsl  = hsl_from_name('darkblue');

    Graphics::Toolkit::Color::Value::add_rgb('lucky', [0, 100, 50]);

=head1 DESCRIPTION

RGB and HSL values of named colors from the X11, HTML(CSS), SVG standard
and Pantone report. Allows also nearby search, reverse search and storage
(not permanent) of additional names. One color may have multiple names.
Own colors can be (none permanently) stored for later reference by name.
For this a name has to be chosen, that is not already taken. The
corresponding color may be defined by an RGB or HSL triplet.

No symbol is imported by default. The sub symbols: C<rgb_from_name>,
C<hsl_from_name>, C<name_from_rgb>, C<name_from_hsl> may be imported
individually or by:

    use Graphics::Toolkit::Color::Name qw/:all/;


=head1 ROUTINES

=head2 rgb_from_name

Red, Green and Blue value of the named color.
These values are integer in 0 .. 255.

    my @rgb = Graphics::Toolkit::Color::Name::rgb_from_name('darkblue');
    @rgb = Graphics::Toolkit::Color::Name::rgb_from_name('dark_blue'); # same result
    @rgb = Graphics::Toolkit::Color::Name::rgb_from_name('DarkBlue');  # still same

=head2 hsl_from_name

Hue, saturation and lightness of the named color.
These are integer between 0 .. 359 (hue) or 100 (sat. & light.).
A hue of 360 and 0 (degree in a cylindrical coordinate system) is
considered to be the same, this modul deals only with the ladder.

    my @hsl = Graphics::Toolkit::Color::Name::hsl_from_name('darkblue');

=head2 name_from_rgb

Returns name of color with given rgb value triplet.
Returns empty string if color is not stored. When several names define
given color, the shortest name will be selected in scalar context.
In array context all names are given.

    say Graphics::Toolkit::Color::Name::name_from_rgb( 15, 10, 121 );  # 'darkblue'
    say Graphics::Toolkit::Color::Name::name_from_rgb([15, 10, 121]);  # works too

=head2 name_from_hsl

Returns name of color with given hsl value triplet.
Returns empty string if color is not stored. When several names define
given color, the shortest name will be selected in scalar context.
In array context all names are given.

    say scalar Graphics::Toolkit::Color::Name::name_from_hsl( 0, 100, 50 );  # 'red'
    scalar Graphics::Toolkit::Color::Name::name_from_hsl([0, 100, 50]);  # works too
    say for Graphics::Toolkit::Color::Name::name_from_hsl( 0, 100, 50 ); # 'red', 'red1'

=head2  names_in_hsl_range

Color names in selected neighbourhood of hsl color space, that look similar.
It requires two arguments. The first one is an array containing three
values (hue, saturation and lightness), that define the center of the
neighbourhood (searched area).

The second argument can either be a number or again an array with
three values (h,s and l). If its just a number, it will be the radius r
of a ball, that defines the neighbourhood. From all colors inside that
ball, that are equal distanced or nearer to the center than r, one
name will returned.

If the second argument is an array, it has to contain the tolerance
(allowed distance) in h, s and l direction. Please note the h dimension
is circular: the distance from 355 to 0 is 5. The s and l dimensions are
linear, so that a center value of 90 and a tolerance of 15 will result
in a search of in the range 75 .. 100.

The results contains only one name per color (the shortest).

    # all bright red'ish clors
    my @names = Graphics::Toolkit::Color::Name::names_in_hsl_range([0, 90, 50], 5);
    # approximates to :
    my @names = Graphics::Toolkit::Color::Name::names_in_hsl_range([0, 90, 50],[ 3, 3, 3]);


=head2 all

A sorted list of all stored color names.

=head2 is_taken

Predicate method that return true if the color name (first and only,
required argument) is already in use.

=head2 add_rgb

Adding a color to the store under an not taken (not already used) name.
Arguments are name, red, green and blue value (integer < 256, see rgb).

    Graphics::Toolkit::Color::Name::add_rgb('nightblue',  15, 10, 121 );
    Graphics::Toolkit::Color::Name::add_rgb('nightblue', [15, 10, 121]);

=head2 add_hsl

Adding a color to the store under an not taken (not already used) name.
Arguments are name, hue, saturation and lightness value (see hsl).

    Graphics::Toolkit::Color::Name::add_rgb('lucky',  0, 100, 50 );
    Graphics::Toolkit::Color::Name::add_rgb('lucky', [0, 100, 50]);

=head1 SEE ALSO

L<Color::Library>

L<Graphics::ColorNamesLite::All>

=head1 COPYRIGHT & LICENSE

Copyright 2022-23 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
