#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 28;
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

my $hhki = \&Graphics::Toolkit::Color::Util::has_hash_key_initials;
is( $hhki->([c=>1, m=>1, y=>1, k=>1], {c=>1, m=>1, y=>1}, ),         0,     'def is nt a hash');
is( $hhki->({c=>1, m=>1, y=>1, k=>1}, [c=>1, m=>1, y=>1, k => 1], ), 0,     'values are not in a hash');
is( $hhki->({c=>1, m=>1, y=>1, k=>1}, {c=>1, m=>1, y=>1}, ),         0,     'different key count');
is( $hhki->({r=>1, g=>2, b=>3}, {r=>1, g=>2, b=>3}, ),               1,     'same 3 keys');
is( $hhki->({r=>1, g=>1, b=>1}, {r=>1, g=>2, b=>3}, ),               1,     'key values are ignored');
is( $hhki->({r=>1, g=>2, b=>3}, {R=>1, G=>1, B=>1}, ),               1,     'casing gets ignored');
is( $hhki->({r=>1, g=>2, b=>3}, {Red=>1, Green=>1, Blue=>1}, ),      1,     'words get condensed to first char');
is( $hhki->({c=>1, m=>1, y=>1, k=>1}, {c=>1, m=>1, y=>1, k=>1}, ),   1,     'same 4 keys');

my $ehv = \&Graphics::Toolkit::Color::Util::extract_hash_values;
is( $ehv->([c=>1, m=>1, y=>1, k=>1], {c=>1, m=>1, y=>1}, ),         0,     'def is nt a hash');
is( $ehv->({c=>1, m=>1, y=>1, k=>1}, [c=>1, m=>1, y=>1, k => 1], ), 0,     'values are not in a hash');

my $rgb = $ehv->({r=>0, g=>1, b=>2}, {Red =>100, Green =>200, Blue =>300}, );
is( ref $rgb, 'ARRAY',    'found values in RGB hash');
is( int @$rgb, 3,         'got three values extracted');
is( int $rgb->[0], 100,   'got first value right');
is( int $rgb->[1], 200,   'got second value right');
is( int $rgb->[2], 300,   'got third value right');

my $cmyk = $ehv->({c=>0, m=>1, y=>2, k=> 3}, {c=>100, m=>200, y=>300, Key => 400}, );
is( ref $cmyk, 'ARRAY',    'found values in CMYK hash');
is( int @$cmyk, 4,         'got three values extracted');
is( int $cmyk->[0], 100,   'got first value right');
is( int $cmyk->[1], 200,   'got second value right');
is( int $cmyk->[2], 300,   'got third value right');
is( int $cmyk->[3], 400,   'got fourth value right');

exit 0;
