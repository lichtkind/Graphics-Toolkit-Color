
# geometry of space: value range checks, normalisation and computing distance

package Graphics::Toolkit::Color::Space::Shape;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util qw/round_decimals is_nr/;

sub new {
    my $pkg = shift;
    my ($basis, $type, $range, $precision) = @_;
    return unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    if (not defined $type){ $type = [ (1) x $basis->axis_count ] } # set all axis as linear per default
    elsif (ref $type eq 'ARRAY' and @$type == $basis->axis_count ) {
        for my $i ($basis->axis_iterator) {
            my $atype = $type->[$i];                              # type def of this axis
            return unless defined $atype;
            if    ($atype eq 'angular' or $atype eq 'circular' or $atype eq '0') { $type->[$i] = 0 }
            elsif ($atype eq 'linear'                          or $atype eq '1') { $type->[$i] = 1 }
            elsif ($atype eq 'no'                              or $atype eq '2') { $type->[$i] = 2 }
            else  { return 'invalid axis type at element '.$i.'. It has to be "angular", "linear" or "no".' }
        }
    } else        { return 'invalid axis type definition in color space '.$basis->space_name }

    # check range settings
    if    (not defined $range or $range eq 'normal') { $range = [([0,1]) x $basis->axis_count] }       # default range
    elsif (                     $range eq 'percent') { $range = [([0,100]) x $basis->axis_count] }
    elsif (not ref $range and $range > 0 )           { $range = [([0, $range]) x $basis->axis_count] } # single int range def
    elsif (ref $range eq 'ARRAY' and @$range == $basis->axis_count ) {                                 # check elements of range def
        for my $i ($basis->axis_iterator) {
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
    } else { return 'invalid range definition in color space '.$basis->space_name }

    $precision = [(-2) x $basis->axis_count] unless defined $precision;
    $precision = [($precision) x $basis->axis_count] unless ref $precision;
    return 'need an ARRAY as definition of axis value precision' unless ref $precision eq 'ARRAY';
    return 'definition of axis value precision has to have same lengths as basis' unless @$precision == $basis->axis_count;
    for my $i ($basis->axis_iterator) {
        $precision->[$i] = 0 if $precision->[$i] == -2 and $range->[$i][0] == int($range->[$i][0])
                                                       and $range->[$i][1] == int($range->[$i][1])
                                                       and ($range->[$i][0] != 0 or $range->[$i][1] != 1);
    }
    bless { basis => $basis, type => $type, range => $range, precision => $precision }
}

#### getter (defaults) #################################################

sub basis           { $_[0]{'basis'}}
sub is_axis_nr {
    my ($self, $axis_nr) = @_;
    return 0 if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    $self->{'type'}[$axis_nr] == 2 ? 0 : 1;

}
sub axis_value_precision { # --> +precision?
    my ($self, $axis_nr, $precision) = @_;
    return undef if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    return undef unless $self->is_axis_nr($axis_nr);
    $precision //= $self->{'precision'};
    return undef unless ref $precision eq 'ARRAY' and exists $precision->[$axis_nr];
    $precision->[$axis_nr];
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

#### value adaptation methods ##########################################

sub in_range {  # $vals -- $range, $precision --> $@vals | ~!
    my ($self, $values, $range, $precision) = @_;
    return 'color value tuple in '.$self->basis->space_name.' space needs to be ARRAY ref with '.$self->basis->axis_count.' elements'
        unless $self->basis->is_value_tuple( $values );
    $range = $self->_range( $range );
    return "got bad range definition" unless ref $range;
    $precision = $self->_precision( $precision );
    return "bad precision definition, need ARRAY with ints or -1" unless ref $precision;
    my @names = $self->basis->long_axis_names;
    for my $i ($self->basis->axis_iterator){
        next unless $self->is_axis_nr($i);
        return $names[$i]." value is below minimum of ".$range->[$i][0] if $values->[$i] < $range->[$i][0];
        return $names[$i]." value is above maximum of ".$range->[$i][1] if $values->[$i] > $range->[$i][1];
        return $names[$i]." value is not properly rounded " if $precision->[$i] >= 0
                                                           and round_decimals($values->[$i], $precision->[$i]) != $values->[$i];
    }
    return $values;
}

sub clamp { # change value if its outside of range
    my ($self, $values, $range, $precision) = @_;
    $range = $self->_range( $range );
    return "bad range definition, need upper limit, 2 element ARRAY or ARRAY of 2 element ARRAYs" unless ref $range;
    $precision = $self->_precision( $precision, $range );
    return "bad precision definition, need ARRAY with ints or -1" unless ref $precision;
    $values = [] unless ref $values eq 'ARRAY';
    push @$values, 0 while @$values < $self->basis->axis_count;
    pop  @$values    while @$values > $self->basis->axis_count;
    for my $i ($self->basis->axis_iterator){
        next unless $self->is_axis_nr($i);
        my $delta = $range->[$i][1] - $range->[$i][0];
        if ($self->{'type'}[$i]){
            $values->[$i] = $range->[$i][0] if $values->[$i] < $range->[$i][0];
            $values->[$i] = $range->[$i][1] if $values->[$i] > $range->[$i][1];
        } else {
            $values->[$i] += $delta while $values->[$i] < $range->[$i][0];
            $values->[$i] -= $delta while $values->[$i] > $range->[$i][1];
            $values->[$i] = $range->[$i][0] if $values->[$i] == $range->[$i][1];
        }
        $values->[$i] = round_decimals($values->[$i], $precision->[$i]) if $precision->[$i] >= 0;
    }
    return $values;
}

sub round {
    my ($self, $values, $precision) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $precision = $self->_precision( $precision );
    return "bad precision definition" unless ref $precision;
    [ map { ($self->is_axis_nr( $_ ) and $precision->[$_] >= 0) ? round_decimals ($values->[$_], $precision->[$_]) : $values->[$_] } $self->basis->axis_iterator ];
}

#### computation methods ###############################################

sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->is_axis_nr( $_ )) ? (($values->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]))
                                           : $values->[$_]    } $self->basis->axis_iterator ];
}

sub denormalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;

    return [ map { ($self->is_axis_nr( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0])
                                                   : $values->[$_]   } $self->basis->axis_iterator ];
}

sub denormalize_delta {
    my ($self, $delta_values, $range) = @_;
    return unless $self->basis->is_value_tuple( $delta_values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->is_axis_nr( $_ ))
             ? ($delta_values->[$_] * ($range->[$_][1]-$range->[$_][0]))
             :  $delta_values->[$_]                                       } $self->basis->axis_iterator ];
}

sub delta { # values have to be normalized
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_value_tuple( $values1 ) and $self->basis->is_value_tuple( $values2 );
    # ignore none numeric dimensions
    my @delta = map { $self->is_axis_nr($_) ? ($values2->[$_] - $values1->[$_]) : 0 } $self->basis->axis_iterator;
    [ map { $self->{'type'}[$_] ? $delta[$_]   :                                      # adapt to circular dimensions
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->axis_iterator ];
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space::Shape - color space helper for value vectors

=head1 SYNOPSIS

This is for internal usage only, see L<Graphics::Toolkit::Color::Space>.

    use Graphics::Toolkit::Color::Space::Shape;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, $type, $range, $precision);
    $shape->delta( $values1, $values2 );
    $shape->in_range( $values, $range, $precision );
    $shape->clamp( $values, $range, $precision );
    $shape->normalize( $values, $range );
    $shape->denormalize( $values, $range, $precision );
    $shape->round( $values, $precision );

=head1 DESCRIPTION

This package provides a core class that encapsulates the most basic
color value handling functions in a color space. The arguments I<$range>
and I<$precision> are optional and default to the values set while
construction of the color space (inside the
Graphics::Toolkit::Color::Space::Instance::* packages).

=head1 METHODS

=head2 new

The constructor takes 4 positional arguments.

    I<$basis> is an L<Graphics::Toolkit::Color::Space::Basis> object.
    We need mostly needed to know the right size of a color value vector.

    I<$type> are the axis types of this space: I<circular>, I<linear> or
    I<no> (not arithmetic) as set by the values 0, 1 and 2.

    default I<$range> of this space.

    default I<$precision> of this space.

=head2 in_range

Check if a color value vector (first arg) is inside a given range
(optional second arg) having the needed precision (optional third arg).
Vector ARRAY ref if yes and error message if no.

=head2 clamp

Clamp a color value vector (first arg) into the given range
(optional second arg) and with given precision (optional third arg).
Does this for every numeric axis.

=head2 normalize

Compute color value vector (first arg) into normal range of 0 .. 1 if axis
is numeric.

=head2 denormalize

Reverse of I<normalize>, optional second arg is the range.

=head2 denormalize_delta

I<denormalize> for results of I<delta>.

=head2 delta

Difference between two normalized color value vectors. Its zero when exis
is none arithmetic and is more than simple difference in circular dimensions.

=head1 COPYRIGHT & LICENSE

Copyright 2023-25 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
