#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 100;
BEGIN { unshift @INC, 'lib', '../lib', 't/lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELAB';
my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELAB',                  'color space has right name');
is( $space->alias,         'LAB',                  'color space has right alis name');
is( $space->axis_count,        3,                  'color space has 3 axis');

is( ref $space->check_range([0, 0, 0]),          'ARRAY',   'check minimal CIELAB values are in bounds');
is( ref $space->check_range([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELAB values');
is( ref $space->check_range([0,0]),              '',   "CIELAB got too few values");
is( ref $space->check_range([0, 0, 0, 0]),       '',   "CIELAB got too many values");
is( ref $space->check_range([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_range([101, 0, 0]),        '',   "L value is too big");
is( ref $space->check_range([0, -500.1, 0]),     '',   "a value is too small");
is( ref $space->check_range([0, 500.1, 0]),      '',   "a value is too big");
is( ref $space->check_range([0, 0, -200.1 ] ),   '',   "b value is too small");
is( ref $space->check_range([0, 0, 200.2] ),     '',   "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({'L*' => 1, 'a*' => 0, 'b*' => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('CIEXYZ'), 1,              'do only convert from and to xyz');
is( $space->can_convert('ciexyz'), 1,              'namespace can be written upper case');
is( $space->can_convert('CIELAB'), 0,              'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cielab(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELAB', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cielab(0, 1, 0)', 'can format css string');

# black
my $lab = $space->convert_from( 'CIEXYZ', [ 0, 0, 0]);
is( ref $lab,                    'ARRAY',  'deconverted tuple of zeros (black) from CIEXYZ');
is( int @$lab,                         3,  'right amount of values');
is( close_enough( $lab->[0] , 0),      1,  'L* value good');
is( close_enough( $lab->[1] , 0.5),    1,  'a* value good');
is( close_enough( $lab->[2] , 0.5),    1,  'b* value good');

my $xyz = $space->convert_to( 'CIEXYZ', [ 0, 0.5, 0.5]);
is( ref $xyz,                    'ARRAY',  'converted black to CIEXYZ');
is( int @$xyz,                         3,  'got 3 values');
is( close_enough( $xyz->[0] , 0),      1,  'X value good');
is( close_enough( $xyz->[1] , 0),      1,  'Y value good');
is( close_enough( $xyz->[2] , 0),      1,  'Z value good');

$val = $space->denormalize( [0, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized deconverted tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'L* value of black good');
is( close_enough( $val->[1] , 0),      1,  'a* value of black good');
is( close_enough( $val->[2] , 0),      1,  'b* value of black good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros (black)');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'L value good');
is( close_enough( $val->[1] , 0.5),    1,  'a* value good');
is( close_enough( $val->[2] , 0.5),    1,  'b* value good');

# white
$lab = $space->convert_from( 'CIEXYZ', [ 1, 1, 1,]);
is( int @$lab,                          3,  'deconverted white from CIEXYZ');
is( close_enough( $lab->[0],   1),      1,  'L* value of white good');
is( close_enough( $lab->[1],   0.5),    1,  'a* value of white good');
is( close_enough( $lab->[2],   0.5),    1,  'b* value of white good');

$xyz = $space->convert_to( 'CIEXYZ', [ 1, 0.5, 0.5]);
is( int @$xyz,                         3,  'converted white to CIEXYZ');
is( close_enough( $xyz->[0] , 1),      1,  'X value of white good');
is( close_enough( $xyz->[1] , 1),      1,  'Y value of white good');
is( close_enough( $xyz->[2] , 1),      1,  'Z value of white good');

$val = $space->denormalize( [1, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized white');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 100),    1,  'L* value of black good');
is( close_enough( $val->[1] , 0),      1,  'a* value of black good');
is( close_enough( $val->[2] , 0),      1,  'b* value of black good');

$val = $space->normalize( [100, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized white');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 1),      1,  'L value good');
is( close_enough( $val->[1] , 0.5),    1,  'a* value good');
is( close_enough( $val->[2] , 0.5),    1,  'b* value good');

# nice blue
$lab = $space->convert_from( 'CIEXYZ', [ 0.0872931606914908, 0.0537065470652866, 0.282231548430505]);
is( int @$lab,                          3,  'deconverted nice blue from CIEXYZ');
is(  close_enough($lab->[0],   0.277656852),  1,    'L* value of nice blue good');
is(  close_enough($lab->[1],   0.5331557592), 1,    'a* value of nice blue good');
is(  close_enough($lab->[2],   0.3606718),    1,    'b* value of nice blue good');

$xyz = $space->convert_to( 'CIEXYZ', [ .277656852, 0.5331557592, 0.3606718]);
is( int @$xyz,                         3,  'converted nice blue to CIEXYZ');
is( close_enough( $xyz->[0],  0.08729316069), 1,   'X value of nice blue good');
is( close_enough( $xyz->[1],  0.053706547),   1,   'Y value of nice blue good');
is( close_enough( $xyz->[2],  0.2822315484),  1,   'Z value of nice blue good');

$val = $space->denormalize( [0.277656852, 0.5331557592, 0.3606718] );
is( int @$val,                          3,  'denormalized nice blue');
is( close_enough( $val->[0] , 27.766),  1,  'L* value of nice blue good');
is( close_enough( $val->[1] , 33.156),  1,  'a* value of nice blue good');
is( close_enough( $val->[2] , -55.731), 1,  'b* value of nice blue good');

$val = $space->normalize( [27.766, 33.156, -55.731] );
is( int @$val,                         3,  'normalized nice blue');
is( close_enough( $val->[0] , 0.277656852),    1,  'L value good');
is( close_enough( $val->[1] , 0.5331557592),   1,  'a* value good');
is( close_enough( $val->[2] , 0.3606718),      1,  'b* value good');

# pink
$lab = $space->convert_from( 'CIEXYZ', [0.487032731, 0.25180, 0.208186769 ]);
is( int @$lab,                          3,  'deconverted pink from CIEXYZ');
is(  close_enough($lab->[0],   0.57250),    1,    'L* value of pink good');
is(  close_enough($lab->[1],   0.577658),   1,    'a* value of pink good');
is(  close_enough($lab->[2],   0.5193925),  1,    'b* value of pink good');

$xyz = $space->convert_to( 'CIEXYZ', [ .57250, 0.577658, 0.5193925]);
is( int @$xyz,                         3,  'converted nice blue to CIEXYZ');
is( close_enough( $xyz->[0],  0.487032731), 1,   'X value of pink good');
is( close_enough( $xyz->[1],  0.25180),     1,   'Y value of pink good');
is( close_enough( $xyz->[2],  0.208186769), 1,   'Z value of pink good');


$val = $space->denormalize( [0.57250, 0.577658, 0.5193925] );
is( int @$val,                          3,  'denormalized pink');
is( close_enough( $val->[0] , 57.250),  1,  'L* value of pink good');
is( close_enough( $val->[1] , 77.658),  1,  'a* value of pink good');
is( close_enough( $val->[2] ,  7.757),  1,  'b* value of pink good');

$val = $space->normalize( [57.250, 77.658, 7.757] );
is( int @$val,                         3,  'normalized pink');
is( close_enough( $val->[0] , 0.57250),    1,  'L value of pink good');
is( close_enough( $val->[1] , 0.577658),   1,  'a* value of pink good');
is( close_enough( $val->[2] , 0.5193925),  1,  'b* value of pink good');
exit 0;

