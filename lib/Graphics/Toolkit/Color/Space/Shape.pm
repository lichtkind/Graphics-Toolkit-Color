use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::Space::Shape;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Util qw/pround is_nr/;

sub new {
    my $pkg = shift;
    my ($basis, $type, $range, $precision, $suffix) = @_;
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

    $suffix = [('') x $basis->count] unless defined $suffix;
    $suffix = [($suffix) x $basis->count] unless ref $suffix;
    return 'need an ARRAY as definition of axis value suffix' unless ref $suffix eq 'ARRAY';
    return 'definition of axis value suffix has to have same lengths as basis' unless @$suffix == $basis->count;

    bless { basis => $basis, type => $type, range => $range, precision => $precision , suffix => $suffix }
}

sub basis           { $_[0]{'basis'}}
sub axis_is_numeric {
    my ($self, $dnr) = @_;
    return 0 if not defined $dnr or not exists $self->{'type'}[$dnr];
    $self->{'type'}[$dnr] == 2 ? 0 : 1;

}
sub axis_value_precision {
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
    $precision = $self->_precision( $precision );
    return "bad precision definition" unless ref $precision;
    my @val = map { ($self->axis_is_numeric( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0]) + $range->[$_][0])
                                                   : $values->[$_]   } $self->basis->iterator;
    @val    = map { ($self->axis_is_numeric( $_ ) and 
                    $precision->[$_] >= 0)          ? pround ($val[$_], $precision->[$_]) : $val[$_] } $self->basis->iterator;
    return \@val;
}

sub denormalize_delta {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    $range = $self->_range( $range );
    return "bad range definition" unless ref $range;
    [ map { ($self->axis_is_numeric( $_ )) ? ($values->[$_] * ($range->[$_][1]-$range->[$_][0])) : $values->[$_]} $self->basis->iterator ];
}

1;
