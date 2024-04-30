use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::Space::Format;

sub new {
    my ($pkg, $basis, $suffix, $value_format ) = @_;
    return 'first argument has to be an Color::Space::Basis reference'
        unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    $suffix = make_suffix( $basis, $suffix ) ;
    return $suffix unless ref $suffix;

    my $number_format = '-?(?:\d+|\d+\.\d+|.\d+)';
    my $count = $basis->count;
    $value_format = [($number_format) x $count] unless defined $value_format;
    $value_format = [($value_format) x $count] unless ref $suffix;
    $value_format = [ map {(defined $_ and $_) ? $_ : $number_format } @$value_format]; # fill missing defs with default
    return 'need an ARRAY as definition of value format' unless ref $value_format eq 'ARRAY';
    return 'definition value format has to have same lengths as basis' unless @$value_format == $count;

    # format --> tuple
    my %deformats = ( hash => sub { tuple_from_hash(@_)         },
               named_array => sub { tuple_from_named_array(@_)  },
              named_string => sub { tuple_from_named_string(@_) },
                css_string => sub { tuple_from_css_string(@_)   },
    );
    # tuple --> format
    my %formats = (list => sub { @{$_[1]} },                              #   1, 2, 3
                   hash => sub { $basis->long_hash_from_tuple($_[1]) },   # { red => 1, green => 2, blue => 3 }
              char_hash => sub { $basis->short_hash_from_tuple($_[1]) },  # { r =>1, g => 2, b => 3 }
            named_array => sub { [$basis->space_name, @{$_[1]}] },        # ['rgb',1,2,3]
           named_string => sub { $_[0]->named_string_from_tuple($_[1]) }, #  'rgb: 1, 2, 3'
             css_string => sub { $_[0]->css_string_from_tuple($_[1]) },   #  'rgb(1,2,3)'
    );
    bless { basis => $basis, suffix => $suffix, value_format => $value_format ,
            format => \%formats, deformat => \%deformats, }
}

sub make_suffix {
    my ($basis, $suffix) = @_;
    my $count = $basis->count;
    $suffix = [('') x $count] unless defined $suffix;
    $suffix = [($suffix) x $count] unless ref $suffix;
    return 'need an ARRAY as definition of axis value suffix' unless ref $suffix eq 'ARRAY';
    return 'definition of axis value suffix has to have same lengths as basis' unless @$suffix == $count;
    return $suffix;
}

sub _suffix {
    my ($self, $suffix) = @_;
    return $self->{'suffix'} unless defined $suffix;
    make_suffix( $self->{'basis'}, $suffix );
}
sub _value_regex {
    my ($self, $match) = @_;
    (defined $match and $match)
        ? (map {'\s*('.$self->{'value_format'}[$_].'\s*(?:'.quotemeta($self->{'suffix'}[$_]).')?)\s*' } $self->basis->iterator)
        : (map {'\s*'.$self->{'value_format'}[$_].'\s*(?:'.quotemeta($self->{'suffix'}[$_]).')?\s*' } $self->basis->iterator);
}
#### public API: formatting value tuples ###############################

sub basis            { $_[0]{'basis'}}
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub has_deformat     { (defined $_[1] and exists $_[0]{'deformat'}{ lc $_[1] }) ? 1 : 0 }
sub add_formatter {
    my ($self, $format, $code) = @_;
    return if not defined $format or ref $format or ref $code ne 'CODE';
    return if $self->has_format( $format );
    $self->{'format'}{ $format } = $code;
}
sub add_deformatter {
    my ($self, $format, $code) = @_;
    return if not defined $format or ref $format or exists $self->{'deformat'}{$format} or ref $code ne 'CODE';
    $self->{'deformat'}{ lc $format } = $code;
}

sub format {
    my ($self, $values, $format, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $suffix = $self->_suffix( $suffix );
    return $suffix unless ref $suffix;
    $values = $self->add_suffix( $values, $suffix );
    $self->{'format'}{ lc $format }->($self, $values) if $self->has_format( $format );
}

sub deformat {
    my ($self, $color, $suffix) = @_;
    return undef unless defined $color;
    $suffix = $self->_suffix( $suffix );
    return $suffix unless ref $suffix;
    for my $name (keys %{$self->{'deformat'}}){
        my $deformatter = $self->{'deformat'}{$name};
        my $values = $deformatter->( $self, $color );
        next unless $self->basis->is_value_tuple( $values );
        $values = $self->remove_suffix($values, $suffix);
        return wantarray ? ($values, $name) : $values;
    }
    return undef;
}

#### helper ############################################################

sub add_suffix {
    my ($self, $values, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $suffix = $self->_suffix( $suffix );
    return $suffix unless ref $suffix;
    [ map { ($suffix->[$_] and substr( $values->[$_], - length $suffix->[$_]) ne $suffix->[$_])
                  ? $values->[$_] . $suffix->[$_] : $values->[$_]                              } $self->basis->iterator ];
}
sub remove_suffix { # and unnecessary white space
    my ($self, $values, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $suffix = $self->_suffix( $suffix );
    return $suffix unless ref $suffix;
    local $/ = ' ';
    chomp $values->[$_] for $self->basis->iterator;
    [ map { eval $_ }
      map { ($self->{'suffix'}[$_] and substr( $values->[$_], - length($self->{'suffix'}[$_])) eq $self->{'suffix'}[$_])
          ? (substr( $values->[$_], 0, length($values->[$_]) - length($self->{'suffix'}[$_])))
          : $values->[$_]                                                                     } $self->basis->iterator ];
}

sub match_number_values {
    my ($self, $values) = @_;
    my @re = $self->_value_regex();
    for my $i ($self->basis->iterator){
        return 0 unless $values->[$i] =~ /^$re[$i]$/;
    }
    return $values;
}

#### converter: format --> values ######################################

sub tuple_from_named_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    my $name = $self->basis->space_name;
    $string =~ /^\s*$name:\s*(\s*[^:]+\s*)\s*$/i;
    return 0 unless $1;
    $self->match_number_values( [split(',',$1)] );
}


sub tuple_from_css_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    my $name = $self->basis->space_name;
    $string =~ /^\s*$name\s*\(\s*([^)]+)\s*\)\s*$/i;
    return 0 unless $1;
    $self->match_number_values( [split(',',$1)] );
}

sub tuple_from_named_array {
    my ($self, $array) = @_;
    return 0 unless ref $array eq 'ARRAY' and @$array == $self->basis->count+1;
    return 0 unless uc $array->[0] eq uc $self->basis->space_name;
    shift @$array;
    $self->match_number_values( $array );
}

sub tuple_from_hash        {
    my ($self, $hash) = @_;
    return 0 unless $self->basis->is_hash($hash);
    my $values = $self->basis->tuple_from_hash( $hash );
    $self->match_number_values( $values );
}

#### converter: values --> format ######################################

sub named_array_from_tuple {
    my ($self, $values) = @_;
    return [$self->basis->space_name, @$values] unless $self->basis->is_value_tuple( $values );
}
sub named_string_from_tuple {
    my ($self, $values) = @_;
    return lc( $self->basis->space_name).': '.join(', ', @$values);
}
sub css_string_from_tuple {
    my ($self, $values) = @_;
    return  lc( $self->basis->space_name).'('.join(', ', @$values).')';
}

1;
