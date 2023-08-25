use v5.12;
use warnings;

# common base of all color spaces

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::SpaceBasis;
use Graphics::Toolkit::Color::Util ':all';

sub new {
    my $pkg = shift;
    my (undef, $axis, undef, $range, undef, $type) = @_;
    return unless ref $axis eq 'ARRAY';
    my $basis = Graphics::Toolkit::Color::SpaceBasis->new( @$axis );
    return unless ref $basis;

    if    (not defined $range){                # check range settings
        $range = [([0,1,1]) x $basis->count];  # no denormal range
    } elsif (not ref $range and $range > 0) {
        $range = int $range;
        $range = [([0, $range, $range]) x $basis->count];
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
                splice (@$drange, 1, 1, int($drange->[1] - $drange->[0]));
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
    );
    # which formats we can output
    my %formats = (list => sub { @_ },
                   hash => sub { $basis->key_hash_from_list(@_) },
              char_hash => sub { $basis->shortcut_hash_from_list(@_) },
                  array => sub { $basis->named_array_from_list(@_) },
                 string => sub { $basis->named_string_from_list(@_) },
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

sub delta {
    my ($self, $values1, $values2) = @_;
    return unless $self->basis->is_array( $values1 ) and $self->basis->is_array( $values2 );
    my @delta = map {$values2->[$_] - $values1->[$_] } $self->basis->iterator;
    map { $self->{'type'}[$_] ? $delta[$_]     :
            $delta[$_] < -0.5 ? ($delta[$_]+1) :
            $delta[$_] >  0.5 ? ($delta[$_]-1) : $delta[$_] } $self->basis->iterator;
}

sub check {
    my ($self, @values) = @_;

}
#~ sub check { # carp returns 1
    #~ my (@rgb) = @_;
    #~ my $range_help = 'has to be an integer between 0 and 255';
    #~ return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless $rgb_def->is_array( \@rgb );
    #~ return carp "red value $rgb[0] ".$range_help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    #~ return carp "green value $rgb[1] ".$range_help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    #~ return carp "blue value $rgb[2] ".$range_help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    #~ 0;
#~ }

sub clamp { # cut values into the domain of definition of 0 .. 255
    map { round($_) } map {$_ < 0 ? 0 : $_} map {$_ > 255 ? 255 : $_}  @_;
}


#~ sub clamp {
    #~ my ($self, $values, $range) = @_;
    #~ return if defined $range and not $self->basis->is_range_def( $range );
    #~ $range //= $self->{'range'};
    #~ push @$values, 0 while @$values < $self->dimensions;
    #~ pop  @$values    while @$values > $self->dimensions;
    #~ # map {} $self->basis->iterator;
#~ }

########################################################################

sub normalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    return if defined $range and not $self->basis->is_range_def( $range );
    $range //= $self->{'range'};
    map { ($values->[$_] - $range->[$_][0]) / $range->[$_][1] } $self->basis->iterator;
}

sub denormalize {
    my ($self, $values, $range) = @_;
    return unless $self->basis->is_array( $values );
    return if defined $range and not $self->basis->is_range_def( $range );
    $range //= $self->{'range'};
    map { my $v = ($values->[$_] * $range->[$_][1]) + $range->[$_][0];
          $range->[$_][1] == 1 ? $v : round ($v)                      } $self->basis->iterator;
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
