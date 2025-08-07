
# geometry of space: value range checks, normalisation and computing distance

package Graphics::Toolkit::Color::Space::Shape;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util qw/round_decimals is_nr/;

#### constructor #######################################################

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

    # check and complete range definition into most explicit form
    my $error_msg = 'Bad value range definition!';
    $range =   1 if not defined $range or $range eq 'normal';
    $range = 100 if                       $range eq 'percent';
    return $error_msg." It has to be 'normal', 'percent', a number or ARRAY of numbers or ARRAY of ARRAY's with two number!"
        unless (not ref $range and is_nr( $range )) or (ref $range eq 'ARRAY') ;
    $range = [$range] unless ref $range;
    $range = [(@$range) x $basis->axis_count] if @$range == 1;
    return "Range definition needs inside an ARRAY either one definition for all axis or one definition".
           " for each axis!"                  if @$range != $basis->axis_count;
    for my $axis_index ($basis->axis_iterator) {
        my $axis_range = $range->[$axis_index];
        if (not ref $axis_range){
            if    ($axis_range eq 'normal')  {$range->[$axis_index] = [0, 1]}
            elsif ($axis_range eq 'percent') {$range->[$axis_index] = [0, 100]}
            else                             {$range->[$axis_index] = [0, $axis_range+0]}
        } elsif (ref $axis_range eq 'ARRAY') {
            return $error_msg.' Array at axis number '.$axis_index.' has to have two elements' unless @$axis_range == 2;
            return $error_msg.' None numeric value at lower bound for axis number '.$axis_index unless is_nr( $axis_range->[0] );
            return $error_msg.' None numeric value at upper bound for axis number '.$axis_index unless is_nr( $axis_range->[1] );
            return $error_msg.' Lower bound (first value) is >= than upper bound at axis number '.$axis_index if $axis_range->[0] >= $axis_range->[1];
        } else { return "Range definitin for axis $axis_index was not an two element ARRAY!" }
    }

    $precision = -1 unless defined $precision;
    $precision = [($precision) x $basis->axis_count] unless ref $precision;
    return 'need an ARRAY as definition of axis value precision' unless ref $precision eq 'ARRAY';
    return 'definition of axis value precision has to have same lengths as basis' unless @$precision == $basis->axis_count;
    bless { basis => $basis, type => $type, range => $range, precision => $precision, constraint => {} }
}

sub add_constraint {
    my ($self, $name, $error_msg, $checker, $remedy) = @_;
    return unless defined $name and not exists $self->{'constraint'}{$name}
              and defined $error_msg and not ref $error_msg and length($error_msg) > 10
              and ref $checker eq 'CODE' and ref $remedy eq 'CODE';
    $self->{'constraint'}{$name} = {checker => $checker, remedy => $remedy, error => $error_msg};
}
#### getter (defaults) #################################################

sub basis           { $_[0]{'basis'}}
sub is_axis_numeric {
    my ($self, $axis_nr) = @_;
    return 0 if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    $self->{'type'}[$axis_nr] == 2 ? 0 : 1;

}
sub axis_value_precision { # --> +precision?
    my ($self, $axis_nr, $precision) = @_;
    return undef if not defined $axis_nr or not exists $self->{'type'}[$axis_nr];
    return undef unless $self->is_axis_numeric($axis_nr);
    $precision //= $self->{'precision'};
    return undef unless ref $precision eq 'ARRAY' and exists $precision->[$axis_nr];
    $precision->[$axis_nr];
}

sub check_range_definition { # check if range def is valid and eval (exapand) it
    my ($self, $external_range) = @_;
    return $self->{'range'} unless defined $external_range;
    $external_range = Graphics::Toolkit::Color::Space::Shape->new( $self->{'basis'},  $self->{'type'}, $external_range,);
    return (ref $external_range) ? $external_range->{'range'} : undef ;
}

sub check_precision_definition { # check if precision def is valid and eval (exapand) it
    my ($self, $external_precision, $external_range) = @_;
    return $self->{'precision'} unless defined $external_precision;
    my $range = $self->check_range_definition($external_range);
    return $range unless ref $range;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $self->{'basis'}, $self->{'type'}, $range, $external_precision);
    return (ref $shape) ? $shape->{'precision'} : undef;
}

#### value adaptation methods ##########################################

sub check_range {  # $vals -- $range, $precision --> $@vals | ~!
    my ($self, $values, $range, $precision) = @_;
    return 'color value tuple in '.$self->basis->space_name.' space needs to be ARRAY ref with '.$self->basis->axis_count.' elements'
        unless $self->basis->is_value_tuple( $values );
    $range = $self->check_range_definition( $range );
    return "got bad range definition" unless ref $range;
    $precision = $self->check_precision_definition( $precision );
    return "bad precision definition, need ARRAY with ints or -1" unless ref $precision;
    my @names = $self->basis->long_axis_names;
    for my $i ($self->basis->axis_iterator){
        next unless $self->is_axis_numeric($i);
        return $names[$i]." value is below minimum of ".$range->[$i][0] if $values->[$i] < $range->[$i][0];
        return $names[$i]." value is above maximum of ".$range->[$i][1] if $values->[$i] > $range->[$i][1];
        return $names[$i]." value is not properly rounded " if $precision->[$i] >= 0
                                                           and round_decimals($values->[$i], $precision->[$i]) != $values->[$i];
    }
    for my $constraint (values %{$self->{'constraint'}}){
        return $constraint->{'error'} unless $constraint->{'checker'}->( $values );
    }
    return $values;
}

sub clamp { # change values if outside of range, angles get rotated in std range
    my ($self, $values, $range) = @_;
    $range = $self->check_range_definition( $range );
    return "bad range definition, need upper limit, 2 element ARRAY or ARRAY of 2 element ARRAYs" unless ref $range;
    $values = [] unless ref $values eq 'ARRAY';
    push @$values, 0 while @$values < $self->basis->axis_count;
    pop  @$values    while @$values > $self->basis->axis_count;
    for my $axis_nr ($self->basis->axis_iterator){
        next unless $self->is_axis_numeric( $axis_nr );
        my $delta = $range->[$axis_nr][1] - $range->[$axis_nr][0];
        if ($self->{'type'}[$axis_nr]){
            $values->[$axis_nr] = $range->[$axis_nr][0] if $values->[$axis_nr] < $range->[$axis_nr][0];
            $values->[$axis_nr] = $range->[$axis_nr][1] if $values->[$axis_nr] > $range->[$axis_nr][1];
        } else {
            $values->[$axis_nr] += $delta while $values->[$axis_nr] < $range->[$axis_nr][0];
            $values->[$axis_nr] -= $delta while $values->[$axis_nr] > $range->[$axis_nr][1];
            $values->[$axis_nr] = $range->[$axis_nr][0] if $values->[$axis_nr] == $range->[$axis_nr][1];
        }
#        $values->[$axis_nr] = round_decimals($values->[$axis_nr], $precision->[$axis_nr]) if $precision->[$axis_nr] >= 0;
    }
    for my $constraint (values %{$self->{'constraint'}}){
        $values = $constraint->{'remedy'}->( $values ) unless $constraint->{'checker'}->( $values );
    }
    return $values;
}

sub round {
    my ($self, $values, $precision) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $precision = $self->check_precision_definition( $precision );
    return "round got bad precision definition" unless ref $precision;
    [ map { ($self->is_axis_numeric( $_ ) and $precision->[$_] >= 0) ? round_decimals ($values->[$_], $precision->[$_]) : $values->[$_] } $self->basis->axis_iterator ];
}

#### computation methods ###############################################

sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $range = $self->check_range_definition( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->is_axis_numeric( $_ )) ? (($values->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]))
                                           : $values->[$_]    } $self->basis->axis_iterator ];
}

sub denormalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $range = $self->check_range_definition( $range );
    return "bad range definition" unless ref $range;

    return [ map { ($self->is_axis_numeric( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0])
                                                   : $values->[$_]   } $self->basis->axis_iterator ];
}

sub denormalize_delta {
    my ($self, $delta_values, $range) = @_;
    return unless $self->basis->is_value_tuple( $delta_values );
    $range = $self->check_range_definition( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->is_axis_numeric( $_ ))
             ? ($delta_values->[$_] * ($range->[$_][1]-$range->[$_][0]))
             :  $delta_values->[$_]                                       } $self->basis->axis_iterator ];
}

sub delta { # values have to be normalized
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_value_tuple( $values1 ) and $self->basis->is_value_tuple( $values2 );
    # ignore none numeric dimensions
    my @delta = map { $self->is_axis_numeric($_) ? ($values2->[$_] - $values1->[$_]) : 0 } $self->basis->axis_iterator;
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
