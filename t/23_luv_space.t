#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 40;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::LUV';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'CIELUV',                  'color space has right name');
is( $def->axis,              3,                  'color space has 3 dimensions');
is( $def->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $def->is_partial_hash({u => 1, v => 0}), 1,  'found hash with some axis names');
is( $def->is_partial_hash({u => 1, v => 0, l => 0}), 1, 'found hash with all axis names');
is( $def->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with onw wrong axis name');
is( $def->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $def->can_convert('yiq'), 0,                 'can not convert to itself');
is( $def->format([0,0,0], 'css_string'), 'cieluv(0, 0, 0)', 'can format css string');

my $val = $def->deformat(['CIELUV', 1, 0, -0.1]);
is( ref $val,  'ARRAY',  'deformated random value tuple');
is( int @$val,    3,     'right amount of values');
is( $val->[0],    1,     'first value good');
is( $val->[1],    0,     'second value good');
is( $val->[2], -0.1,     'third value good');


exit 0;
