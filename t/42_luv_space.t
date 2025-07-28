#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 148;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELUV';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,          'LUV',                  'color space name is CIELUV');
is( $space->alias,      'CIELUV',                  'color space alias is LUV');
is( $space->axis_count,        3,                  'color space has 3 dimensions');

is( ref $space->check_range([0, 0, 0]),          'ARRAY',   'check minimal CIELUV values are in bounds');
is( ref $space->check_range([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELUV values');
is( ref $space->check_range([0,0]),              '',   "CIELUV got too few values");
is( ref $space->check_range([0, 0, 0, 0]),       '',   "CIELUV got too many values");
is( ref $space->check_range([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_range([100, 0, 0]),   'ARRAY',   'L value is maximal');
is( ref $space->check_range([101, 0, 0]),        '',   "L value is too big");
is( ref $space->check_range([0, -134, 0]),  'ARRAY',   'u value is minimal');
is( ref $space->check_range([0, -134.1, 0]),     '',   "u value is too small");
is( ref $space->check_range([0, 220, 0]),   'ARRAY',   'u value is maximal');
is( ref $space->check_range([0, 220.1, 0]),      '',   "u value is too big");
is( ref $space->check_range([0, 0, -140]),  'ARRAY',   'v value is minimal');
is( ref $space->check_range([0, 0, -140.1 ] ),   '',   "v value is too small");
is( ref $space->check_range([0, 0, 122]),   'ARRAY',   'v value is maximal');
is( ref $space->check_range([0, 0, 122.2] ),     '',   "v value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({u => 1, v => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({u => 1, v => 0, l => 0}), 1, 'found hash with all axis names');
is( $space->is_partial_hash({'L*' => 1, 'u*' => 0, 'v*' => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'CIEXYZ'), 1,                 'do only convert from and to rgb');
is( $space->can_convert( 'ciexyz'), 1,                 'namespace can be written lower case');
is( $space->can_convert( 'CIEluv'), 0,                 'can not convert to itself');
is( $space->can_convert( 'luv'), 0,                    'can not convert to itself (alias)');
is( $space->format([0,0,0], 'css_string'), 'luv(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELUV', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'luv(0, 1, 0)', 'can format css string');

# black
$val = $space->denormalize( [0, .378531073, .534351145] );
is( ref $val,                    'ARRAY',  'denormalized black into zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'L* value of black good');
is( close_enough( $val->[1] , 0),      1,  'u* value of black good');
is( close_enough( $val->[2] , 0),      1,  'v* value of black good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'L value good');
is( close_enough( $val->[1] , 0.378531073),    1,  'u* value good');
is( close_enough( $val->[2] , 0.534351145),    1,  'v* value good');

my $luv = $space->convert_from( 'CIEXYZ', [ 0, 0, 0]);
is( ref $luv,                    'ARRAY',  'deconverted tuple of zeros (black) from CIEXYZ');
is( int @$luv,                         3,  'right amount of values');
is( close_enough( $luv->[0] , 0),                1,  'first value good');
is( close_enough( $luv->[1] , 0.378531073),      1,  'second value good');
is( close_enough( $luv->[2] , 0.534351145),      1,  'third value good');

my $xyz = $space->convert_to( 'CIEXYZ', [ 0, .378531073, .534351145 ]);
is( ref $xyz,                    'ARRAY',  'converted black to CIEXYZ');
is( int @$xyz,                         3,  'right amount of values');
is( close_enough( $xyz->[0] , 0),      1,  'X value good');
is( close_enough( $xyz->[1] , 0),      1,  'Y value good');
is( close_enough( $xyz->[2] , 0),      1,  'Z value good');

# white
$val = $space->denormalize( [1, .378531073, .534351145] );
is( ref $val,                    'ARRAY',  'denormalized white into zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 100),      1,  'L* value of white good');
is( close_enough( $val->[1] , 0),      1,  'u* value of white good');
is( close_enough( $val->[2] , 0),      1,  'v* value of white good');

$val = $space->normalize( [100, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of white');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 1),      1,  'L value good');
is( close_enough( $val->[1] , 0.378531073),    1,  'u* value good');
is( close_enough( $val->[2] , 0.534351145),    1,  'v* value good');

$luv = $space->convert_from( 'CIEXYZ', [ 1, 1, 1]);
is( ref $luv,                    'ARRAY',  'deconverted white from CIEXYZ');
is( int @$luv,                         3,  'right amount of values');
is( close_enough( $luv->[0] , 1),                1,  'first value good');
is( close_enough( $luv->[1] , 0.378531073),      1,  'second value good');
is( close_enough( $luv->[2] , 0.534351145),      1,  'third value good');

$xyz = $space->convert_to( 'CIEXYZ', [ 1, .378531073, .534351145 ]);
is( ref $xyz,                    'ARRAY',  'converted white to CIEXYZ');
is( int @$xyz,                         3,  'right amount of values');
is( close_enough( $xyz->[0] , 1),      1,  'X value good');
is( close_enough( $xyz->[1] , 1),      1,  'Y value good');
is( close_enough( $xyz->[2] , 1),      1,  'Z value good');

# red
$val = $space->denormalize( [0.53241, .872923729, .678458015] );
is( int @$val,                          3,  'denormalize red');
is( close_enough( $val->[0] , 53.241),  1,  'L* value of white good');
is( close_enough( $val->[1] , 175.015), 1,  'u* value of white good');
is( close_enough( $val->[2] , 37.756),  1,  'v* value of white good');

$val = $space->normalize( [53.241, 175.015, 37.756] );
is( int @$val,                         3,  'normalize red');
is( close_enough( $val->[0] , 0.53241),      1,  'L value good');
is( close_enough( $val->[1] , 0.872923729),    1,  'u* value good');
is( close_enough( $val->[2] , 0.678458015),    1,  'v* value good');

$luv = $space->convert_from( 'CIEXYZ', [ 0.433953728, 0.21267, 0.017753001]);
is( int @$luv,                         3,  'deconverted red from CIEXYZ');
is( close_enough( $luv->[0] , 0.53241),                1,  'first value good');
is( close_enough( $luv->[1] , 0.872923729),      1,  'second value good');
is( close_enough( $luv->[2] , 0.678458015),      1,  'third value good');

$xyz = $space->convert_to( 'CIEXYZ', [ 0.53241, .872923729, .678458015 ]);
is( int @$xyz,                         3,  'converted red to CIEXYZ');
is( close_enough( $xyz->[0] , 0.433953728),  1,  'X value good');
is( close_enough( $xyz->[1] , 0.21267),      1,  'Y value good');
is( close_enough( $xyz->[2] , 0.017753001),      1,  'Z value good');

# blue
$val = $space->denormalize( [0.32297, .351963277, .036862595] );
is( int @$val,                          3,  'denormalize blue');
is( close_enough( $val->[0] , 32.297),  1,  'L* value of white good');
is( close_enough( $val->[1] , -9.405), 1,  'u* value of white good');
is( close_enough( $val->[2] , -130.342),  1,  'v* value of white good');

$val = $space->normalize( [32.297, -9.405, -130.342] );
is( int @$val,                         3,  'normalize blue');
is( close_enough( $val->[0] , 0.32297),      1,  'L value good');
is( close_enough( $val->[1] , 0.351963277),    1,  'u* value good');
is( close_enough( $val->[2] , 0.036862595),    1,  'v* value good');

$luv = $space->convert_from( 'CIEXYZ', [ 0.18984292, 0.07217, 0.872771691]);
is( int @$luv,                         3,  'deconverted blue from CIEXYZ');
is( close_enough( $luv->[0] , 0.32297),                1,  'first value good');
is( close_enough( $luv->[1] , 0.351963277),      1,  'second value good');
is( close_enough( $luv->[2] , 0.036862595),      1,  'third value good');

$xyz = $space->convert_to( 'CIEXYZ', [ 0.32297, .351963277, .036862595 ]);
is( int @$xyz,                         3,  'converted blue to CIEXYZ');
is( close_enough( $xyz->[0] , 0.18984292),  1,  'X value good');
is( close_enough( $xyz->[1] , 0.07217),      1,  'Y value good');
is( close_enough( $xyz->[2] , 0.872771691),      1,  'Z value good');


$val = $space->denormalize( [0.32297, .351963277, .036862595] );
is( int @$val,                          3,  'denormalize blue');
is( close_enough( $val->[0] , 32.297),  1,  'L* value of white good');
is( close_enough( $val->[1] , -9.405), 1,  'u* value of white good');
is( close_enough( $val->[2] , -130.342),  1,  'v* value of white good');

$val = $space->normalize( [32.297, -9.405, -130.342] );
is( int @$val,                         3,  'normalize blue');
is( close_enough( $val->[0] , 0.32297),      1,  'L value good');
is( close_enough( $val->[1] , 0.351963277),    1,  'u* value good');
is( close_enough( $val->[2] , 0.036862595),    1,  'v* value good');

# gray
$val = $space->denormalize( [0.53389, .378531073, .534351145] );
is( int @$val,                         3,  'denormalize gray');
is( close_enough( $val->[0] , 53.389), 1,  'L* value of white good');
is( close_enough( $val->[1] , 0),      1,  'u* value of white good');
is( close_enough( $val->[2] , 0),      1,  'v* value of white good');

$val = $space->normalize( [53.389, 0, 0] );
is( int @$val,                         3,  'normalize gray');
is( close_enough( $val->[0] , 0.53389),        1,  'L value good');
is( close_enough( $val->[1] , 0.378531073),    1,  'u* value good');
is( close_enough( $val->[2] , 0.534351145),    1,  'v* value good');

$luv = $space->convert_from( 'CIEXYZ', [ .214041474 , .21404, 0.214037086]);
is( int @$luv,                         3,  'deconverted gray from CIEXYZ');
is( close_enough( $luv->[0] , 0.53389),          1,  'first value good');
is( close_enough( $luv->[1] , 0.378531073),      1,  'second value good');
is( close_enough( $luv->[2] , 0.534351145),      1,  'third value good');

$xyz = $space->convert_to( 'CIEXYZ', [ 0.53389, .378531073, .534351145 ]);
is( int @$xyz,                         3,  'converted gray to CIEXYZ');
is( close_enough( $xyz->[0] , 0.214041474),   1,  'X value good');
is( close_enough( $xyz->[1] , 0.21404),       1,  'Y value good');
is( close_enough( $xyz->[2] , 0.214037086),   1,  'Z value good');

# nice blue
$val = $space->denormalize( [0.24082, .352573446, .317049618] );
is( int @$val,                         3,  'denormalize nice blue');
is( close_enough( $val->[0] , 24.082), 1,  'L* value of white good');
is( close_enough( $val->[1] , -9.189),      1,  'u* value of white good');
is( close_enough( $val->[2] , -56.933),      1,  'v* value of white good');

$val = $space->normalize( [24.082, -9.189, -56.933] );
is( int @$val,                         3,  'normalize nice blue');
is( close_enough( $val->[0] , 0.24082),        1,  'L value good');
is( close_enough( $val->[1] , 0.352573446),    1,  'u* value good');
is( close_enough( $val->[2] , 0.317049618),    1,  'v* value good');

$luv = $space->convert_from( 'CIEXYZ', [ 0.057434743, .04125, .190608268]);
is( int @$luv,                         3,  'deconverted nice blue from CIEXYZ');
is( close_enough( $luv->[0] , 0.24082),          1,  'first value good');
is( close_enough( $luv->[1] , 0.352573446),      1,  'second value good');
is( close_enough( $luv->[2] , 0.317049618),      1,  'third value good');

$xyz = $space->convert_to( 'CIEXYZ', [ 0.24082, .352573446, .317049618 ]);
is( int @$xyz,                         3,  'converted nice blue to CIEXYZ');
is( close_enough( $xyz->[0] , 0.057434743),   1,  'X value good');
is( close_enough( $xyz->[1] , 0.04125),       1,  'Y value good');
is( close_enough( $xyz->[2] , 0.190608268),   1,  'Z value good');

exit 0;



