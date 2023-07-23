use v5.12;
use warnings;

# utilities for any sub module of the distribution

package Graphics::Toolkit::Color::Util;

use Exporter 'import';
our @EXPORT_OK = qw/round has_hash_key_initials extract_hash_values color_key_short_cut/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $half = 0.50000000000008;

sub round {
    $_[0] >= 0 ? int ($_[0] + $half)
               : int ($_[0] - $half)
}

sub has_hash_key_initials {
    my ($def_hash, $value_hash) = @_;      # % def keys have to be single char lc
    return 0 unless ref $def_hash eq 'HASH' and ref $value_hash eq 'HASH';
    my @keys = keys %$value_hash;
    return 0 unless keys (%$def_hash) == @keys;
    for my $key (@keys) {
        return 0 unless exists $def_hash->{ color_key_short_cut( $key ) };
    }
    return 1;
}

sub extract_hash_values {
    my ($def_hash, $value_hash) = @_;      # % def keys have to be single char lc
    return 0 unless ref $def_hash eq 'HASH' and ref $value_hash eq 'HASH';
    my @keys = keys %$value_hash;
    return 0 unless keys (%$def_hash) == @keys;
    my @values;
    for my $key (@keys) {
        my $shortcut = color_key_short_cut( $key );
        return 0 unless exists $def_hash->{ $shortcut };
        $values[ $def_hash->{ $shortcut } ] = $value_hash->{ $key };
    }
    return \@values;
}

sub color_key_short_cut { lc substr($_[0], 0, 1) if defined $_[0] }

1;
