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
is( $space->axis_count,          3,                  'color space has 3 dimensions');

is( ref $space->check_range([0,0]),              '',   "CIELCHab got too few values");
is( ref $space->check_range([0, 0, 0, 0]),       '',   "CIELCHab got too many values");
is( ref $space->check_range([0, 0, 0]),          'ARRAY',   'check minimal CIELCHab values are in bounds');
is( ref $space->check_range([100, 539, 360]),    'ARRAY',   'check maximal CIELCHab values are in bounds');
is( ref $space->check_range([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_range([100.01, 0, 0]),     '',   'L value is too big');
is( ref $space->check_range([0, -0.1, 0]),       '',   "c value is too small");
is( ref $space->check_range([0, 539.1, 0]),      '',   'c value is too big');
is( ref $space->check_range([0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_range([0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}), 1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'CIELAB'), 1,                 'do only convert from and to rgb');
is( $space->can_convert( 'CieLab'), 1,                 'namespace can be written lower case');
is( $space->can_convert( 'CIELCHab'), 0,               'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cielchab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELCHab', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,11,350], 'css_string'), 'cielchab(0, 11, 350)', 'can format css string');


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

my $lch = $space->convert_from( 'CIELAB',  [ 0, 0.5, 0.5]);
is( ref $lch,                    'ARRAY',  'deconverted black from CIELAB');
is( int @$lch,                         3,  'right amount of values');
is( close_enough( $lch->[0] , 0),      1,  'L value is good');
is( close_enough( $lch->[1] , 0),      1,  'C value is good');
is( close_enough( $lch->[2] , 0),      1,  'H value is good');

my $lab = $space->convert_to( 'CIELAB',  [ 0, 0, 0 ]);
is( ref $lab,                    'ARRAY',  'converted black to CIELAB');
is( int @$lab,                             3,  'right amount of values');
is( close_enough( $lab->[0] , 0),          1,  'L* value is good');
is( close_enough( $lab->[1] , 0.5), 1,  'a* value is good');
is( close_enough( $lab->[2] , 0.5), 1,  'b* value is good');

# white
$val = $space->denormalize( [1, 0, 0] );
is( int @$val,                          3,  'denormalized white');
is( close_enough( $val->[0] , 100),     1,  'L value of white is good');
is( close_enough( $val->[1] , 0),       1,  'C value of white is good');
is( close_enough( $val->[2] , 0),       1,  'H value of white is good');

$val = $space->normalize( [100, 0, 0] );
is( int @$val,                        3,  'normalized white');
is( close_enough( $val->[0] , 1),     1,  'L value is good');
is( close_enough( $val->[1] , 0),     1,  'C value is good');
is( close_enough( $val->[2] , 0),     1,  'H value is good');

$lch = $space->convert_from( 'CIELAB',  [ 1, .5, .5]);
is( int @$lch,                         3,  'deconverted white from CIELAB');
is( close_enough( $lch->[0] , 1),      1,  'L value is good');
is( close_enough( $lch->[1] , 0),      1,  'C value is good');
is( close_enough( $lch->[2] , 0),      1,  'H value is good');

$lab = $space->convert_to( 'CIELAB',  [ 1, 0, 0 ]);
is( int @$lab,                     3,  'converted white to CIELAB');
is( close_enough( $lab->[0] , 1),  1,  'L value is good');
is( close_enough( $lab->[1] , .5), 1,  'u value is good');
is( close_enough( $lab->[2] , .5), 1,  'v value is good');

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

$lch = $space->convert_from( 'CIELAB',  [ .53389, .5, .5]);
is( int @$lch,                         3,  'deconverted gray from CIELAB');
is( close_enough( $lch->[0] , .53389), 1,  'L value is good');
is( close_enough( $lch->[1] , 0),      1,  'C value is good');
is( close_enough( $lch->[2] , 0),      1,  'H value is good');

$lab = $space->convert_to( 'CIELAB',  [ .53389, 0, 0.686386111 ]);
is( int @$lab,                         3,  'converted gray to CIELAB');
is( close_enough( $lab->[0] , .53389),      1,  'L value is good');
is( close_enough( $lab->[1] , .5),  1,  'u value is good');
is( close_enough( $lab->[2] , .5),  1,  'v value is good');

# red
$val = $space->denormalize( [.53389, 0.193974026, .111108333] );
is( int @$val,                          3,  'denormalized red');
is( close_enough( $val->[0] , 53.389),     1,  'L value is good');
is( close_enough( $val->[1] , 104.552),       1,  'C value is good');
is( close_enough( $val->[2] , 39.999), 1,  'H value is good');

$val = $space->normalize( [53.389, 104.552, 39.999] );
is( int @$val,                         3,  'normalized red');
is( close_enough( $val->[0] , .53389),      1,  'L value good');
is( close_enough( $val->[1] , 0.193974026),      1,  'C value good');
is( close_enough( $val->[2] , 0.111108333),    1,  'H value good');

$lch = $space->convert_from( 'CIELAB',  [ .53389, .580092, .6680075]);
is( int @$lch,                         3,  'deconverted red from CIELAB');
is( close_enough( $lch->[0] , .53389), 1,  'L value good');
is( close_enough( $lch->[1] , 0.193974026),      1,  'C value good');
is( close_enough( $lch->[2] , 0.111108333),      1,  'H value good');

$lab = $space->convert_to( 'CIELAB',  [ .53389, 0.193974026, .111108333 ]);
is( int @$lab,                         3,  'converted red to CIELAB');
is( close_enough( $lab->[0] , .53389),      1,  'L value good');
is( close_enough( $lab->[1] , .580092),  1,  'u value good');
is( close_enough( $lab->[2] , .6680075),  1,  'v value good');

# blue
$val = $space->denormalize( [.32297, 0.248252319, .850791667] );
is( int @$val,                          3,  'denormalized blue');
is( close_enough( $val->[0] , 32.297),     1,  'L value is good');
is( close_enough( $val->[1] , 133.808),       1,  'C value is good');
is( close_enough( $val->[2] , 306.285), 1,  'H value is good');

$val = $space->normalize( [32.297, 133.808, 306.285] );
is( int @$val,                         3,  'normalized blue');
is( close_enough( $val->[0] , .32297),      1,  'L value good');
is( close_enough( $val->[1] , 0.248252319),      1,  'C value good');
is( close_enough( $val->[2] , 0.850791667),    1,  'H value good');

$lch = $space->convert_from( 'CIELAB',  [ .32297, .579188, .23035]);
is( int @$lch,                         3,  'deconverted blue from CIELAB');
is( close_enough( $lch->[0] , .32297), 1,  'L value good');
is( close_enough( $lch->[1] , 0.248252319),      1,  'C value good');
is( close_enough( $lch->[2] , 0.850791667),      1,  'H value good');

$lab = $space->convert_to( 'CIELAB',  [ .32297, 0.248252319, .850791667 ]);
is( int @$lab,                         3,  'converted blue to CIELAB');
is( close_enough( $lab->[0] , .32297),      1,  'L value good');
is( close_enough( $lab->[1] , .579188),  1,  'u value good');
is( close_enough( $lab->[2] , .23035),  1,  'v value good');

# mid blue
$val = $space->denormalize( [.37478, 0.220141002, .842422222] );
is( int @$val,                          3,  'denormalized nice blue');
is( close_enough( $val->[0] , 37.478),      1,  'L value is good');
is( close_enough( $val->[1] , 118.656),     1,  'C value is good');
is( close_enough( $val->[2] , 303.272), 1,  'H value is good');

$val = $space->normalize( [37.478, 118.656, 303.272] );
is( int @$val,                         3,  'normalized nice blue');
is( close_enough( $val->[0] , .37478),      1,  'L value good');
is( close_enough( $val->[1] , 0.220141002),      1,  'C value good');
is( close_enough( $val->[2] , 0.842422222),    1,  'H value good');

$lch = $space->convert_from( 'CIELAB',  [ .37478, .565097, .2519875]);
is( int @$lch,                         3,  'deconverted nice blue from CIELAB');
is( close_enough( $lch->[0] , .37478), 1,  'L value good');
is( close_enough( $lch->[1] , 0.220141002),      1,  'C value good');
is( close_enough( $lch->[2] , 0.842422222),      1,  'H value good');

$lab = $space->convert_to( 'CIELAB',  [ .37478, 0.220141002, .842422222 ]);
is( int @$lab,                         3,  'converted nice blue to CIELAB');
is( close_enough( $lab->[0] , .37478),      1,  'L value good');
is( close_enough( $lab->[1] , .565097),     1,  'u value good');
is( close_enough( $lab->[2] , .2519875),    1,  'v value good');

exit 0;

