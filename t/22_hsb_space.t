#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 54;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HSB';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'HSB',                     'color space has initials as name');
is( $def->alias,         '',                     'color space has no alias name');
is( $def->axis_count,     3,                     'color space has 3 axis');
is( ref $def->check_range([0, 0, 0]),     'ARRAY',   'check HSB values works on lower bound values');
is( ref $def->check_range([360,100,100]), 'ARRAY',   'check HSB values works on upper bound values');
is( ref $def->check_range([0,0]),              '',   "HSB got too few values");
is( ref $def->check_range([0, 0, 0, 0]),       '',   "HSB got too many values");
is( ref $def->check_range([-1, 0, 0]),         '',   "hue value is too small");
is( ref $def->check_range([1.1, 0, 0]),        '',   "hue is not integer");
is( ref $def->check_range([361, 0, 0]),        '',   "hue value is too big");
is( ref $def->check_range([0, -1, 0]),         '',   "saturation value is too small");
is( ref $def->check_range([0, 1.1, 0]),        '',   "saturation value is not integer");
is( ref $def->check_range([0, 101, 0]),        '',   "saturation value is too big");
is( ref $def->check_range([0, 0, -1 ] ),       '',   "brightness value is too small");
is( ref $def->check_range([0, 0, 1.1] ),       '',   "brightness value is not integer");
is( ref $def->check_range([0, 0, 101] ),       '',   "brightness value is too big");

my $hsb = $def->clamp([]);
is( int @$hsb,   3,     'clamp added three missing values as zero');
is( $hsb->[0],   0,     'default color is black (H)');
is( $hsb->[1],   0,     'default color is black (S)');
is( $hsb->[2],   0,     'default color is black (B)');
$hsb = $def->clamp([0,100]);
is( int @$hsb,  3,     'added one missing value');
is( $hsb->[0],   0,     'carried first min value');
is( $hsb->[1], 100,     'carried second max value');
is( $hsb->[2],   0,     'set missing color value to zero (B)');
$hsb = $def->clamp([-1.1,-1,101,4]);
is( int @$hsb,  3,     'removed superfluous value');
is( $hsb->[0], 358.9,     'rotated up (H) value and removed decimals');
is( $hsb->[1],   0,     'clamped up too small (S) value');
is( $hsb->[2], 100,     'clamped down too large (B) value');;


$hsb = $def->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is( int @$hsb,  3,     'converted color grey has three hsb values');
is( $hsb->[0],   0,     'converted color grey has computed right hue value');
is( $hsb->[1],   0,     'converted color grey has computed right saturation');
is( $hsb->[2],  0.5,     'converted color grey has computed right brightness');

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

$hsb = $def->convert_from( 'RGB', [0.78, 0.078, 0.196078431]);
is( int @$hsb,  3,      'converted nice blue has three hsb values');
is( close_enough($hsb->[0], 0.97222), 1, 'converted nice blue has computed right hue value');
is( $hsb->[1],  .9,      'converted nice blue has computed right saturation');
is( $hsb->[2],  .78,     'converted nice blue has computed right brightness');

$rgb = $def->convert_to( 'RGB', [0.76666, .83, .24]);
is( int @$rgb,  3,     'converted red color into tripled');
is( close_enough($rgb->[0], 0.156862), 1,   'right red value');
is( close_enough($rgb->[1], 0.03921),  1,   'right green value');
is( close_enough($rgb->[2], 0.2352),   1,   'right blue value');

$hsb = $def->convert_from( 'RGB', [40/255, 10/255, 60/255]);
is( int @$hsb,  3,      'converted nice blue has three hsb values');
is( close_enough($hsb->[0], 0.766666), 1, 'converted nice blue has computed right hue value');
is( close_enough($hsb->[1],  .83),     1, 'converted nice blue has computed right saturation');
is( close_enough($hsb->[2],  .24),     1, 'converted nice blue has computed right brightness');

exit 0;
