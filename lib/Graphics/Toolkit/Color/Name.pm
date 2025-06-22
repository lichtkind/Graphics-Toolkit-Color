
# named colors from X11, HTML (SVG) standard and Pantone report

package Graphics::Toolkit::Color::Name;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

my $constants = require Graphics::Toolkit::Color::Name::Constant;
our (@name_from_rgb, @name_from_hsl);       # search caches
_add_color_to_reverse_search( $_, @{$constants->{$_}} ) for all();

sub all      { sort keys %$constants }
sub is_taken { exists  $constants->{ _clean_name($_[0]) } }

sub rgb_from_name {
    my $name = _clean_name(shift);
    @{$constants->{$name}}[0..2] if taken( $name );
}

sub hsl_from_name {
    my $name = _clean_name(shift);
    @{$constants->{$name}}[3..5] if taken( $name );
}

sub name_from_rgb {
    my (@rgb) = @_;
    @rgb  = @{$rgb[0]} if (ref $rgb[0] eq 'ARRAY');
    my $vals = $RGB->range_check( [@rgb] );
    return unless ref $vals;
    my $names = _names_from_rgb( @rgb );
    return unless ref $names;
    wantarray ? @$names : $names->[0];
}

sub name_from_hsl {
    my (@hsl) = @_;
    @hsl  = @{$hsl[0]} if (ref $hsl[0] eq 'ARRAY');
    my $vals = $HSL->range_check( [ @hsl ] );
    return unless ref $vals;
    my $names = _names_from_hsl( @hsl );
    return unless ref $names;
    wantarray ? @$names : $names->[0];
}

sub names_in_hsl_range { # @center, (@d | $d) --> @names
    my $help = 'need two arguments: 1. array with h s l values '.
               '2. radius (real number) or array with tolerances in h s l direction';
    return $help if @_ != 2;
    my ($hsl_center, $radius) = @_;
    $HSL->range_check( $hsl_center ) and return;
    my $hsl_delta = (ref $radius eq 'ARRAY') ? $radius : [$radius, $radius, $radius];
    $HSL->range_check( $hsl_delta ) and return;

    $hsl_delta->[0] = 180 if $hsl_delta->[0] > 180;        # enough to search complete HSL space (prevent double results)
    my (@min, @max, @names, $minhrange, $maxhrange);
    $min[$_] = $hsl_center->[$_] - $hsl_delta->[$_]  for 0..2;
    $max[$_] = $hsl_center->[$_] + $hsl_delta->[$_]  for 0..2;
    $min[1] =   0 if $min[1] <   0;
    $min[2] =   0 if $min[2] <   0;
    $max[1] = 100 if $max[1] > 100;
    $max[2] = 100 if $max[2] > 100;
    my @hrange = ($min[0] <   0) ? ( 0 .. $max[0]    , $min[0]+360 .. 359)
               : ($max[0] > 360) ? ( 0 .. $max[0]-360, $min[0]     .. 359)
                                 :                    ($min[0]     .. $max[0]);
    for my $h (@hrange){
        next unless defined $name_from_hsl[ $h ];
        for my $s ($min[1] .. $max[1]){
            next unless defined $name_from_hsl[ $h ][ $s ];
            for my $l ($min[2] .. $max[2]){
                my $name = $name_from_hsl[ $h ][ $s ][ $l ];
                next unless defined $name;
                push @names, (ref $name ? $name->[0] : $name);
             }
        }
    }
    @names = grep {Graphics::Toolkit::Color::Values->new(['HSL',@$hsl_center])->distance(
                   Graphics::Toolkit::Color::Values->new(['HSL',hsl_from_name($_)]), 'HSL' ) <= $radius} @names if not ref $radius;
    @names;
}

sub add_rgb {
    my ($name, @rgb) = @_;
    @rgb  = @{$rgb[0]} if (ref $rgb[0] eq 'ARRAY');
    return "missing first argument: color name" unless defined $name and $name;
    $RGB->range_check( [@rgb] ) and return;
    my @hsl = $HSL->deconvert( [$RGB->normalize( \@rgb )], 'RGB');
    _add_color( $name, @rgb, $HSL->denormalize(\@hsl) );
}

sub add_hsl {
    my ($name, @hsl) = @_;
    @hsl  = @{$hsl[0]} if (ref $hsl[0] eq 'ARRAY');
    return "missing first argument: color name" unless defined $name and $name;
    $HSL->range_check( \@hsl ) and return;
    my @rgb = $HSL->convert( [$HSL->normalize( \@hsl )], 'RGB');
    _add_color( $name, $RGB->denormalize( \@rgb ), @hsl );
}

sub _add_color {
    my ($name, @rgb, @hsl) = @_;
    $name = _clean_name( $name );
    return "there is already a color named '$name' in store of ".__PACKAGE__ if taken( $name );
    _add_color_to_reverse_search( $name, @rgb, @hsl);
    my $ret = $constants->{$name} = [@rgb, @hsl]; # add to foreward search
    (ref $ret) ? [@$ret] : '';                         # make returned ref not transparent
}

sub _clean_name {
    my $name = shift;
    $name =~ tr/_//d;
    lc $name;
}

sub _names_from_rgb { # each of AoAoA cells (if exists) contains name or array with names (shortes first)
    return '' unless exists $name_from_rgb[ $_[0] ]
              and exists $name_from_rgb[ $_[0] ][ $_[1] ] and exists $name_from_rgb[ $_[0] ][ $_[1] ][ $_[2] ];
    my $cell = $name_from_rgb[ $_[0] ][ $_[1] ][ $_[2] ];
    ref $cell ? @$cell : $cell;
}

sub _names_from_hsl {
    return '' unless exists $name_from_hsl[ $_[0] ]
              and exists $name_from_hsl[ $_[0] ][ $_[1] ] and exists $name_from_hsl[ $_[0] ][ $_[1] ][ $_[2] ];
    my $cell = $name_from_hsl[ $_[0] ][ $_[1] ][ $_[2] ];
    ref $cell ? @$cell : $cell;
}

sub _add_color_to_reverse_search { #     my ($name, @rgb, @hsl) = @_;
    my $name = $_[0];
    my $cell = $name_from_rgb[ $_[1] ][ $_[2] ][ $_[3] ];
    if (defined $cell) {
        if (ref $cell) {
            if (length $name < length $cell->[0] ) { unshift @$cell, $name }
            else                                   { push @$cell, $name    }
        } else {
            $name_from_rgb[ $_[1] ][ $_[2] ][ $_[3] ] =
                (length $name < length $cell) ? [ $name, $cell ]
                                              : [ $cell, $name ] ;
        }
    } else { $name_from_rgb[ $_[1] ][ $_[2] ][ $_[3] ] = $name  }

    $cell = $name_from_hsl[ $_[4] ][ $_[5] ][ $_[6] ];
    if (defined $cell) {
        if (ref $cell) {
            if (length $name < length $cell->[0] ) { unshift @$cell, $name }
            else                                   { push @$cell, $name    }
        } else {
            $name_from_hsl[ $_[4] ][ $_[5] ][ $_[6] ] =
                (length $name < length $cell) ? [ $name, $cell ]
                                              : [ $cell, $name ] ;
        }
    } else { $name_from_hsl[ $_[4] ][ $_[5] ][ $_[6] ] = $name  }
}

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

=head2 taken

A perlish pseudo boolean tells if the color name (first and only, required
argument) is already in use.

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
