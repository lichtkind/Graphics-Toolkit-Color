#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 131;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHuv';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,         'CIELCHUV',                'color space name is CIELCHuv');
is( $space->is_name('CIELCHuv'),   1,                'color space name CIELCHuv is correct');
is( $space->alias,                '',                'color space has no alias name');
is( $space->axis_count,            3,                'color space has 3 dimensions');

is( ref $space->check_range( [0,0]),              '',   "CIELCHuv got too few values");
is( ref $space->check_range( [0, 0, 0, 0]),       '',   "CIELCHuv got too many values");
is( ref $space->check_range( [0, 0, 0]),          'ARRAY',   'check minimal CIELCHuv values are in bounds');
is( ref $space->check_range( [100, 261, 360]),    'ARRAY',   'check maximal CIELCHuv values are in bounds');
is( ref $space->check_range( [-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_range( [100.01, 0, 0]),     '',   'L value is too big');
is( ref $space->check_range( [0, -0.1, 0]),       '',   "c value is too small");
is( ref $space->check_range( [0, 261.1, 0]),      '',   'c value is too big');
is( ref $space->check_range( [0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_range( [0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert('LUV'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('Luv'), 1,                 'namespace can be written lower case');
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
is( round_decimals( $val->[0] , 0),      1,  'L value is good');
is( round_decimals( $val->[1] , 0),      1,  'C value is good');
is( round_decimals( $val->[2] , 0),      1,  'H value is good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( round_decimals( $val->[0] , 0),      1,  'L value is good');
is( round_decimals( $val->[1] , 0),      1,  'C value is good');
is( round_decimals( $val->[2] , 0),      1,  'H value is good');

my $lch = $space->convert_from( 'LUV', [ 0, .378531073, .534351145]);
is( ref $lch,                    'ARRAY',  'deconverted black from LUV');
is( int @$lch,                         3,  'right amount of values');
is( round_decimals( $lch->[0] , 0),      1,  'L value is good');
is( round_decimals( $lch->[1] , 0),      1,  'C value is good');
is( round_decimals( $lch->[2] , 0),      1,  'H value is good');

my $luv = $space->convert_to( 'LUV', [ 0, 0, 0 ] );
is( ref $luv,                    'ARRAY',  'converted black to LUV');
is( int @$luv,                             3,  'right amount of values');
is( round_decimals( $luv->[0] , 0),          1,  'L* value is good');
is( round_decimals( $luv->[1] , .378531073), 1,  'u* value is good');
is( round_decimals( $luv->[2] , .534351145), 1,  'v* value is good');
exit 0;

# white
$val = $space->denormalize( [1, 0, 0] );
is( int @$val,                          3,  'denormalized white');
is( round_decimals( $val->[0] , 100),     1,  'L value of white is good');
is( round_decimals( $val->[1] , 0),       1,  'C value of white is good');
is( round_decimals( $val->[2] , 0),       1,  'H value of white is good');

$val = $space->normalize( [100, 0, 0] );
is( int @$val,                               3,  'normalized white');
is( round_decimals( $val->[0] , 1),            1,  'L value is good');
is( round_decimals( $val->[1] , 0),            1,  'C value is good');
is( round_decimals( $val->[2] , 0),            1,  'H value is good');

$lch = $space->convert_from( 'LUV', [ 1, .378531073, .534351145]);
is( int @$lch,                         3,  'deconverted white from LUV');
is( round_decimals( $lch->[0] , 1),      1,  'L value is good');
is( round_decimals( $lch->[1] , 0),      1,  'C value is good');
is( round_decimals( $lch->[2] , 0),      1,  'H value is good');

$luv = $space->convert_to( 'LUV', [ 1, 0, 0 ] );
is( int @$luv,                             3,  'converted white to LUV');
is( round_decimals( $luv->[0] , 1),          1,  'L value is good');
is( round_decimals( $luv->[1] , .378531073), 1,  'u value is good');
is( round_decimals( $luv->[2] , .534351145), 1,  'v value is good');


# gray
$val = $space->denormalize( [.53389, 0, .686386111] );
is( int @$val,                          3,  'denormalized gray');
is( round_decimals( $val->[0] , 53.389),  1,  'L value is good');
is( round_decimals( $val->[1] , 0),       1,  'C value is good');
is( round_decimals( $val->[2] , 247.099), 1,  'H value is good');

$val = $space->normalize( [53.389, 0, 247.099] );
is( int @$val,                              3,  'normalized gray');
is( round_decimals( $val->[0] , .53389),      1,  'L value good');
is( round_decimals( $val->[1] , 0),           1,  'C value good');
is( round_decimals( $val->[2] , 0.686386111), 1,  'H value good');

$lch = $space->convert_from( 'LUV', [ .53389, .378531073, .534351145] );
is( int @$lch,                         3,  'deconverted gray from LUV');
is( round_decimals( $lch->[0] , .53389), 1,  'L value is good');
is( round_decimals( $lch->[1] , 0),      1,  'C value is good');
is( round_decimals( $lch->[2] , 0),      1,  'H value is good');

$luv = $space->convert_to( 'LUV', [ .53389, 0, 0.686386111 ] );
is( int @$luv,                         3,  'converted gray to LUV');
is( round_decimals( $luv->[0] , .53389),      1,  'L value is good');
is( round_decimals( $luv->[1] , .378531073),  1,  'u value is good');
is( round_decimals( $luv->[2] , .534351145),  1,  'v value is good');

# red
$val = $space->denormalize( [.53389, 0.685980843, .033816667] );
is( int @$val,                          3,  'denormalized red');
is( round_decimals( $val->[0] , 53.389),     1,  'L value is good');
is( round_decimals( $val->[1] , 179.041),       1,  'C value is good');
is( round_decimals( $val->[2] , 12.174), 1,  'H value is good');

$val = $space->normalize( [53.389, 179.041, 12.174] );
is( int @$val,                         3,  'normalized red');
is( round_decimals( $val->[0] , .53389),      1,  'L value good');
is( round_decimals( $val->[1] , 0.685980843),      1,  'C value good');
is( round_decimals( $val->[2] , 0.033816667),    1,  'H value good');

$lch = $space->convert_from( 'LUV', [ .53389, .872923729, .678458015] );
is( int @$lch,                         3,  'deconverted red from LUV');
is( round_decimals( $lch->[0] , .53389), 1,  'L value good');
is( round_decimals( $lch->[1] , 0.685980843),      1,  'C value good');
is( round_decimals( $lch->[2] , 0.033816667),      1,  'H value good');

$luv = $space->convert_to( 'LUV', [ .53389, 0.685980843, .033816667 ] );
is( int @$luv,                         3,  'converted red to LUV');
is( round_decimals( $luv->[0] , .53389),      1,  'L value good');
is( round_decimals( $luv->[1] , .872923729),  1,  'u value good');
is( round_decimals( $luv->[2] , .678458015),  1,  'v value good');

# blue
$val = $space->denormalize( [.32297, 0.500693487, .738536111] );
is( int @$val,                          3,  'denormalized blue');
is( round_decimals( $val->[0] , 32.297),     1,  'L value is good');
is( round_decimals( $val->[1] , 130.681),       1,  'C value is good');
is( round_decimals( $val->[2] , 265.873), 1,  'H value is good');

$val = $space->normalize( [32.297, 130.681, 265.873] );
is( int @$val,                         3,  'normalized blue');
is( round_decimals( $val->[0] , .32297),      1,  'L value good');
is( round_decimals( $val->[1] , 0.500693487),      1,  'C value good');
is( round_decimals( $val->[2] , 0.738536111),    1,  'H value good');

$lch = $space->convert_from( 'LUV', [ .32297, .351963277, .036862595]);
is( int @$lch,                         3,  'deconverted blue from LUV');
is( round_decimals( $lch->[0] , .32297), 1,  'L value good');
is( round_decimals( $lch->[1] , 0.500693487),      1,  'C value good');
is( round_decimals( $lch->[2] , 0.738536111),      1,  'H value good');

$luv = $space->convert_to( 'LUV', [ .32297, 0.500693487, .738536111 ]);
is( int @$luv,                         3,  'converted blue to LUV');
is( round_decimals( $luv->[0] , .32297),      1,  'L value good');
is( round_decimals( $luv->[1] , .351963277),  1,  'u value good');
is( round_decimals( $luv->[2] , .036862595),  1,  'v value good');

# mid blue
$val = $space->denormalize( [.24082, 0.220954023, .724533333] );
is( int @$val,                          3,  'denormalized mid blue');
is( round_decimals( $val->[0] , 24.082),     1,  'L value is good');
is( round_decimals( $val->[1] , 57.669),       1,  'C value is good');
is( round_decimals( $val->[2] , 260.832), 1,  'H value is good');

$val = $space->normalize( [24.082, 57.669, 260.832] );
is( int @$val,                         3,  'normalized mid blue');
is( round_decimals( $val->[0] , .24082),      1,  'L value good');
is( round_decimals( $val->[1] , 0.220954023),      1,  'C value good');
is( round_decimals( $val->[2] , 0.724533333),    1,  'H value good');

$lch = $space->convert_from( 'LUV', [ .24082, .352573446, .317049618] );
is( int @$lch,                         3,  'deconverted mid blue from LUV');
is( round_decimals( $lch->[0] , .24082), 1,  'L value good');
is( round_decimals( $lch->[1] , 0.220954023),      1,  'C value good');
is( round_decimals( $lch->[2] , 0.724533333),      1,  'H value good');

$luv = $space->convert_to( 'LUV', [ .24082, 0.220954023, .724533333 ] );
is( int @$luv,                         3,  'converted mid blue to LUV');
is( round_decimals( $luv->[0] , .24082),      1,  'L value good');
is( round_decimals( $luv->[1] , .352573446),  1,  'u value good');
is( round_decimals( $luv->[2] , .317049618),  1,  'v value good');

exit 0;
