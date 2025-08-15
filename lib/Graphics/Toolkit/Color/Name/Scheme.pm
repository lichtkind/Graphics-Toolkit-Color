
# name space for color names, translate values > names & back, find closest name

package Graphics::Toolkit::Color::Name::Scheme;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space_name();


sub new {
    my $pkg = shift;
    bless { $RGB->name => {name => [], values => {}} }
}

sub add_color {
    my ($self, $name, $values) = @_;

}
sub all_names { keys %{$_[0]->{$RGB->name}{'values'}} }
sub is_name_taken {
    my ($self, $name, $values) = @_;
}
sub values_from_name {
    my ($self, $name, $space_name) = @_;
}
sub name_from_values {
    my ($self, $values, $space_name) = @_;

}
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

1;

1;
