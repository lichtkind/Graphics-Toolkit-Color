#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 46;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::CMY';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $def->name,       'CMY',                     'color space has right name');
is( $def->axis,           3,                     'CMY color space has 3 axis');

is( ref $def->range_check([0,0,0]),    'ARRAY',   'check CMY values works on lower bound values');
is( ref $def->range_check([1, 1, 1]),  'ARRAY',   'check CMY values works on upper bound values');
is( ref $def->range_check([0,0]),           '',   "CMY got too few values");
is( ref $def->range_check([0, 0, 0, 0]),    '',   "CMY got too many values");
is( ref $def->range_check([-1, 0, 0]),      '',   "cyan value is too small");
is( ref $def->range_check([2, 0, 0]),       '',   "cyan value is too big");
is( ref $def->range_check([0, -1, 0]),      '', "magenta value is too small");
is( ref $def->range_check([0, 2, 0]),       '', "magenta value is too big");
is( ref $def->range_check([0, 0, -1 ] ),    '',  "yellow value is too small");
is( ref $def->range_check([0, 0, 2] ),      '',  "yellow value is too big");


my $cmy = $def->clamp([]);
is( int @$cmy,   3,     'default color is set by clamp');
is( $cmy->[0],   0,     'default color is black (C) no args');
is( $cmy->[1],   0,     'default color is black (M) no args');
is( $cmy->[2],   0,     'default color is black (Y) no args');

$cmy = $def->clamp([0, 1]);
is( int @$cmy,   3,     'clamp added missing argument in vector');
is( $cmy->[0],   0,     'passed (C) value');
is( $cmy->[1],   1,     'passed (M) value');
is( $cmy->[2],   0,     'added (Y) value when too few args');

$cmy = $def->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is( ref $cmy,   'ARRAY',  'clamped tuple and got tuple back');
is( int @$cmy,   3,     'removed missing argument in value vector by clamp');
is( $cmy->[0],   0,     'clamped up  (C) value to minimum');
is( $cmy->[1],   1,     'clamped down (M) value to maximum');
is( $cmy->[2],  0.5,    'passed (Y) value');


$cmy = $def->deconvert( [0, 0.1, 1], 'RGB');
is( ref $cmy,   'ARRAY',  'converted RGB values tuple into CMY tuple');
is( int @$cmy,   3,     'converted RGB values to CMY');
is( $cmy->[0],   1,      'converted to maximal cyan value');
is( $cmy->[1],   0.9,    'converted to mid magenta value');
is( $cmy->[2],   0,      'converted to minimal yellow value');

my ($rgb, $name) = $def->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

$rgb = $def->convert( [1, 0.9, 0 ], 'RGB');
is( ref $rgb,  'ARRAY',  'converted CMY values tuple into RGB tuple');
is( int @$rgb,   3,      'converted CMY to RGB triplets');
is( $rgb->[0],   0,      'converted red value');
is( $rgb->[1],   0.1,    'converted green value');
is( $rgb->[2],   1,      'converted blue value');


my $d = $def->delta([.2,.2,.2],[.2,.2,.2]);
is( int @$d,    3,      'zero delta vector has right length');
is( $d->[0],    0,      'no delta in C component');
is( $d->[1],    0,      'no delta in M component');
is( $d->[2],    0,      'no delta in Y component');

$d = $def->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is( int @$d,   3,      'delta vector has right length');
is( $d->[0],  -0.1,     'C delta');
is( $d->[1],   0.3,     'M delta');
is( $d->[2],   0.6,     'Y delta');



exit 0;
