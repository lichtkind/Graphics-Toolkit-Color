#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 88;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::YUV';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space',  'got tight return value by loading module');
is( $def->name,       'YUV',                      'color space has initials as name');
is( $def->alias,         '',                      'color space has no alias name');
is( $def->axis,           3,                      'color space has 3 axis');
is( ref $def->range_check([0, 0, 0]),  'ARRAY',   'check neutral YUV values are in bounds');
is( ref $def->range_check([0, -0.5, -0.5]), 'ARRAY',   'check YUV values works on lower bound values');
is( ref $def->range_check([1, 0.5, 0.5]),   'ARRAY',   'check YUV values works on upper bound values');
is( ref $def->range_check([0,0]),              '',   "YUV got too few values");
is( ref $def->range_check([0, 0, 0, 0]),       '',   "YUV got too many values");
is( ref $def->range_check([-1, 0, 0]),         '',   "luma value is too small");
is( ref $def->range_check([1.1, 0, 0]),        '',   "luma value is too big");
is( ref $def->range_check([0, -.51, 0]),       '',   "Pb value is too small");
is( ref $def->range_check([0, .51, 0]),        '',   "Pb value is too big");
is( ref $def->range_check([0, 0, -.51] ),      '',   "Pr value is too small");
is( ref $def->range_check([0, 0, 0.51] ),      '',   "Pr value is too big");


is( $def->is_value_tuple([0,0,0]),            1,  'value vector has 3 elements');
is( $def->is_partial_hash({y => 1, Pb => 0}), 1,  'found hash with some keys');
is( $def->can_convert('rgb'), 1,                  'do only convert from and to rgb');
is( $def->can_convert('yuv'), 0,                  'can not convert to itself');
is( $def->format([0,1,2], 'css_string'), 'yuv(0, 1, 2)', 'can format css string');

my $val = $def->deformat(['yuv', 1, 0, -0.1]);
is( int @$val,    3,  'deformated value triplet (vector)');
is( $val->[0],    1,  'first value good');
is( $val->[1],    0,  'second value good');
is( $val->[2], -0.1,  'third value good');


my $yuv = $def->deconvert( [ 0, 0, 0], 'RGB');
is( ref $yuv, 'ARRAY','reconverted black has to be a ARRAY reference');
is( int @$yuv,  3,    'reconverted black has three YUV values');
is( $yuv->[0],  0,    'reconverted black has computed right luma value');
is( $yuv->[1],  0.5,  'reconverted black has computed right Pb');
is( $yuv->[2],  0.5,  'reconverted black has computed right Pr');

$yuv = $def->denormalize( [0, 0.5, 0.5] );
is( ref $yuv, 'ARRAY','denormalized black has to be a ARRAY reference');
is( int @$yuv,  3,    'denormalized black has three YUV values');
is( $yuv->[0],  0,    'denormalized black has computed right luma value');
is( $yuv->[1],  0,    'denormalized black has computed right Pb');
is( $yuv->[2],  0,    'denormalized black has computed right Pr');

$yuv = $def->normalize( [0, 0, 0] );
is( ref $yuv, 'ARRAY','normalized black has to be a ARRAY reference');
is( int @$yuv,  3,    'normalized black has three YUV values');
is( $yuv->[0],  0,    'normalized black has computed right luma value');
is( $yuv->[1],  0.5,  'normalized black has computed right Pb');
is( $yuv->[2],  0.5,  'normalized black has computed right Pr');

my $rgb = $def->convert( [0, 0.5, 0.5], 'RGB');
is( int @$rgb,  3,    'converted black has three rgb values');
is( $rgb->[0],  0,    'converted black has right red value');
is( $rgb->[1],  0,    'converted black has right green value');
is( $rgb->[2],  0,    'converted black has right blue value');


$yuv = $def->deconvert( [ 1, 1, 1], 'RGB');
is( int @$yuv,  3,               'reconverted black has three YUV values');
is( $yuv->[0],  1, 'reconverted black has computed right luma value');
is( $yuv->[1], .5, 'reconverted black has computed right Pb');
is( $yuv->[2], .5, 'reconverted black has computed right Pr');

$yuv = $def->denormalize( [1, 0.5, 0.5] );
is( int @$yuv,  3,    'denormalized white has three YUV values');
is( $yuv->[0],  1,    'denormalized white has computed right luma value');
is( $yuv->[1],  0,    'denormalized white has computed right Pb');
is( $yuv->[2],  0,    'denormalized white has computed right Pr');

$rgb = $def->convert( [1, .5, .5], 'RGB');
is( int @$rgb,  3,    'converted white has three rgb values');
is( $rgb->[0],  1,    'converted white has right red value');
is( $rgb->[1],  1,    'converted white has right green value');
is( $rgb->[2],  1,    'converted white has right blue value');


$yuv = $def->deconvert( [ .5, .5, .5], 'RGB');
is( int @$yuv,  3,                'reconverted gray has three YIQ values');
is( $yuv->[0],  .5, 'reconverted gray has computed right luma value');
is( $yuv->[1],  .5, 'reconverted gray has computed right Pb');
is( $yuv->[2],  .5, 'reconverted gray has computed right Pr');

$yuv = $def->denormalize( [0.5, 0.5, 0.5] );
is( int @$yuv,  3,    'denormalized gray has three YUV values');
is( $yuv->[0],  0.5,  'denormalized gray has computed right luma value');
is( $yuv->[1],  0,    'denormalized gray has computed right Pb');
is( $yuv->[2],  0,    'denormalized gray has computed right Pr');

$yuv = $def->normalize( [0.5, 0, 0] );
is( int @$yuv,  3,    'normalized gray has three YUV values');
is( $yuv->[0],  0.5,  'normalized gray has computed right luma value');
is( $yuv->[1],  0.5,  'normalized gray has computed right Pb');
is( $yuv->[2],  0.5,  'normalized gray has computed right Pr');

$rgb = $def->convert( [.5, .5, .5], 'RGB');
is( int @$rgb,  3,    'converted white has three rgb values');
is( $rgb->[0], .5,    'converted white has right red value');
is( $rgb->[1], .5,    'converted white has right green value');
is( $rgb->[2], .5,    'converted white has right blue value');


$yuv = $def->deconvert( [ 0.11, 0, 1], 'RGB');
is( int @$yuv,  3,                'reconverted nice blue has three YUV values');
ok( close_enough( $yuv->[0], 0.15),    'reconverted nice blue has computed right luma value');
ok( close_enough( $yuv->[1], 0.48+0.5),  'reconverted nice blue has computed right Pb');
ok( close_enough( $yuv->[2], -0.03+0.5),  'reconverted nice blue has computed right Pr');

$rgb = $def->convert( [0.14689, 0.48143904+0.5, -0.026312+0.5], 'RGB');
is( int @$rgb,  3,    'converted nice blue color, has three rgb values');
ok( close_enough( $rgb->[0], .11),   'converted nice blue color, has right red value');
ok( close_enough( $rgb->[1],  0),    'converted nice blue color, has right green value');
ok( close_enough( $rgb->[2],  1),    'converted nice blue color, has right blue value');

$yuv = $def->deconvert( [ 0.8156, 0.0470588, 0.137254], 'RGB');
is( int @$yuv,  3,                'reconverted nice red has three YUV values');
ok( close_enough( $yuv->[0],  0.2871),    'reconverted nice red has computed right luma value');
ok( close_enough( $yuv->[1], -0.0846+0.5),  'reconverted nice red has computed right Pb');
ok( close_enough( $yuv->[2],  0.3769+0.5),  'reconverted nice red has computed right Pr');

$rgb = $def->convert( [0.2871, -0.0846+0.5, 0.3769+0.5], 'RGB');
is( int @$rgb,  3,    'converted nice blue color, has three rgb values');
ok( close_enough( $rgb->[0], 0.8156),    'converted red blue color, has right red value');
ok( close_enough( $rgb->[1], 0.04705),    'converted red blue color, has right green value');
ok( close_enough( $rgb->[2], 0.137254),    'converted red blue color, has right blue value');

exit 0;
