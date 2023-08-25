use v5.12;
use warnings;

# check, convert and measure color values in CMYK space

package Graphics::Toolkit::Color::Value::CMYK;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $cmyk_def = Graphics::Toolkit::Color::Space->new( axis => [qw/cyan magenta yellow key/] );
   $cmyk_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub from_rgb {
    my ($r, $g, $b) = @_;
    return unless defined $b;
    my $km = $r > $g ? $r : $g;
    $km = $km > $b ? $km : $b;
    return (0,0,0,1) unless $km; # prevent / 0

    return ( ($km - $r) / $km,
             ($km - $g) / $km,
             ($km - $b) / $km,
                1 - $km
    );
}

sub to_rgb {
    my ($c, $m, $y, $k) = @_;
    return ( (1-$c) * (1-$k) ,
             (1-$m) * (1-$k) ,
             (1-$y) * (1-$k) ,
    );
}

$cmyk_def;
