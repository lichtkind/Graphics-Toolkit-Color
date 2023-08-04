use v5.12;
use warnings;

# check, convert and measure color values in RGB space

package Graphics::Toolkit::Color::Value::RGB;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $rgb_def = Graphics::Toolkit::Color::Space->new(qw/red green blue/);
   $rgb_def->add_formatter(   'hex',   \&hex_from_rgb );
   $rgb_def->add_deformatter( 'hex',   sub { rgb_from_hex(@_) if is_hex(@_) } );
   $rgb_def->add_deformatter( 'array', sub { @{$_[0]} if $rgb_def->is_array($_[0]) } );

########################################################################

sub check { # carp returns 1
    my (@rgb) = @_;
    my $range_help = 'has to be an integer between 0 and 255';
    return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless $rgb_def->is_array( \@rgb );
    return carp "red value $rgb[0] ".$range_help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    return carp "green value $rgb[1] ".$range_help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    return carp "blue value $rgb[2] ".$range_help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    0;
}

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

sub delta { # \@rgb, \@rgb --> @rgb             distance as vector
    my ($rgb1, $rgb2) = @_;
    return carp  "need two triplets of rgb values in 2 arrays to compute rgb differences"
        unless $rgb_def->is_array( $rgb1 ) and $rgb_def->is_array( $rgb2 );
    check( @$rgb1 ) and return;
    check( @$rgb2 ) and return;
    (abs($rgb1->[0] - $rgb2->[0]), abs($rgb1->[1] - $rgb2->[1]), abs($rgb1->[2] - $rgb2->[2]) );
}

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

sub is_hex { defined $_[0] and ($_[0] =~ /^#[[:xdigit:]]{3}$/ or $_[0] =~ /^#[[:xdigit:]]{6}$/)}


$rgb_def;
