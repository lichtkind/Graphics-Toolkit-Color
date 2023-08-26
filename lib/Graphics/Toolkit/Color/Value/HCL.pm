use v5.12;
use warnings;

# check, convert and measure color values in HCL space

package Graphics::Toolkit::Color::Value::HCL;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hwb_def = Graphics::Toolkit::Color::Space->new(axis => [qw/hue chroma luminance/],
                                                  range => [360, 100, 100]);
   $hwb_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub from_rgb {
    my (@rgb) = @_;

}


sub to_rgb {
    my (@hcl) = @_;

}

$hwb_def;
