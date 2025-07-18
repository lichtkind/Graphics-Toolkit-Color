#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 52;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HSL';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util 'close_enough';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'HSL',                     'color space has initials as name');
is( $def->alias,         '',                     'color space has no alias name');
is( $def->axis,           3,                     'color space has 3 axis');
is( ref $def->check_range( [0, 0, 0]),     'ARRAY',   'check HSL values works on lower bound values');
is( ref $def->check_range( [360,100,100]), 'ARRAY',   'check HSL values works on upper bound values');
is( ref $def->check_range( [0,0]),              '',   "HSL got too few values");
is( ref $def->check_range( [0, 0, 0, 0]),       '',   "HSL got too many values");
is( ref $def->check_range( [-1, 0, 0]),         '',   "hue value is too small");
is( ref $def->check_range( [1.1, 0, 0]),        '',   "hue is not integer");
is( ref $def->check_range( [361, 0, 0]),        '',   "hue value is too big");
is( ref $def->check_range( [0, -1, 0]),         '',   "saturation value is too small");
is( ref $def->check_range( [0, 1.1, 0]),        '',   "saturation value is not integer");
is( ref $def->check_range( [0, 101, 0]),        '',   "saturation value is too big");
is( ref $def->check_range( [0, 0, -1 ] ),       '',  "lightness value is too small");
is( ref $def->check_range( [0, 0, 1.1] ),       '',  "lightness value is not integer");
is( ref $def->check_range( [0, 0, 101] ),       '',  "lightness value is too big");


my $hsl = $def->clamp([]);
is( int @$hsl,   3,     'missing values are clamped to black (default color)');
is( $hsl->[0],   0,     'default color is black (H)');
is( $hsl->[1],   0,     'default color is black (S)');
is( $hsl->[2],   0,     'default color is black (L)');

$hsl = $def->clamp([0,100]);
is( int @$hsl,   3,     'clamp added missing value');
is( $hsl->[0],   0,     'carried first min value (H)');
is( $hsl->[1], 100,     'carried second max value (S)');
is( $hsl->[2],   0,     'set missing value to zero');

$hsl = $def->clamp( [-1, -1, 101, 4]);
is( int @$hsl,     3,     'clamp removed superfluous value');
is( $hsl->[0],   359,     'rotated up (H) value');
is( $hsl->[1],     0,     'clamped up (S) value');
is( $hsl->[2],   100,    'clamped down(L) value');;


$hsl = $def->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is( int @$hsl,   3,     'converted color grey has three hsl values');
is( $hsl->[0],   0,     'converted color grey has computed right hue value');
is( $hsl->[1],   0,     'converted color grey has computed right saturation');
is( $hsl->[2],  0.5,    'converted color grey has computed right lightness');

my $rgb = $def->convert_to( 'RGB', [0, 0, 0.5]);
is( int @$rgb,   3,     'converted back color grey has three rgb values');
is( $rgb->[0], 0.5,     'converted back color grey has right red value');
is( $rgb->[1], 0.5,     'converted back color grey has right green value');
is( $rgb->[2], 0.5,     'converted back color grey has right blue value');

$hsl = $def->convert_from( 'RGB', [0.00784, 0.7843, 0.0902]);
is( int @$hsl,  3,     'converted blue color has three hsl values');
is( close_enough($hsl->[0], 0.35097493), 1, 'converted color blue has computed right hue value');
is( close_enough($hsl->[1], 0.98),       1, 'converted color blue has computed right saturation');
is( close_enough($hsl->[2], 0.4),        1, 'converted color blue has computed right lightness');

$rgb = $def->convert_to( 'RGB', [0.351011, 0.980205, 0.39607]);
is( int @$rgb,  3,     'converted back color grey has three rgb values');
is( close_enough($rgb->[0], 0.00784), 1,  'converted back color grey has right red value');
is( close_enough($rgb->[1], 0.7843),  1,  'converted back color grey has right green value');
is( close_enough($rgb->[2], 0.0902),  1,  'converted back color grey has right blue value');

my $d = $def->delta([0.3,0.3,0.3],[0.3,0.4,0.2]);
is( int @$d,   3,      'delta vector has right length');
is( $d->[0],    0,      'no delta in hue component');
is( $d->[1],    0.1,    'positive delta in saturation component');
is( $d->[2],   -0.1,    'negatve delta in lightness component');

$d = $def->delta([0.9,0,0],[0.1,0,0]);
is( $d->[0],   .2,      'negative delta across the cylindrical border');
$d = $def->delta([0.3,0,0],[0.9,0,0]);
is( $d->[0],  -.4,      'negative delta because cylindrical quality of dimension');

exit 0;
