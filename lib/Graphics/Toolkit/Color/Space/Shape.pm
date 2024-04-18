use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::Space::Shape;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util qw/pround is_nr/;

sub new {
    my $pkg = shift;
    my ($basis, $type, $range, $precision) = @_;
    return unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    if (not defined $type){ $type = [ (1) x $basis->count ] } # default is all linear space
    elsif (ref $type eq 'ARRAY' and @$type == $basis->count ) {
        for my $i ($basis->iterator) {
            my $dtype = $type->[$i]; # type def of this dimension
            return unless defined $dtype;
            if    ($dtype eq 'angular' or $dtype eq 'circular' or $dtype eq '0') { $type->[$i] = 0 }
            elsif ($dtype eq 'linear'                          or $dtype eq '1') { $type->[$i] = 1 }
            elsif ($dtype eq 'no'                              or $dtype eq '2') { $type->[$i] = 2 }
            else  { return 'invalid axis type at element '.$i.'. It has to be "angular", "linear" or "no".' }
        }
    } else        { return 'invalid axis type definition in color space '.$basis->name }

    # check range settings
    if    (not defined $range or $range eq 'normal') { $range = [([0,1]) x $basis->count] }       # default range
    elsif (                     $range eq 'percent') { $range = [([0,100]) x $basis->count] }
    elsif (not ref $range and $range > 0 )           { $range = [([0, $range]) x $basis->count] } # single int range def
    elsif (ref $range eq 'ARRAY' and @$range == $basis->count ) {                                 # check elements of range def
        for my $i ($basis->iterator) {
            my $drange = $range->[$i]; # range def of this dimension

            if (not ref $drange and $drange and $drange eq 'normal') { $range->[$i] = [0,  1] }
            elsif                            ( $drange eq 'percent') { $range->[$i] = [0,100] }
            elsif (not ref $drange and $drange > 0)                  { $range->[$i] = [0, $drange] }
            elsif (ref $drange eq 'ARRAY') {
                return 'range definition element number '.$i.' has to have two elements' unless @$drange == 2;
                return 'none numeric range definition at lower bound of element number '.$i unless is_nr( $drange->[0] );
                return 'none numeric range definition at upper bound of element number '.$i unless is_nr( $drange->[1] );
                return 'lower bound is greater or equal than upper bound at element number '.$i if $drange->[0] >= $drange->[1];
            } else { return 'invalid range definition at ARRAY element number '.$i }
        }
    } else { return 'invalid range definition in color space '.$basis->name }

    $precision = [(-2) x $basis->count] unless defined $precision;
    $precision = [($precision) x $basis->count] unless ref $precision;
    return 'need an ARRAY as definition of axis value precision' unless ref $precision eq 'ARRAY';
    return 'definition of axis value precision has to have same lengths as basis' unless @$precision == $basis->count;
    for my $i ($basis->iterator) {
        $precision->[$i] = 0 if $precision->[$i] == -2 and $range->[$i][0] == int($range->[$i][0])
                                                       and $range->[$i][1] == int($range->[$i][1])
                                                       and ($range->[$i][0] != 0 or $range->[$i][1] != 1);
    }

    bless { basis => $basis, type => $type, range => $range, precision => $precision }
}

sub basis           { $_[0]{'basis'}}
sub axis_is_numeric {
    my ($self, $dnr) = @_;
    return 0 if not defined $dnr or not exists $self->{'type'}[$dnr];
    $self->{'type'}[$dnr] == 2 ? 0 : 1;

}
sub axis_value_precision { # --> +precision?
    my ($self, $dnr, $precision) = @_;
    return undef if not defined $dnr or not exists $self->{'type'}[$dnr];
    return undef unless $self->axis_is_numeric($dnr);
    $precision //= $self->{'precision'};
    return undef unless ref $precision eq 'ARRAY' and exists $precision->[$dnr];
    $precision->[$dnr];
}
sub _range { # check if range def is valid and eval (exapand) it
    my ($self, $external_range) = @_;
    return $self->{'range'} unless defined $external_range;

    $external_range = Graphics::Toolkit::Color::Space::Shape->new( $self->{'basis'},  $self->{'type'}, $external_range,);
    return (ref $external_range) ? $external_range->{'range'} : undef ;
}

sub _precision { # check if precision def is valid and eval (exapand) it
    my ($self, $external_precision, $external_range) = @_;
    return $self->{'precision'} unless defined $external_precision;
    my $range = $self->_range($external_range);
    return $range unless ref $range;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $self->{'basis'}, $self->{'type'}, $range, $external_precision);
    return (ref $shape) ? $shape->{'precision'} : undef;
}

########################################################################

sub delta { # values have to be normalized
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_array( $values1 ) and $self->basis->is_array( $values2 );
    # ignore none numeric dimensions
    my @delta = map { $self->axis_is_numeric($_) ? ($values2->[$_] - $values1->[$_]) : 0 } $self->basis->iterator;
    [ map { $self->{'type'}[$_] ? $delta[$_]     :                                      # adapt to circular dimensions
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->iterator ];
}

sub in_range {  # $vals -- $range, $precision --> $@vals | ~!
    my ($self, $values, $range, $precision) = @_;
    return 'color value vector in '.$self->basis->name.' needs '.$self->basis->count.' values'
        unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return "got bad range definition" unless ref $range;
    $precision = $self->_precision( $precision );
    return "bad precision definition, need ARRAY with ints or -1" unless ref $precision;
    my @names = $self->basis->keys;
    for my $i ($self->basis->iterator){
        next unless $self->axis_is_numeric($i);
        return $names[$i]." value is below minimum of ".$range->[$i][0] if $values->[$i] < $range->[$i][0];
        return $names[$i]." value is above maximum of ".$range->[$i][1] if $values->[$i] > $range->[$i][1];
        return $names[$i]." value is not properly rounded " if $precision->[$i] >= 0
                                                           and pround($values->[$i], $precision->[$i]) != $values->[$i];
    }
    return $values;
}

sub clamp {
    my ($self, $values, $range, $precision) = @_;
    $range = $self->_range( $range );
    return "bad range definition, need upper limit, 2 element ARRAY or ARRAY of 2 element ARRAYs" unless ref $range;
    $precision = $self->_precision( $precision, $range );
    return "bad precision definition, need ARRAY with ints or -1" unless ref $precision;
    $values = [] unless ref $values eq 'ARRAY';
    push @$values, 0 while @$values < $self->basis->count;
    pop  @$values    while @$values > $self->basis->count;
    for my $i ($self->basis->iterator){
        next unless $self->axis_is_numeric($i);
        my $delta = $range->[$i][1] - $range->[$i][0];
        if ($self->{'type'}[$i]){
            $values->[$i] = $range->[$i][0] if $values->[$i] < $range->[$i][0];
            $values->[$i] = $range->[$i][1] if $values->[$i] > $range->[$i][1];
        } else {
            $values->[$i] += $delta while $values->[$i] < $range->[$i][0];
            $values->[$i] -= $delta while $values->[$i] > $range->[$i][1];
            $values->[$i] = $range->[$i][0] if $values->[$i] == $range->[$i][1];
        }
        $values->[$i] = pround($values->[$i], $precision->[$i]) if $precision->[$i] >= 0;
    }
    return $values;
}

########################################################################

sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->axis_is_numeric( $_ )) ? (($values->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]))
                                           : $values->[$_]    } $self->basis->iterator ];
}

sub denormalize {
    my ($self, $values, $range, $precision) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;
    my @val = map { ($self->axis_is_numeric( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0])
                                                   : $values->[$_]   } $self->basis->iterator;
    return \@val;
}

sub denormalize_delta {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->axis_is_numeric( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0])) : $values->[$_]} $self->basis->iterator ];
}

sub round {
    my ($self, $values, $precision) = @_;
    return unless $self->basis->is_array( $values );
    $precision = $self->_precision( $precision );
    return "bad precision definition" unless ref $precision;
    [ map { ($self->axis_is_numeric( $_ ) and $precision->[$_] >= 0) ? pround ($values->[$_], $precision->[$_]) : $values->[$_] } $self->basis->iterator ];
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space::Shape - color space helper for value vectors

=head1 SYNOPSIS

Color spaces are objects( instances ) of this class, who provide property
details via the constructor and formatter and converters via CODE ref.

    use Graphics::Toolkit::Color::Space;

    my  $def = Graphics::Toolkit::Color::Space::Shape->new( $basis, $type, $range, $precision);

    $def->add_converter('RGB', \&to_rgb, \&from_rgb );
    $def->add_formatter(   'name',   sub {...} );
    $def->add_deformatter( 'name',   sub {...} );


=head1 DESCRIPTION

This package provides the API for color space authors.
The module is supposed to be used by L<Graphics::Toolkit::Color::Space::Hub>
and L<Graphics::Toolkit::Color::Values> and not directly, thus it exports
no symbols and has a much less DWIM API then the main module.

=head1 METHODS

=head2 new

The constructor takes five named arguments. Only I<axis>, which takes
an ARRAY ref with the names of the axis, is required. The first letter
of each axis name becomes the name shortcut for each axis, unless
separate shortcut names are provided under the named argument I<short>.
The name of a color space is derived from the combined axis shortcuts.
If that would lead to an already taken name, you can provide an additional
I<prefix>, which will pasted in front of the space name.

Under the argument I<range> you can set the limits of each dimension.
If none are provided, normal ranges (0 .. 1) are assumed. One number
is understood as the upper limit of all dimensions and the lower bound
being zero. An ARRAY ref with two number set the lower and upper bound of
each dimension, but you can also provide an ARRAY ref filled with numbers
or ARRAY ref defining the bounds for each dimension. If no argument under
the name L<type> is provided, then all dimensions will be I<linear> (Euclidean).
But you might want to change that for some to I<circular> or I<angular>
which both means that this dimension is not measured in length but
with an angle from the origin.

=head2 delta

Takes three arguments:

1. A name of a space the values will be converter from and to
(usually just 'RGB').

2. & 3. Two CODE refs of the actual converter methods, which have to take
the normalized values as a list and return normalized values as a list.
The first CODE converts to the named (by first argument) space and
the second from the named into the name space the objects implements.

=head2 in_range



=head2 clamp

=head2 normalize

=head2 denormalize

=head2 denormalize_delta

=head1 COPYRIGHT & LICENSE

Copyright 2023-24 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
