use v5.12;
use warnings;

# logic of value hash keys for all color spacs

package Graphics::Toolkit::Color::SpaceKeys;

sub new {
    my $pkg = shift;
    my @keys = map {lc} @_;
    return unless @keys > 0;
    my @iterator = 0 .. $#keys;
    my %key_order = map { $keys[$_] => $_ } @iterator;
    my @shortcuts = map { color_key_short_cut($_) } @keys;
    my %shortcut_order = map { $shortcuts[$_] => $_ } @iterator;
    bless { keys => [@keys], shortcuts => [@shortcuts],
            key_order => \%key_order, shortcut_order => \%shortcut_order,
            name => join('', @shortcuts), count => int @keys, iterator => \@iterator }
}

sub keys     { @{$_[0]{'keys'}} }
sub shortcuts{ @{$_[0]{'shortcuts'}} }
sub iterator { @{$_[0]{'iterator'}} }
sub count    {   $_[0]{'count'} }
sub name     {   $_[0]{'name'} }

sub is_key      { (defined $_[1] and exists $_[0]->{'key_order'}{ lc $_[1] }) ? 1 : 0 }
sub is_shortcut { (defined $_[1] and exists $_[0]->{'shortcut_order'}{ lc $_[1] }) ? 1 : 0 }
sub is_key_or_shortcut { $_[0]->is_key($_[1]) or $_[0]->is_shortcut($_[1]) }
sub is_array {
    my ($self, $value_array) = @_;
    (ref $value_array eq 'ARRAY' and @$value_array == $self->{'count'}) ? 1 : 0;
}
sub is_hash {
    my ($self, $value_hash) = @_;
    return 0 unless ref $value_hash eq 'HASH' and CORE::keys %$value_hash == $self->{'count'};
    for (CORE::keys %$value_hash) {
        return 0 unless $self->is_key_or_shortcut( $_);
    }
    return 1;
}
sub is_partial_hash {
    my ($self, $value_hash) = @_;
    return 0 unless ref $value_hash eq 'HASH';
    my $key_count = CORE::keys %$value_hash;
    return 0 unless $key_count and $key_count <= $self->{'count'};
    for (CORE::keys %$value_hash) {
        return 0 unless $self->is_key_or_shortcut( $_);
    }
    return 1;
}

sub key_pos      { $_[0]->{'key_order'}{ lc $_[1] } if defined $_[1] }
sub shortcut_pos { $_[0]->{'shortcut_order'}{ lc $_[1] } if defined $_[1] }

sub list_value_from_key {
    my ($self, $key, @values) = @_;
    $key = lc $key;
    return unless @values == $self->{'count'};
    return unless exists $self->{'key_order'}{ $key };
    return $values[ $self->{'key_order'}{ $key } ];
}

sub list_value_from_shortcut {
    my ($self, $shortcut, @values) = @_;
    $shortcut = lc $shortcut;
    return unless @values == $self->{'count'};
    return unless exists $self->{'shortcut_order'}{ $shortcut };
    return $values[ $self->{'shortcut_order'}{ $shortcut } ];
}

sub list_from_hash {
    my ($self, $value_hash) = @_;
    return undef unless ref $value_hash eq 'HASH' and CORE::keys %$value_hash == $self->{'count'};
    my @values = (0) x $self->{'count'};
    for my $value_key (CORE::keys %$value_hash) {
        my $shortcut = color_key_short_cut( $value_key );
        return 0 unless exists $self->{'shortcut_order'}{ $shortcut };
        $values[ $self->{'shortcut_order'}{ $shortcut } ] = $value_hash->{ $value_key };
    }
    return @values;
}

sub key_hash_from_list {
    my ($self, @values) = @_;
    return unless @values == $self->{'count'};
    return { map { $self->{'keys'}[$_] => $values[$_]} @{$self->{'iterator'}} };
}

sub shortcut_hash_from_list {
    my ($self, @values) = @_;
    return unless @values == $self->{'count'};
    return { map {$self->{'shortcuts'}[$_] => $values[$_]} @{$self->{'iterator'}} };
}

sub color_key_short_cut { lc substr($_[0], 0, 1) if defined $_[0] }

1;
