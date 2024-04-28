use v5.12;
use warnings;

# sRGB color space specific code

package Graphics::Toolkit::Color::Space::Instance::RGB;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util ':all';

my $rgb_def = Graphics::Toolkit::Color::Space->new( axis => [qw/red green blue/], range => 255 );
   $rgb_def->add_formatter(   'hex_string',  \&hex_from_rgb );
   $rgb_def->add_deformatter( 'hex_string',  \&rgb_from_hex );
   $rgb_def->add_deformatter( 'array', sub { $_[1] if $rgb_def->is_value_tuple( $_[1] ) } );


sub hex_from_rgb { sprintf("#%02x%02x%02x", @{$_[1]} ) }

sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my ($self, $hex) = @_;
    return "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
        unless defined $hex and not ref $hex
           and (length($hex) == 4 or length($hex) == 7)
           and substr($hex, 0, 1) eq '#' and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    [(length $hex == 3) ? (map { hex($_.$_) } unpack( "a1 a1 a1", $hex))
                        : (map { hex($_   ) } unpack( "a2 a2 a2", $hex))];
}

# defined $_[0] and ($_[0] =~ /^#[[:xdigit:]]{3}$/ or $_[0] =~ /^#[[:xdigit:]]{6}$/)


$rgb_def;
