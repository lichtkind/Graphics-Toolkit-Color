
# name space for color names, translate values > names & back, find closest name

package Graphics::Toolkit::Color::Name::Scheme;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space_name();

#### constructor #######################################################
sub new {
    my $pkg = shift;
    bless { shaped => {name => [], values => {}}, normal => {} }
}
sub add_color {
    my ($self, $name, $values) = @_;
    return if not defined $name or not defined $values or $self->is_name_taken($name);
    $self->{'shaped'}{'values'}{$name} = $values;
    $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]] =
        (exists $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]])
       ? [@{$self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]]}, $name]
       : [$name];
    # update normal
}

#### exact getter ######################################################
sub all_names { keys %{$_[0]->{'shaped'}{'values'}} }
sub is_name_taken {
    my ($self, $name) = @_;
    (exists $self->{'shaped'}{'values'}{$name}) ? 1 : 0;
}
sub values_from_name {
    my ($self, $name) = @_;
    return $self->{'shaped'}{'values'}{$name} if exists $self->{'shaped'}{'values'}{$name};
}
sub names_from_values {
    my ($self, $values) = @_;
    return unless ref $values eq 'ARRAY' and @$values == 3;
    return unless exists $self->{'shaped'}{'name'}[$values->[0]];
    return unless exists $self->{'shaped'}{'name'}[$values->[0]][$values->[1]];
    return unless exists $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]];
    return $self->{'shaped'}{'name'}[$values->[0]][$values->[1]][$values->[2]];
}

#### nearness methods ##################################################
sub closest_name {
    my ($self, $values, $space_name) = @_;
}
sub names_in_range {
    my ($self, $values, $range, $space_name) = @_;
}

1;
__END__

my $constants = require Graphics::Toolkit::Color::Name::Constant; # store
our (@name_from_rgb, @name_from_hsl);       # search caches
_add_color_to_reverse_search( $_, @{$constants->{$_}} ) for all(); # (all color names)

sub is_taken { (exists  $constants->{ _clean_name($_[0]) }) ? 1 : 0 }
sub rgb_from_name {
    my $name = _clean_name(shift);
    return [@{$constants->{$name}}[0..2]] if is_taken( $name );
}
sub hsl_from_name {
    my $name = _clean_name(shift);
    return [@{$constants->{$name}}[3..5]] if is_taken( $name );
}

########################################################################
sub all_names { sort keys %$constants }
sub name_from_rgb {
    my ($rgb) = @_;
    return '' unless ref $RGB->check_value_shape( $rgb );
    return '' unless exists $name_from_rgb[ $rgb->[0] ] and exists $name_from_rgb[ $rgb->[0] ][ $rgb->[1] ]
                 and exists $name_from_rgb[ $rgb->[0] ][ $rgb->[1] ][ $rgb->[2] ];
    my @names = ($name_from_rgb[ $rgb->[0] ][ $rgb->[1] ][ $rgb->[2] ]);
    @names = @{$names[0]} if ref $names[0];
    return wantarray ? @names : $names[0];
}
sub name_from_hsl {
    my ($hsl) = @_;
    return unless ref $HSL->check_value_shape( $hsl );
    return '' unless exists $name_from_hsl[ $hsl->[0] ] and exists $name_from_hsl[ $hsl->[0] ][ $hsl->[1] ]
                 and exists $name_from_hsl[ $hsl->[0] ][ $hsl->[1] ][ $hsl->[2] ];
    my @names = ($name_from_hsl[ $hsl->[0] ][ $hsl->[1] ][ $hsl->[2] ]);
    @names = @{$names[0]} if ref $names[0];
    return wantarray ? @names : $names[0];
}

sub names_in_rgb_range { # @center, (@d | $d) --> @names
    return if @_ != 2;
    my ($rgb_center, $radius) = @_;
    return unless ref $RGB->check_value_shape( $rgb_center ) and defined $radius;
    return unless (ref $radius eq 'ARRAY' and @$radius == 3) or not ref $radius;
    my %distance;
    my $border = (ref $radius) ? $radius : [$radius, $radius, $radius];
    my @min = map {$rgb_center->[$_] - $border->[$_]} 0 .. 2;
    my @max = map {$rgb_center->[$_] + $border->[$_]} 0 .. 2;
    for my $name (all()){
        my @rgb = @{$constants->{$name}}[0..2];
        next if $rgb[0] < $min[0]  or $rgb[0] > $max[0];
        my @delta = map { ($rgb[$_] - $rgb_center->[$_]) ** 2 } 0 .. 2;
        my $d = sqrt( $delta[0] + $delta[1] + $delta[2] );
        $distance{ $name } = $d if ref $radius or $d <= $radius;
    }
    my @names = sort { $distance{$a} <=> $distance{$b} || $a cmp $b } keys %distance;
    my @d = map {$distance{$_}} @names;
    return \@names, \@d;
}
sub names_in_hsl_range { # @center, (@d | $d) --> @names
    return if @_ != 2;
    my ($hsl_center, $radius) = @_;
    return unless ref $HSL->check_value_shape( $hsl_center ) and defined $radius;
    return unless (ref $radius eq 'ARRAY' and @$radius == 3) or not ref $radius;
    my %distance;
    my $border = (ref $radius) ? $radius : [$radius, $radius, $radius];
    my @min = map {$hsl_center->[$_] - $border->[$_]} 0 .. 2;
    my @max = map {$hsl_center->[$_] + $border->[$_]} 0 .. 2;
    my $ignore_hue_filter = $border->[0] >= 180;
    my $flip_hue_boundaries = ($min[0] < 0 or $max[0] > 360);
    $min[0] += 360 if $min[0] < 0;
    $max[0] -= 360 if $max[0] > 360;
    for my $name (all()){
        my @hsl = @{$constants->{$name}}[3..5];
        unless ($ignore_hue_filter){
            if ($flip_hue_boundaries) { next if $hsl[0] > $min[0] and $hsl[0] < $max[0] }
            else                      { next if $hsl[0] < $min[0]  or $hsl[0] > $max[0] }
        }
        next if $hsl[1] < $min[1] or $hsl[1] > $max[1];
        next if $hsl[2] < $min[2] or $hsl[2] > $max[2];
        my $h_delta = abs ($hsl[0] - $hsl_center->[0]);
        $h_delta = 360 - $h_delta if $h_delta > 180;
        my $d = sqrt( $h_delta**2 + ($hsl[1]-$hsl_center->[1])**2 + ($hsl[2]-$hsl_center->[2])**2 );
        $distance{ $name } = $d if ref $radius or $d <= $radius;
    }
    my @names = sort { $distance{$a} <=> $distance{$b} || $a cmp $b } keys %distance;
    my @d = map {$distance{$_}} @names;
    return \@names, \@d;
}

##### extend store #####################################################
sub add_rgb {
    my ($name, $rgb) = @_;
    return 'need a color name that is not already taken as first argument' unless defined $name and not is_taken( $name );
    return "second argument: RGB tuple is malformed or values are  out of range" unless ref $RGB->check_value_shape( $rgb );
    my $hsl = $HSL->denormalize( $HSL->convert_from( 'RGB', $RGB->normalize( $rgb ) ) );
    _add_color( $name, $RGB->round( $rgb ), $HSL->round( $hsl ) );
}
sub add_hsl {
    my ($name, $hsl) = @_;
    return 'need a color name that is not already taken as first argument' unless defined $name and not is_taken( $name );
    return "second argument: HSL tuple is malformed or values are  out of range" unless ref $HSL->check_value_shape( $hsl );
    my $rgb = $RGB->denormalize( $HSL->convert_to( 'RGB', $HSL->normalize( $hsl ) ) );
    _add_color( $name, $RGB->round( $rgb ), $HSL->round( $hsl ) );
}
sub _add_color {
    my ($name, $rgb, $hsl) = @_;
    $name = _clean_name( $name );
    return "there is already a color named '$name' in store of ".__PACKAGE__ if is_taken( $name );
    _add_color_to_reverse_search( $name, @$rgb, @$hsl);
    my $ret = $constants->{$name} = [@$rgb, @$hsl];    # add to foreward search
    return 0;
}

########################################################################
sub _clean_name {
    my $name = shift;
    $name =~ tr/_'//d;
    lc $name;
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

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Name::Scheme - a name space for color names

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Name::Scheme;
    my $scheme = Graphics::Toolkit::Color::Name::Scheme_>new();
    $scheme->add_color( $_->{name}, $_->{rgb_values} ) for @colors;
    say for $scheme->all_names();
    my $values = $scheme->values_from_name( 'blue' );          # tuple = 3 element ARRAY
    my $names = $scheme->names_from_values( $values );         # tuple -> ARRAY of names
    my ($names, $distance) = $scheme->closest_name( $values ); # tuple -> \@names, $distance
    my $names = $scheme->names_in_range( $values, $distance ); #       -> ARRAY of names


=head1 DESCRIPTION

This module is mainly for internal usage to model name spaces for HTML,
SVG, Pantone ... colors. Use it to create your own set color names or
to give names slightly different values.


=head1 ROUTINES

=head2 new

Needs no arguments.

=head2 sub add_color

takes two positional arguments, a color name a n ARRAY with three
RGB values in range of 0 .. 255.


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

Copyright 2025 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>
