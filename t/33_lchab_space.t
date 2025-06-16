#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 130;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHab';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELCHab',                  'color space name is CIELCHab');
is( $space->alias,           'LCH',                  'color space name alias nameis LCH');
is( $space->axis,                3,                  'color space has 3 dimensions');

is( ref $space->range_check([0,0]),              '',   "CIELCHab got too few values");
is( ref $space->range_check([0, 0, 0, 0]),       '',   "CIELCHab got too many values");
is( ref $space->range_check([0, 0, 0]),          'ARRAY',   'check minimal CIELCHab values are in bounds');
is( ref $space->range_check([100, 539, 360]),    'ARRAY',   'check maximal CIELCHab values are in bounds');
is( ref $space->range_check([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->range_check([100.01, 0, 0]),     '',   'L value is too big');
is( ref $space->range_check([0, -0.1, 0]),       '',   "c value is too small");
is( ref $space->range_check([0, 539.1, 0]),      '',   'c value is too big');
is( ref $space->range_check([0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->range_check([0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert('CIELAB'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('CieLab'), 1,                 'namespace can be written lower case');
is( $space->can_convert('CIELCHab'), 0,               'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cielchab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELCHab', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cielchab(0, 1, 0)', 'can format css string');


exit 0;
