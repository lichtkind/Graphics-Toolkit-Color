use v5.12;
use warnings;

# check, convert and measure color values in RGB space

package Graphics::Toolkit::Color::Value::RGB;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $rgb_def = Graphics::Toolkit::Color::Space->new(qw/red green blue/);
   $rgb_def->add_format( 'hex', \&hex_from_rgb );

########################################################################

sub check_rgb { &check }
sub check { # carp returns 1
    my (@rgb) = @_;
    my $range_help = 'has to be an integer between 0 and 255';
    return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless @rgb == $rgb_def->dimensions;
    return carp "red value $rgb[0] ".$range_help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    return carp "green value $rgb[1] ".$range_help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    return carp "blue value $rgb[2] ".$range_help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    0;
}

sub trim_rgb { &trim }
sub trim { # cut values into the domain of definition of 0 .. 255
    my (@rgb) = @_;
    for ($rgb_def->iterator){
        $rgb[$_] =   0 unless exists $rgb[$_];
        $rgb[$_] =   0 if $rgb[$_] <   0;
        $rgb[$_] = 255 if $rgb[$_] > 255;
    }
    $rgb[$_] = round($rgb[$_]) for $rgb_def->iterator;
    pop @rgb until @rgb == $rgb_def->dimensions;
    @rgb;
}

sub delta_rgb { &delta }
sub delta { # \@rgb, \@rgb --> @rgb             distance as vector
    my ($rgb, $rgb2) = @_;
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb differences"
        unless ref $rgb eq 'ARRAY' and @$rgb == $rgb_def->dimensions
           and ref $rgb2 eq 'ARRAY' and @$rgb2 == $rgb_def->dimensions;
    check( @$rgb ) and return;
    check( @$rgb2 ) and return;
    (abs($rgb->[0] - $rgb2->[0]), abs($rgb->[1] - $rgb2->[1]), abs($rgb->[2] - $rgb2->[2]) );
}

sub distance_rgb { &distance }
sub distance { # \@rgb, \@rgb --> $d
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb distance " if @_ != 2;
    my @delta_rgb = delta( $_[0], $_[1] );
    return unless @delta_rgb == $rgb_def->dimensions;
    sqrt($delta_rgb[0] ** 2 + $delta_rgb[1] ** 2 + $delta_rgb[2] ** 2);
}


sub hex_from_rgb {  return unless @_ == $rgb_def->dimensions;  sprintf "#%02x%02x%02x", @_ }

sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my $hex = shift;
    return carp "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
    unless defined $hex and (length($hex) == 4 or length($hex) == 7) and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    (length $hex == 3) ? (map { CORE::hex($_.$_) } unpack( "a1 a1 a1", $hex))
                       : (map { CORE::hex($_   ) } unpack( "a2 a2 a2", $hex));
}

sub is_hex { defined $_[0] and ($_[0] =~ /^#[[:alnum:]]{3}$/ or $_[0] =~ /^#[[:alnum:]]{6}$/)}

$rgb_def;
