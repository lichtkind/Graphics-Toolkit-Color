use v5.12;
use warnings;

# check, convert and measure color values in RGB space

package Graphics::Toolkit::Color::Value::RGB;
use Graphics::Toolkit::Color::Util ':all';
use Carp;
use Exporter 'import';
our @EXPORT_OK = qw/check_rgb trim_rgb delta_rgb distance_rgb hex_from_rgb rgb_from_hex/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our @keys = qw/red green blue/;
our @short_keys = map {color_key_short_cut $_} @keys;
our @getter = (@keys, qw/hex list hash long_name_hash/);
our $space_name = join '', @short_keys;
my $key_count = length $space_name;
my @key_iterator = 0 .. $key_count - 1;
my $shortcut_order = { map { $short_keys[$_] => $_ } @key_iterator };

sub new {
    my $pkg = shift;
    bless [ trim(@_) ];
}
sub values {
    my $self = shift;
    my $which = lc( shift // 'list' );
    if    ($which eq 'list')          { @$self }
    elsif ($which eq 'hash')          { as_hash( @$self ) }
    elsif ($which eq 'long_name_hash'){ as_long_hash( @$self ) }
    elsif ($which eq 'hex')           { hex_from_rgb(@$self) }
    elsif ($which eq 'red')           { $self->[0] }
    elsif ($which eq 'green')         { $self->[1] }
    elsif ($which eq 'blue')          { $self->[2] }
    elsif (exists $shortcut_order->{$which}) { $self->[ $shortcut_order->{$which} ] }
}

sub check_rgb { &check }
sub check { # carp returns 1
    my (@rgb) = @_;
    my $range_help = 'has to be an integer between 0 and 255';
    return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless @rgb == $key_count;
    return carp "red value $rgb[0] ".$range_help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    return carp "green value $rgb[1] ".$range_help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    return carp "blue value $rgb[2] ".$range_help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    0;
}

sub trim_rgb { &trim }
sub trim { # cut values into the domain of definition of 0 .. 255
    my (@rgb) = @_;
    for (@key_iterator){
        $rgb[$_] =   0 unless exists $rgb[$_];
        $rgb[$_] =   0 if $rgb[$_] <   0;
        $rgb[$_] = 255 if $rgb[$_] > 255;
    }
    $rgb[$_] = round($rgb[$_]) for @key_iterator;
    pop @rgb until @rgb == $key_count;
    @rgb;
}

sub delta_rgb { &delta }
sub delta { # \@rgb, \@rgb --> @rgb             distance as vector
    my ($rgb, $rgb2) = @_;
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb differences"
        unless ref $rgb eq 'ARRAY' and @$rgb == $key_count
           and ref $rgb2 eq 'ARRAY' and @$rgb2 == $key_count;
    check_rgb(@$rgb) and return;
    check_rgb(@$rgb2) and return;
    (abs($rgb->[0] - $rgb2->[0]), abs($rgb->[1] - $rgb2->[1]), abs($rgb->[2] - $rgb2->[2]) );
}

sub distance_rgb { &distance }
sub distance { # \@rgb, \@rgb --> $d
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb distance " if @_ != 2;
    my @delta_rgb = delta( $_[0], $_[1] );
    return unless @delta_rgb == 3;
    sqrt($delta_rgb[0] ** 2 + $delta_rgb[1] ** 2 + $delta_rgb[2] ** 2);
}


sub hex_from_rgb {  return unless @_ == 3;  sprintf "#%02x%02x%02x", @_ }

sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my $hex = shift;
    return carp "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
    unless defined $hex and (length($hex) == 4 or length($hex) == 7) and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    (length $hex == 3) ? (map { CORE::hex($_.$_) } unpack( "a1 a1 a1", $hex))
                       : (map { CORE::hex($_   ) } unpack( "a2 a2 a2", $hex));
}

# sub is_hex { }

sub as_hash {
    my (@rgb) = @_;
    check(@rgb) and return;
    return { map {$short_keys[$_] => $rgb[$_] } @key_iterator };
}
sub as_long_hash {
    my (@rgb) = @_;
    check(@rgb) and return;
    return { map {$keys[$_] => $rgb[$_] } @key_iterator };
}
sub is_hash { has_hash_key_initials( $shortcut_order, $_[0] ) }  # % --> ?       # hash with righ keys
sub hash_as_list { extract_hash_values ( $shortcut_order, $_[0] ) }  # % --> @list|0

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value::RGB - converter and getter for the RGB color space

=head1 SYNOPSIS

    use Graphics::Toolkit::Color::Value::RGB ':all';
    my $c = Graphics::Toolkit::Color::Value::RGB->new(20,30,500);
    $c->hex;             # same as hex_from_rgb(20,30,50) eq '#141EFF'
                         # rgb_from_hex('#141EFF')
    $c->list;            # 20, 30, 255
    $c->red;             # 20
    $c->green;           # 30
    $c->blue;            # 255
    $c->hash;            # { red => 20, green => 30, blue => 255}


=head1 DESCRIPTION



=head1 OO Interface

=head1 Importable Routines

=head2 hex_from_rgb

=head2 rgb_from_hex

=head1 COPYRIGHT & LICENSE

Copyright 2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut

