
# bidirectional conversion of value tuples (ARRAY) into different string and other formats
# values themself can have space dependant extra shape, suffixes, etc.

package Graphics::Toolkit::Color::Space::Format;
use v5.12;
use warnings;

my $number_form = '-?(?:\d+|\d+\.\d+|\.\d+)';

#### constructor, building attr data ###################################
sub new { # -, $:Basis -- ~|@~val_form, , ~|@~suffix --> :_
    my ($pkg, $basis, $value_form, $prefix, $suffix) = @_;
    return 'First argument has to be an Color::Space::Basis reference !'
        unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    my $count = $basis->axis_count;
    $value_form = $number_form unless defined $value_form;
    $value_form = [($value_form) x $count] unless ref $value_form;
    return "Definition of the value format has to be as ARRAY reference" if ref $value_form ne 'ARRAY';
    $value_form = [ map {(defined $_ and $_) ? $_ : $number_form } @$value_form]; # fill missing defs with default
    return 'Need a value form definition for every axis!' unless @$value_form == $count;

    $suffix = expand_suffix_def( $basis, $suffix ) ;
    return $suffix unless ref $suffix;

    # format --> tuple
    my %deformats = ( hash => sub { tuple_from_hash(@_)         },
               named_array => sub { tuple_from_named_array(@_)  },
              named_string => sub { tuple_from_named_string(@_) },
                css_string => sub { tuple_from_css_string(@_)   },
    );
    # tuple --> format
    my %formats = (list => sub { @{$_[1]} },                                  #   1, 2, 3
                   hash => sub { $basis->long_name_hash_from_tuple($_[1]) },  # { red => 1, green => 2, blue => 3 }
              char_hash => sub { $basis->short_name_hash_from_tuple($_[1]) }, # { r =>1, g => 2, b => 3 }
            named_array => sub { [$basis->space_name, @{$_[1]}] },            # ['rgb',1,2,3]
           named_string => sub { $_[0]->named_string_from_tuple($_[1]) },     #  'rgb: 1, 2, 3'
             css_string => sub { $_[0]->css_string_from_tuple($_[1]) },       #  'rgb(1,2,3)'
    );
    bless { basis => $basis, deformatter => \%deformats, formatter => \%formats,
            value_form => $value_form, prefix => $prefix, suffix => $suffix,
            value_numifier => { into_numric => '', from_numeric => '' },
          }
}

sub expand_suffix_def {
    my ($basis, $suffix) = @_;
    my $count = $basis->axis_count;
    $suffix = [('') x $count] unless defined $suffix;
    $suffix = [($suffix) x $count] unless ref $suffix;
    return 'need an ARRAY as definition of axis value suffix' unless ref $suffix eq 'ARRAY';
    return 'definition of axis value suffix has to have same lengths as basis' unless @$suffix == $count;
    return $suffix;
}
sub get_suffix {
    my ($self, $suffix) = @_;
    return $self->{'suffix'} unless defined $suffix;
    expand_suffix_def( $self->{'basis'}, $suffix );
}

sub add_formatter   {
    my ($self, $format, $code) = @_;
    return if not defined $format or ref $format or ref $code ne 'CODE';
    return if $self->has_formatter( $format );
    $self->{'formatter'}{ $format } = $code;
}
sub add_deformatter {
    my ($self, $format, $code) = @_;
    return if not defined $format or ref $format or ref $code ne 'CODE';
    return if $self->has_deformatter( $format );
    $self->{'deformatter'}{ lc $format } = $code;
}
sub set_value_numifier {
    my ($self, $pre_code, $post_code) = @_;
    return 0 if ref $pre_code ne 'CODE' or ref $post_code ne 'CODE';
    $self->{'value_numifier'}{'into_numric'} = $pre_code;
    $self->{'value_numifier'}{'from_numeric'} = $post_code;
}

#### public API: formatting value tuples ###############################
sub basis           { $_[0]{'basis'}}
sub has_formatter   { (defined $_[1] and exists $_[0]{'formatter'}{ lc $_[1] }) ? 1 : 0 }
sub has_deformatter { (defined $_[1] and exists $_[0]{'deformatter'}{ lc $_[1] }) ? 1 : 0 }

sub deformat {
    my ($self, $color, $suffix) = @_;
    return undef unless defined $color;
    $suffix = $self->get_suffix( $suffix );
    return $suffix unless ref $suffix;
    for my $format_name (sort keys %{$self->{'deformatter'}}){
        my $deformatter = $self->{'deformatter'}{$format_name};
        my $tuple = $deformatter->( $self, $color );
        next unless ref $tuple;
        $tuple = $self->check_raw_value_format( $tuple );
        next unless ref $tuple;
        $tuple = $self->remove_suffix($tuple, $suffix);
        next unless ref $tuple;
        return wantarray ? ($tuple, $format_name) : $tuple;
    }
    return undef;
}
sub format {
    my ($self, $tuple, $format, $suffix, $prefix) = @_;
    return '' unless $self->basis->is_value_tuple( $tuple );
    return '' unless $self->has_formatter( $format );
    $suffix = $self->get_suffix( $suffix );
    return $suffix unless ref $suffix;
    $tuple = $self->add_suffix( $tuple, $suffix );
    $self->{'formatter'}{ lc $format }->($self, $tuple);
}

#### work methods ######################################################
sub remove_suffix { # and unnecessary white space
    my ($self, $tuple, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $tuple );
    $suffix = $self->get_suffix( $suffix );
    return $suffix unless ref $suffix;
    $tuple = [@$tuple]; # loose ref and side effects
    if (ref $self->{'value_numifier'}{'into_numric'}){
        $tuple = $self->{'value_numifier'}{'into_numric'}->($tuple);
        return unless $self->basis->is_value_tuple( $tuple );
    }
    local $/ = ' ';
    chomp $tuple->[$_] for $self->basis->axis_iterator;
    for my $axis_index ($self->basis->axis_iterator){
        next unless $suffix->[ $axis_index ];
        my $val_length = length $tuple->[ $axis_index ];
        my $suf_length = length $suffix->[ $axis_index ];
        $tuple->[$axis_index] = substr($tuple->[$axis_index], 0, $val_length - $suf_length)
            if substr( $tuple->[$axis_index], - $suf_length) eq $suffix->[ $axis_index ]
            and substr( $tuple->[$axis_index], - ($suf_length+1),1) ne ' ';
    }
    return $tuple;
}
sub add_suffix {
    my ($self, $tuple, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $tuple );
    $suffix = $self->get_suffix( $suffix );
    return $suffix unless ref $suffix; # has to be array or error message
    $tuple = [@$tuple]; # loose ref and side effects
    if (ref $self->{'value_numifier'}{'from_numeric'}){
        $tuple = $self->{'value_numifier'}{'from_numeric'}->($tuple);
        return unless $self->basis->is_value_tuple( $tuple );
    }
    local $/ = ' ';
    chomp $tuple->[$_] for $self->basis->axis_iterator;
    for my $axis_index ($self->basis->axis_iterator){
        next unless $suffix->[ $axis_index ];
        my $val_length = length $tuple->[ $axis_index ];
        my $suf_length = length $suffix->[ $axis_index ];
        $tuple->[$axis_index] .= $suffix->[ $axis_index ]
            if substr( $tuple->[$axis_index], - $suf_length) ne $suffix->[ $axis_index ];
    }
    return $tuple;
}

sub check_raw_value_format {
    my ($self, $tuple) = @_;
    return 0 if ref $tuple ne 'ARRAY';
    return 0 if @$tuple != $self->basis->axis_count;
    my @re = $self->get_value_regex();
    for my $axis_index ($self->basis->axis_iterator){
        return 0 unless $tuple->[$axis_index] =~ /^$re[$axis_index]$/;
    }
    return $tuple;
}

sub get_value_regex {
    my ($self) = @_;
    map {'\s*('.$self->{'value_form'}[$_].'(?:'.quotemeta($self->{'suffix'}[$_]).')?)\s*' } # quotemeta
        $self->basis->axis_iterator;
}

#### converter: format --> values ######################################
sub tuple_from_named_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    $string =~ /^\s*([^ :]+):\s*(\s*[^:]+)\s*$/i;
    my $space_name = $1;
    my $tuple_string = $2;
    return 0 unless $self->{'basis'}->is_name( $space_name ) and $tuple_string;
    local $/ = ' ';
    chomp $tuple_string;
    return [split(/\s*,\s*/, $tuple_string)] if index($tuple_string, ',') > -1;
    return [split(/\s+/,     $tuple_string)];
}
sub tuple_from_css_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    $string =~ /^\s*([^()]+)\(\s*([^()]+)\s*\)\s*$/i;
    my $space_name = $1;
    my $tuple_string = $2;
    return 0 unless $self->{'basis'}->is_name( $space_name ) and $tuple_string;
    local $/ = ' ';
    chomp $tuple_string;
    return [split(/\s*,\s*/, $tuple_string)] if index($tuple_string, ',') > -1;
    return [split(/\s+/,     $tuple_string)];
}
sub tuple_from_named_array {
    my ($self, $array) = @_;
    return 0 if ref $array ne 'ARRAY' or not @$array;
    return 0 unless $self->basis->is_name( $array->[0] );
    $array = [@$array[1 .. $#$array]];
    $array = $array->[0] if @$array == 1 and ref $array->[0] eq 'ARRAY';
    return 0 unless @$array == $self->basis->axis_count;
    return $array;
}
sub tuple_from_hash        {
    my ($self, $hash) = @_;
    return 0 unless $self->basis->is_hash($hash);
    $self->basis->tuple_from_hash( $hash );
}

#### converter: values --> format ######################################
sub named_array_from_tuple {
    my ($self, $tuple, $name) = @_;
    $name //= $self->basis->space_name(undef, 'given');
    return [$name, @$tuple];
}
sub named_string_from_tuple {
    my ($self, $tuple, $name) = @_;
    $name //= $self->basis->space_name(undef, 'given');
    return lc($name).': '.join(', ', @$tuple);
}
sub css_string_from_tuple {
    my ($self, $tuple, $name) = @_;
    $name //= $self->basis->space_name(undef, 'given');
    return  lc($name).'('.join(', ', @$tuple).')';
}

1;
