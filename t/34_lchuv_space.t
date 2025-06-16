#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 130;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHuv';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELCHuv',                  'color space name is CIELCHuv');
is( $space->alias,              '',                  'color space has no alias name');
is( $space->axis,                3,                  'color space has 3 dimensions');

is( ref $space->range_check([0,0]),              '',   "CIELCHuv got too few values");
is( ref $space->range_check([0, 0, 0, 0]),       '',   "CIELCHuv got too many values");
is( ref $space->range_check([0, 0, 0]),          'ARRAY',   'check minimal CIELCHuv values are in bounds');
is( ref $space->range_check([100, 261, 360]),    'ARRAY',   'check maximal CIELCHuv values are in bounds');
is( ref $space->range_check([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->range_check([100.01, 0, 0]),     '',   'L value is too big');
is( ref $space->range_check([0, -0.1, 0]),       '',   "c value is too small");
is( ref $space->range_check([0, 261.1, 0]),      '',   'c value is too big');
is( ref $space->range_check([0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->range_check([0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert('CIELUV'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('cieLuv'), 1,                 'namespace can be written lower case');
is( $space->can_convert('CIELCHuv'), 0,               'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cielchuv(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELCHuv', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cielchuv(0, 1, 0)', 'can format css string');


# black
$val = $space->denormalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'denormalized black into zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'L value is good');
is( close_enough( $val->[1] , 0),      1,  'C value is good');
is( close_enough( $val->[2] , 0),      1,  'H value is good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'L value is good');
is( close_enough( $val->[1] , 0),      1,  'C value is good');
is( close_enough( $val->[2] , 0),      1,  'H value is good');

my $lch = $space->deconvert( [ 0, .378531073, .534351145], 'CIELUV');
is( ref $lch,                    'ARRAY',  'deconverted black from CIELUV');
is( int @$lch,                         3,  'right amount of values');
is( close_enough( $lch->[0] , 0),      1,  'L value is good');
is( close_enough( $lch->[1] , 0),      1,  'C value is good');
is( close_enough( $lch->[2] , 0),      1,  'H value is good');

my $luv = $space->convert( [ 0, 0, 0 ], 'CIELUV');
is( ref $luv,                    'ARRAY',  'converted black to CIELUV');
is( int @$luv,                             3,  'right amount of values');
is( close_enough( $luv->[0] , 0),          1,  'L* value is good');
is( close_enough( $luv->[1] , .378531073), 1,  'u* value is good');
is( close_enough( $luv->[2] , .534351145), 1,  'v* value is good');


# white
$val = $space->denormalize( [1, 0, 0] );
is( int @$val,                          3,  'denormalized white');
is( close_enough( $val->[0] , 100),     1,  'L value of white is good');
is( close_enough( $val->[1] , 0),       1,  'C value of white is good');
is( close_enough( $val->[2] , 0),       1,  'H value of white is good');

$val = $space->normalize( [100, 0, 0] );
is( int @$val,                               3,  'normalized white');
is( close_enough( $val->[0] , 1),            1,  'L value is good');
is( close_enough( $val->[1] , 0),            1,  'C value is good');
is( close_enough( $val->[2] , 0),            1,  'H value is good');

$lch = $space->deconvert( [ 1, .378531073, .534351145], 'CIELUV');
is( int @$lch,                         3,  'deconverted white from CIELUV');
is( close_enough( $lch->[0] , 1),      1,  'L value is good');
is( close_enough( $lch->[1] , 0),      1,  'C value is good');
is( close_enough( $lch->[2] , 0),      1,  'H value is good');

$luv = $space->convert( [ 1, 0, 0 ], 'CIELUV');
is( int @$luv,                             3,  'converted white to CIELUV');
is( close_enough( $luv->[0] , 1),          1,  'L value is good');
is( close_enough( $luv->[1] , .378531073), 1,  'u value is good');
is( close_enough( $luv->[2] , .534351145), 1,  'v value is good');


# gray
$val = $space->denormalize( [.53389, 0, .686386111] );
is( int @$val,                          3,  'denormalized gray');
is( close_enough( $val->[0] , 53.389),  1,  'L value is good');
is( close_enough( $val->[1] , 0),       1,  'C value is good');
is( close_enough( $val->[2] , 247.099), 1,  'H value is good');

$val = $space->normalize( [53.389, 0, 247.099] );
is( int @$val,                              3,  'normalized gray');
is( close_enough( $val->[0] , .53389),      1,  'L value good');
is( close_enough( $val->[1] , 0),           1,  'C value good');
is( close_enough( $val->[2] , 0.686386111), 1,  'H value good');

$lch = $space->deconvert( [ .53389, .378531073, .534351145], 'CIELUV');
is( int @$lch,                         3,  'deconverted gray from CIELUV');
is( close_enough( $lch->[0] , .53389), 1,  'L value is good');
is( close_enough( $lch->[1] , 0),      1,  'C value is good');
is( close_enough( $lch->[2] , 0),      1,  'H value is good');

$luv = $space->convert( [ .53389, 0, 0.686386111 ], 'CIELUV');
is( int @$luv,                         3,  'converted gray to CIELUV');
is( close_enough( $luv->[0] , .53389),      1,  'L value is good');
is( close_enough( $luv->[1] , .378531073),  1,  'u value is good');
is( close_enough( $luv->[2] , .534351145),  1,  'v value is good');

# red
$val = $space->denormalize( [.53389, 0.685980843, .033816667] );
is( int @$val,                          3,  'denormalized red');
is( close_enough( $val->[0] , 53.389),     1,  'L value is good');
is( close_enough( $val->[1] , 179.041),       1,  'C value is good');
is( close_enough( $val->[2] , 12.174), 1,  'H value is good');

$val = $space->normalize( [53.389, 179.041, 12.174] );
is( int @$val,                         3,  'normalized red');
is( close_enough( $val->[0] , .53389),      1,  'L value good');
is( close_enough( $val->[1] , 0.685980843),      1,  'C value good');
is( close_enough( $val->[2] , 0.033816667),    1,  'H value good');

$lch = $space->deconvert( [ .53389, .872923729, .678458015], 'CIELUV');
is( int @$lch,                         3,  'deconverted red from CIELUV');
is( close_enough( $lch->[0] , .53389), 1,  'L value good');
is( close_enough( $lch->[1] , 0.685980843),      1,  'C value good');
is( close_enough( $lch->[2] , 0.033816667),      1,  'H value good');

$luv = $space->convert( [ .53389, 0.685980843, .033816667 ], 'CIELUV');
is( int @$luv,                         3,  'converted red to CIELUV');
is( close_enough( $luv->[0] , .53389),      1,  'L value good');
is( close_enough( $luv->[1] , .872923729),  1,  'u value good');
is( close_enough( $luv->[2] , .678458015),  1,  'v value good');

# blue
$val = $space->denormalize( [.32297, 0.500693487, .738536111] );
is( int @$val,                          3,  'denormalized blue');
is( close_enough( $val->[0] , 32.297),     1,  'L value is good');
is( close_enough( $val->[1] , 130.681),       1,  'C value is good');
is( close_enough( $val->[2] , 265.873), 1,  'H value is good');

$val = $space->normalize( [32.297, 130.681, 265.873] );
is( int @$val,                         3,  'normalized blue');
is( close_enough( $val->[0] , .32297),      1,  'L value good');
is( close_enough( $val->[1] , 0.500693487),      1,  'C value good');
is( close_enough( $val->[2] , 0.738536111),    1,  'H value good');

$lch = $space->deconvert( [ .32297, .351963277, .036862595], 'CIELUV');
is( int @$lch,                         3,  'deconverted blue from CIELUV');
is( close_enough( $lch->[0] , .32297), 1,  'L value good');
is( close_enough( $lch->[1] , 0.500693487),      1,  'C value good');
is( close_enough( $lch->[2] , 0.738536111),      1,  'H value good');

$luv = $space->convert( [ .32297, 0.500693487, .738536111 ], 'CIELUV');
is( int @$luv,                         3,  'converted blue to CIELUV');
is( close_enough( $luv->[0] , .32297),      1,  'L value good');
is( close_enough( $luv->[1] , .351963277),  1,  'u value good');
is( close_enough( $luv->[2] , .036862595),  1,  'v value good');

# mid blue
$val = $space->denormalize( [.24082, 0.220954023, .724533333] );
is( int @$val,                          3,  'denormalized mid blue');
is( close_enough( $val->[0] , 24.082),     1,  'L value is good');
is( close_enough( $val->[1] , 57.669),       1,  'C value is good');
is( close_enough( $val->[2] , 260.832), 1,  'H value is good');

$val = $space->normalize( [24.082, 57.669, 260.832] );
is( int @$val,                         3,  'normalized mid blue');
is( close_enough( $val->[0] , .24082),      1,  'L value good');
is( close_enough( $val->[1] , 0.220954023),      1,  'C value good');
is( close_enough( $val->[2] , 0.724533333),    1,  'H value good');

$lch = $space->deconvert( [ .24082, .352573446, .317049618], 'CIELUV');
is( int @$lch,                         3,  'deconverted mid blue from CIELUV');
is( close_enough( $lch->[0] , .24082), 1,  'L value good');
is( close_enough( $lch->[1] , 0.220954023),      1,  'C value good');
is( close_enough( $lch->[2] , 0.724533333),      1,  'H value good');

$luv = $space->convert( [ .24082, 0.220954023, .724533333 ], 'CIELUV');
is( int @$luv,                         3,  'converted mid blue to CIELUV');
is( close_enough( $luv->[0] , .24082),      1,  'L value good');
is( close_enough( $luv->[1] , .352573446),  1,  'u value good');
is( close_enough( $luv->[2] , .317049618),  1,  'v value good');

exit 0;
