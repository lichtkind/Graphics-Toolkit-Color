#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 40;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::YUV';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'YUV',                     'color space has initials as name');
is( $def->alias,         '',                     'color space has no alias name');
is( $def->axis,           3,                     'color space has 3 axis');
is( ref $def->range_check([0, 0, 0]),              'ARRAY',   'check neutral YIQ values are in bounds');
is( ref $def->range_check([0, -0.5959, 0.5227]),   'ARRAY',   'check YIQ values works on lower bound values');
is( ref $def->range_check([1, 0.5959, 0.5227]),    'ARRAY',   'check YIQ values works on upper bound values');
is( ref $def->range_check([0,0]),              '',   "YIQ got too few values");
is( ref $def->range_check([0, 0, 0, 0]),       '',   "YIQ got too many values");
is( ref $def->range_check([-1, 0, 0]),         '',   "luminance value is too small");
is( ref $def->range_check([1.1, 0, 0]),        '',   "luminance value is too big");
is( ref $def->range_check([0, -1, 0]),         '',   "in_phase value is too small");
is( ref $def->range_check([0, 1, 0]),          '',   "in_phase value is too big");
is( ref $def->range_check([0, 0, -1 ] ),       '',   "quadrature value is too small");
is( ref $def->range_check([0, 0, 1] ),         '',   "quadrature value is too big");


is( $def->is_value_tuple([0,0,0]),           1,   'value vector has 3 elements');
is( $def->is_partial_hash({i => 1, quadrature => 0}), 1, 'found hash with some keys');
is( $def->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $def->can_convert('yiq'), 0,                 'can not convert to itself');
is( $def->format([0,0,0], 'css_string'), 'yiq(0, 0, 0)', 'can format css string');

my $val = $def->deformat(['YIQ', 1, 0, -0.1]);
is( int @$val,    3,  'deformated value triplet (vector)');
is( $val->[0],    1,  'first value good');
is( $val->[1],    0,  'second value good');
is( $val->[2], -0.1,  'third value good');


my $yiq = $def->deconvert( [ 0.5, 0.5, 0.5], 'RGB');
is( int @$yiq,  3,     'converted color grey has three YIQ values');
is( $yiq->[0], 0.5,     'converted color grey has computed right luminance value');
is( $yiq->[1], 0.5,  'converted color grey has computed right in-phase');
is( $yiq->[2], 0.5,  'converted color grey has computed right quadrature');

my $rgb = $def->convert( [0.5, 0.5, 0.5], 'RGB');
is( int @$rgb,  3,     'converted back color grey has three rgb values');
is( $rgb->[0],   0.5,   'converted back color grey has right red value');
is( $rgb->[1],   0.5,   'converted back color grey has right green value');
is( $rgb->[2],   0.5,   'converted back color grey has right blue value');

$yiq = $def->deconvert( [0.1, 0, 1], 'RGB');
is( int @$yiq,  3,     'converted blue has three YIQ values');
is( close_enough( $yiq->[0], 0.1439 )    ,  1 ,  'converted nice blue has right Y value');
is( close_enough( $yiq->[1], 0.280407787),  1 ,  'converted nice blue has right I value');
is( close_enough( $yiq->[2], 0.817916587),  1 ,  'converted nice blue has right Q value');

$rgb = $def->convert( [0.1439, 0.280407787, 0.817916587], 'RGB');
is( int @$rgb,  3,     'converted back nice blue');
is( close_enough($rgb->[0],  0.1), 1,   'right red value');
is( close_enough($rgb->[1],  0  ), 1,   'right green value');
is( close_enough($rgb->[2],  1, ), 1,   'right blue value');

exit 0;
