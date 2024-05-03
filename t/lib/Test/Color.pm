use v5.12;
use warnings;

# utilities for any sub module of the distribution

package Test::Color;

use Exporter 'import';
our @EXPORT_OK = qw/close_enough/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

my $half      = 0.50000000000008;
my $tolerance = 0.00000000000008;


sub close_enough { abs($_[0] - $_[1]) < 0.008 if defined $_[1]}


1;
