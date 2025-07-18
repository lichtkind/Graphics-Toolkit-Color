#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 54;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HSV';
use Graphics::Toolkit::Color::Space::Util ':all';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'HSV',                     'color space has initials as name');
is( $def->alias,         '',                     'color space has no alias name');
is( $def->axis,           3,                     'color space has 3 axis');
is( ref $def->check_range([0, 0, 0]),     'ARRAY',   'check HSV values works on lower bound values');
is( ref $def->check_range([360,100,100]), 'ARRAY',   'check HSV values works on upper bound values');
is( ref $def->check_range([0,0]),              '',   "HSV got too few values");
is( ref $def->check_range([0, 0, 0, 0]),       '',   "HSV got too many values");
is( ref $def->check_range([-1, 0, 0]),         '',   "hue value is too small");
is( ref $def->check_range([1.1, 0, 0]),        '',   "hue is not integer");
is( ref $def->check_range([361, 0, 0]),        '',   "hue value is too big");
is( ref $def->check_range([0, -1, 0]),         '',   "saturation value is too small");
is( ref $def->check_range([0, 1.1, 0]),        '',   "saturation value is not integer");
is( ref $def->check_range([0, 101, 0]),        '',   "saturation value is too big");
is( ref $def->check_range([0, 0, -1 ] ),       '',   "value value is too small");
is( ref $def->check_range([0, 0, 1.1] ),       '',   "value value is not integer");
is( ref $def->check_range([0, 0, 101] ),       '',   "value value is too big");


my $hsv = $def->clamp([]);
is( int @$hsv,   3,     'clamp added three missing values as zero');
is( $hsv->[0],   0,     'default color is black (H)');
is( $hsv->[1],   0,     'default color is black (S)');
is( $hsv->[2],   0,     'default color is black (V)');
$hsv = $def->clamp([0,100]);
is( int @$hsv,   3,     'added one missing value');
is( $hsv->[0],   0,     'carried first min value');
is( $hsv->[1], 100,     'carried second max value');
is( $hsv->[2],   0,     'set missing color value to zero (V)');
$hsv = $def->clamp([-1.1,-1,101,4]);
is( int @$hsv,   3,     'removed superfluous value');
is( $hsv->[0], 358.9,     'rotated up (H) value and removed decimals');
is( $hsv->[1],   0,     'clamped up too small (S) value');
is( $hsv->[2], 100,     'clamped down too large (V) value');;

$hsv = $def->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is( int @$hsv,   3,     'converted color grey has three hsv values');
is( $hsv->[0],   0,     'converted color grey has computed right hue value');
is( $hsv->[1],   0,     'converted color grey has computed right saturation');
is( $hsv->[2],  0.5,     'converted color grey has computed right value');

my $rgb = $def->convert_to( 'RGB', [0, 0, 0.5]);
is( int @$rgb,  3,     'converted back color grey has three rgb values');
is( $rgb->[0], 0.5,     'converted back color grey has right red value');
is( $rgb->[1], 0.5,     'converted back color grey has right green value');
is( $rgb->[2], 0.5,     'converted back color grey has right blue value');

$rgb = $def->convert_to( 'RGB', [0.972222222, 0.9, 0.78]);
is( int @$rgb,  3,     'converted red color into tripled');
is( $rgb->[0], 0.78,    'right red value');
is( $rgb->[1], 0.078,   'right green value');
is( close_enough($rgb->[2], 0.196), 1,    'right blue value');

$hsv = $def->convert_from( 'RGB', [0.78, 0.078, 0.196078431]);
is( int @$hsv,  3,      'converted nice blue has three hsv values');
is( close_enough($hsv->[0], 0.97222), 1, 'converted nice blue has computed right hue value');
is( $hsv->[1],  .9,      'converted nice blue has computed right saturation');
is( $hsv->[2],  .78,     'converted nice blue has computed right value');

$rgb = $def->convert_to( 'RGB', [0.76666, .83, .24]);
is( int @$rgb,  3,     'converted red color into tripled');
is( close_enough($rgb->[0], 0.156862), 1,   'right red value');
is( close_enough($rgb->[1], 0.03921),  1,   'right green value');
is( close_enough($rgb->[2], 0.2352),   1,   'right blue value');

$hsv = $def->convert_from( 'RGB', [40/255, 10/255, 60/255]);
is( int @$hsv,                         3, 'converted nice blue has three hsv values');
is( close_enough($hsv->[0], 0.766666), 1, 'converted nice blue has computed right hue value');
is( close_enough($hsv->[1],  .83),     1, 'converted nice blue has computed right saturation');
is( close_enough($hsv->[2],  .24),     1, 'converted nice blue has computed right value');

exit 0;
