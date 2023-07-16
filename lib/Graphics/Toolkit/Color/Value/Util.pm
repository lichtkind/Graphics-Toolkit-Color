use v5.12;
use warnings;

# color value computation utilities

package Graphics::Toolkit::Color::Value::Util;

use Exporter 'import';
our @EXPORT_OK = qw/round/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $half = 0.50000000000008;

sub round {
    $_[0] >= 0 ? int ($_[0] + $half)
               : int ($_[0] - $half)
}

1;
