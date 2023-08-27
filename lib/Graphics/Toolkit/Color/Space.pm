use v5.12;
use warnings;

# common base of all color spaces

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::SpaceBasis;
use Graphics::Toolkit::Color::Util ':all';
use Carp;

sub new {
    my $pkg = shift;
    my (undef, $axis, undef, $range, undef, $type) = @_;
    return unless ref $axis eq 'ARRAY';
    my $basis = Graphics::Toolkit::Color::SpaceBasis->new( @$axis );
    return unless ref $basis;

    if    (not defined $range){                # check range settings
        $range = [([0,1]) x $basis->count];    # normal range
    } elsif (not ref $range and $range > 0) {
        $range = int $range;
        $range = [([0, $range]) x $basis->count];
    } elsif (ref $range eq 'ARRAY' and @$range == @$axis ) {
        for my $i (0 .. $basis->count-1) {
            my $drange = $range->[$i]; # range def of this dimension
            if (not ref $drange and $drange > 0){
                $drange = int $drange;
                $range->[$i] = [0, $drange, $drange];
            } elsif (ref $drange eq 'ARRAY' and @$drange == 2
                     and defined $drange->[0] and defined $drange->[1]
                     and $drange->[0] < $drange->[1]                   ) {
                $drange->[0] = int $drange->[0];
                $drange->[1] = int $drange->[1];
            } else { return }
        }
    } else { return }

    if (not defined $type){ $type = [ (1) x $basis->count ] } # check type settings
    elsif (ref $type eq 'ARRAY' and @$type == @$axis ) {
        for my $i (0 .. $basis->count-1) {
            my $dtype = $type->[$i]; # type def of this dimension
            return unless defined $dtype;
            if    ($dtype eq 'angle' or $dtype eq 'circular' or $dtype eq '0') { $type->[$i] = 0 }
            elsif ($dtype eq 'linear'                        or $dtype eq '1') { $type->[$i] = 1 }
            else { return }
        }
    } else { return }


    # which formats the constructor will accept, that can be deconverted into list
    my %deformats = ( hash => sub { $basis->list_from_hash(@_)   if $basis->is_hash(@_) },
               named_array => sub { @{$_[0]}[1 .. $#{$_[0]}]     if $basis->is_named_array(@_) },
                    string => sub { $basis->list_from_string(@_) if $basis->is_string(@_) },
                css_string => sub { $basis->list_from_css(@_)    if $basis->is_css_string(@_) },
    );
    # which formats we can output
    my %formats = (list => sub { @_ },                                 # 1,2,3
                   hash => sub { $basis->key_hash_from_list(@_) },     # { red => 1, green => 2, blue => 3 }
              char_hash => sub { $basis->shortcut_hash_from_list(@_) },# { r =>1, g => 2, b => 3 }
                  array => sub { $basis->named_array_from_list(@_) },  # ['rgb',1,2,3]
                 string => sub { $basis->named_string_from_list(@_) }, #   rgb: 1, 2, 3
             css_string => sub { $basis->css_string_from_list(@_) },   #   rgb(1,2,3)
    );

    bless { basis => $basis, range => $range, type => $type,
            format => \%formats, deformat => \%deformats, convert => {},
    };
}
sub basis            { $_[0]{'basis'}}
sub name             { $_[0]->basis->name }
sub dimensions       { $_[0]->basis->count }
sub iterator         { $_[0]->basis->iterator }
sub is_array         { $_[0]->basis->is_array( $_[1] ) }
sub is_partial_hash  { $_[0]->basis->is_partial_hash( $_[1] ) }
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }

########################################################################

sub delta { # values have to be normalized
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_array( $values1 ) and $self->basis->is_array( $values2 );
    my @delta = map {$values2->[$_] - $values1->[$_] } $self->basis->iterator;
    map { $self->{'type'}[$_] ? $delta[$_]     :
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->iterator;
}

sub check {
    my ($self, $values, $range) = @_;
    return carp 'color value vector in '.$self->name.' needs '.$self->dimensions.' values' if @$values != $self->dimensions;
    return if defined $range and not $self->basis->is_range_def( $range );
    $range //= $self->{'range'};
    my @names = $self->basis->keys;
    for my $i ($self->basis->iterator){
        return carp $names[$i]." value is below minimum of ".$range->[$i][0] if $values->[$i] < $range->[$i][0];
        return carp $names[$i]." value is above maximum of ".$range->[$i][1] if $values->[$i] > $range->[$i][1];
        return carp $names[$i]." value has to be an integer" if ($range->[$i][1] - $range->[$i][0]) > 1
                                                             and $values->[$i] != int $values->[$i];
    }
    return;
}

sub clamp {
    my ($self, $values, $range) = @_;
    return if defined $range and not $self->basis->is_range_def( $range );
    $range //= $self->{'range'};
    push @$values, 0 while @$values < $self->dimensions;
    pop  @$values    while @$values > $self->dimensions;
    for my $i ($self->basis->iterator){
        my $delta = $range->[$i][1] - $range->[$i][0];
        if ($self->{'type'}[$i]){
            $values->[$i] = $range->[$i][0] if $values->[$i] < $range->[$i][0];
            $values->[$i] = $range->[$i][1] if $values->[$i] > $range->[$i][1];
        } else {
            $values->[$i] += $delta while $values->[$i] < $range->[$i][0];
            $values->[$i] -= $delta while $values->[$i] > $range->[$i][1];
            $values->[$i] = $range->[$i][0] if $values->[$i] == $range->[$i][1];
        }
        $values->[$i] = round($values->[$i]) if $delta > 1;
    }
    return @$values;
}

########################################################################

sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    return if defined $range and not $self->basis->is_range_def( $range );
    $range //= $self->{'range'};
    map { ($values->[$_] - $range->[$_][0]) / ($range->[$_][1]-$range->[$_][0]) } $self->basis->iterator;
}

sub denormalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    return if defined $range and not $self->basis->is_range_def( $range );
    $range //= $self->{'range'};
    map { my $v = ($values->[$_] * ($range->[$_][1]-$range->[$_][0])) + $range->[$_][0];
          ($range->[$_][1]-$range->[$_][0]) == 1 ? $v : round ($v)                } $self->basis->iterator;
}

########################################################################

sub add_formatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or ref $code ne 'CODE';
    return 0 if $self->has_format( $format );
    $self->{'format'}{ $format } = $code;
}
sub format {
    my ($self, $values, $format) = @_;
    return unless $self->basis->is_array( $values );
    $self->{'format'}{ lc $format }->(@$values) if $self->has_format( $format );
}

sub add_deformatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or exists $self->{'deformat'}{$format} or ref $code ne 'CODE';
    $self->{'deformat'}{ lc $format } = $code;
}
sub deformat {
    my ($self, $values) = @_;
    return undef unless defined $values;
    for my $deformatter (values %{$self->{'deformat'}}){
        my @values = $deformatter->($values);
        return @values if @values == $self->dimensions;
    }
    return undef;
}

########################################################################

sub add_converter {
    my ($self, $space_name, $to_code, $from_code) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code };
}
sub convert {
    my ($self, $values, $space_name) = @_;
    return unless $self->{'basis'}->is_array( $values ) and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'to'}->(@$values) if $self->can_convert( $space_name );
}

sub deconvert {
    my ($self, $values, $space_name) = @_;
    return unless ref $values eq 'ARRAY' and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'from'}->(@$values) if $self->can_convert( $space_name );
}

1;
