#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 7;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Util';

eval "use $module";
is( not($@), 1, 'could load the module');

my $round = \&Graphics::Toolkit::Color::Util::round;
is( $round->(0.5),           1,     'round 0.5 upward');
is( $round->(0.500000001),   1,     'everything above 0.5 gets also increased');
is( $round->(0.4999999),     0,     'everything below 0.5 gets smaller');
is( $round->(-0.5),         -1,     'round -0.5 downward');
is( $round->(-0.500000001), -1,     'everything beow -0.5 gets also lowered');
is( $round->(-0.4999999),    0,     'everything upward from -0.5 gets increased');

exit 0;
