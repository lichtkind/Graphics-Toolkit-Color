use v5.12;
use warnings;

# store color space name and its axis short and long names, derived core methods

package Graphics::Toolkit::Color::Space::Basis;

sub new {
    my ($pkg, $axis_long_names, $axis_shortcuts, $space_prefix, $space_name) = @_;
    return 'first argument (axis names) has to be an ARRAY reference' unless ref $axis_long_names eq 'ARRAY';
    return 'amount of shortcut names have to match that of full names'
        if defined $axis_shortcuts and (ref $axis_shortcuts ne 'ARRAY' or @$axis_long_names != @$axis_shortcuts);

    my @axis_long = map {lc} @$axis_long_names;
    my @axis_short = map { _color_key_shortcut($_) } (defined $axis_shortcuts) ? @$axis_shortcuts : @axis_long;
    return unless @axis_long > 0;

    my @iterator    = 0 .. $#axis_long;
    my %long_order  = map { $axis_long[$_] => $_ } @iterator;
    my %short_order = map { $axis_short[$_] => $_ } @iterator;
    my $name = $space_name // uc join( '', @axis_short );
    $name = $space_prefix.$name if defined $space_prefix and $space_prefix;

    bless { axis_long => \@axis_long, axis_short => \@axis_short,
            long_order => \%long_order, short_order => \%short_order,
            name => $name, count => int @axis_long, iterator => \@iterator }
}

#### getter ############################################################

sub space_name  {   $_[0]{'name'}        }     # color space name
sub long_names  { @{$_[0]{'axis_long'}}  }     # axis full names
sub short_names { @{$_[0]{'axis_short'}} }     # axis short names
sub iterator    { @{$_[0]{'iterator'}}   }     # counting all axis 0 .. -1
sub count       {   $_[0]{'count'}       }     # amount of axis

sub pos_from_long  {  defined $_[1] ? $_[0]->{'long_order'}{ lc $_[1] } : undef }
sub pos_from_short {  defined $_[1] ? $_[0]->{'short_order'}{ lc $_[1] } : undef }

#### predicates ########################################################

sub is_long_name   { (defined $_[1] and exists $_[0]->{'long_order'}{ lc $_[1] }) ? 1 : 0 }
sub is_short_name  { (defined $_[1] and exists $_[0]->{'short_order'}{ lc $_[1] }) ? 1 : 0 }
sub is_name        { $_[0]->is_long_name($_[1]) or $_[0]->is_short_name($_[1]) }

sub is_hash {
    my ($self, $value_hash) = @_;
    $self->is_partial_hash( $value_hash ) and (keys %$value_hash == $self->count);
}
sub is_partial_hash {
    my ($self, $value_hash) = @_;
    return 0 unless ref $value_hash eq 'HASH';
    my $key_count = keys %$value_hash;
    return 0 unless $key_count and $key_count <= $self->count;
    for (keys %$value_hash) {
        return 0 unless $self->is_name( $_ );
    }
    return 1;
}

sub is_value_tuple { (ref $_[1] eq 'ARRAY' and @{$_[1]} == $_[0]->count) ? 1 : 0 }

#### converter #########################################################

sub short_from_long_name {
    my ($self, $name) = @_;
    return unless $self->is_long_name( $name );
    ($self->short_names)[ $self->pos_from_long( $name ) ];
}
sub long_from_short_name {
    my ($self, $name) = @_;
    return unless $self->is_short_name( $name );
    ($self->long_names)[ $self->pos_from_short( $name ) ];
}

sub long_hash_from_tuple {
    my ($self, $values) = @_;
    return unless $self->is_value_tuple( $values );
    return { map { $self->{'axis_long'}[$_] => $values->[$_]} $self->iterator };
}
sub short_hash_from_tuple {
    my ($self, $values) = @_;
    return unless $self->is_value_tuple( $values );
    return { map {$self->{'axis_short'}[$_] => $values->[$_]} $self->iterator };
}

sub tuple_from_hash {
    my ($self, $value_hash) = @_;
    return unless $self->is_hash( $value_hash );
    my @values = (0) x $self->count;
    for my $key (keys %$value_hash) {
        if    ($self->is_long_name( $key ))  { $values[ $self->pos_from_long($key) ] = $value_hash->{ $key } }
        elsif ($self->is_short_name( $key )) { $values[ $self->pos_from_short($key) ] = $value_hash->{ $key } }
    }
    return \@values;
}
sub pos_hash_from_partial_hash {
    my ($self, $value_hash) = @_;
    return unless $self->is_partial_hash( $value_hash );
    my $values = {};
    for my $key (keys %$value_hash) {
        if    ($self->is_long_name( $key ))  { $values->{$self->pos_from_long($key)} = $value_hash->{ $key } }
        elsif ($self->is_short_name( $key )) { $values->{$self->pos_from_short($key)} = $value_hash->{ $key } }
    }
    return $values;
}

sub select_tuple_value_from_name {
    my ($self, $name, $values) = @_;
    $name = lc $name;
    return unless $self->is_value_tuple( $values );
    return $values->[ $self->{'long_order'}{$name} ] if exists $self->{'long_order'}{$name};
    return $values->[ $self->{'short_order'}{$name} ] if exists $self->{'short_order'}{$name};
    undef;
}

#### util ##############################################################

sub _color_key_shortcut { lc substr($_[0], 0, 1) if defined $_[0] }

1;
