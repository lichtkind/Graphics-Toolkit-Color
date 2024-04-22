use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::Space::Format;

sub new {
    my ($pkg, $basis, $suffix ) = @_;
    return 'first argument has to be an Color::Space::Basis reference'
        unless ref $basis eq 'Graphics::Toolkit::Color::Space::Basis';

    my $count = $basis->count;
    $suffix = [('') x $count] unless defined $suffix;
    $suffix = [($suffix) x $count] unless ref $suffix;
    return 'need an ARRAY as definition of axis value suffix' unless ref $suffix eq 'ARRAY';
    return 'definition of axis value suffix has to have same lengths as basis' unless @$suffix == $count;

    # format --> tuple
    my %deformats = ( hash => sub { $basis->tuple_from_hash(@_)  if $basis->is_hash(@_) },
               named_array => sub { [ @{$_[0]}[1 .. $#{$_[0]}] ] if is_named_array(@_) },
                    string => sub { tuple_from_string(@_)        if is_named_string(@_) },
                css_string => sub { tuple_from_css(@_)           if is_css_string(@_) },
    );
    # tuple --> format
    my %formats = (list => sub { @$_ },                                #   1, 2, 3
                   hash => sub { $basis->long_hash_from_tuple(@_) },   # { red => 1, green => 2, blue => 3 }
              char_hash => sub { $basis->short_hash_from_tuple(@_) },  # { r =>1, g => 2, b => 3 }
                  array => sub { [$basis->space_name, @$_] },          # ['rgb',1,2,3]
                 string => sub { named_string_from_tuple(@_) },         #  'rgb: 1, 2, 3'
             css_string => sub { css_string_from_tuple(@_) },           #  'rgb(1,2,3)'
    );
    bless { basis => $basis, suffix => $suffix, format => \%formats, deformat => \%deformats, }
}

########################################################################
sub basis            { $_[0]{'basis'}}
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub has_deformat     { (defined $_[1] and exists $_[0]{'deformat'}{ lc $_[1] }) ? 1 : 0 }
sub add_formatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or ref $code ne 'CODE';
    return 0 if $self->has_format( $format );
    $self->{'format'}{ $format } = $code;
}
sub add_deformatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or exists $self->{'deformat'}{$format} or ref $code ne 'CODE';
    $self->{'deformat'}{ lc $format } = $code;
}

########################################################################

sub format {
    my ($self, $values, $format, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $values = self->add_suffix($values, $suffix);
    $self->{'format'}{ lc $format }->(@$values) if $self->has_format( $format );
}

sub deformat {
    my ($self, $color, $suffix) = @_;
    return undef unless defined $color;
    for my $deformatter (values %{$self->{'deformat'}}){
        my $values = $deformatter->( $color );
        return self->remove_suffix($values, $suffix) if $self->basis->is_value_tuple( $values );
    }
    return undef;
}

sub add_suffix {
    my ($self, $values, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $suffix //= $self->{'suffix'};
    $suffix = [($suffix) x $self->count] unless ref $suffix;
    [ map { ($self->{'suffix'}[$_] and substr( $values->[$_], - length($self->{'suffix'}[$_])) ne $self->{'suffix'}[$_])
                  ? $values->[$_] . $self->{'suffix'}[$_] : $values->[$_] } $self->basis->iterator ];
}

sub remove_suffix {
    my ($self, $values, $suffix) = @_;
    return unless $self->basis->is_value_tuple( $values );
    $suffix //= $self->{'suffix'};
    $suffix = [($suffix) x $self->basis->count] unless ref $suffix;
    [ map { ($self->{'suffix'}[$_] and
             substr( $values->[$_], - length($self->{'suffix'}[$_])) eq $self->{'suffix'}[$_])
          ? (substr( $values->[$_], 0, length($values->[$_]) - length($self->{'suffix'}[$_]))) : $values->[$_] } $self->basis->iterator ];
}

########################################################################

sub is_named_string { #
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    $string = lc $string;
    my $name = lc $self->basis->space_name;
    return 0 unless index($string, $name.':') == 0;
    my $nr = '\s*-?\d+(?:\.\d+)?\s*';
    my $nrs = join(',', ('\s*-?\d+(?:\.\d+)?\s*') x $self->basis->count);
    ($string =~ /^$name:$nrs$/) ? 1 : 0;
}
sub is_css_string {
    my ($self, $string) = @_;
    return 0 unless defined $string and not ref $string;
    $string = lc $string;
    my $name = lc $self->basis->space_name;
    return 0 unless index($string, $name.'(') == 0;
    my $nr = '\s*-?\d+(?:\.\d+)?\s*';
    my $nrs = join(',', ('\s*-?\d+(?:\.\d+)?\s*') x $self->basis->count);
    ($string =~ /^$name\($nrs\)$/) ? 1 : 0;
}
sub is_named_array {
    my ($self, $value_array) = @_;
    (ref $value_array eq 'ARRAY' and @$value_array == ($self->basis->count+1)
                                 and uc $value_array->[0] eq uc $self->basis->space_name) ? 1 : 0;
}

########################################################################

sub tuple_from_string {
    my ($self, $string) = @_;
    my @parts = split(/:/, $string);
    return [split(/,/, $parts[1])];
}

sub tuple_from_css {
    my ($self, $string) = @_;
    1 until chop($string) eq ')';
    my @parts = split(/\(/, $string);
    return [split(/,/, $parts[1])];
}

sub named_array_from_tuple {
    my ($self, $values) = @_;
    return [$self->basis->space_name, @$values] unless $self->basis->is_value_tuple( $values );
}

sub named_string_from_tuple {
    my ($self, $values) = @_;
    lc( $self->basis->space_name).': '.join(', ', @$values);
}

sub css_string_from_tuple {
    my ($self, $values) = @_;
    lc( $self->basis->space_name).'('.join(',', @$values).')';
}

1;
