#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 40;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELUV';


my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELUV',                  'color space name is CIELUV');
is( $space->alias,         'LUV',                  'color space alias is LUV');
is( $space->axis,              3,                  'color space has 3 dimensions');

is( ref $space->range_check([0, 0, 0]),          'ARRAY',   'check minimal CIELUV values are in bounds');
is( ref $space->range_check([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELUV values');
is( ref $space->range_check([0,0]),              '',   "CIELUV got too few values");
is( ref $space->range_check([0, 0, 0, 0]),       '',   "CIELUV got too many values");
is( ref $space->range_check([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->range_check([100, 0, 0]),   'ARRAY',   'L value is maximal');
is( ref $space->range_check([101, 0, 0]),        '',   "L value is too big");
is( ref $space->range_check([0, -134, 0]),  'ARRAY',   'u value is minimal');
is( ref $space->range_check([0, -134.1, 0]),     '',   "u value is too small");
is( ref $space->range_check([0, 220, 0]),   'ARRAY',   'u value is maximal');
is( ref $space->range_check([0, 220.1, 0]),      '',   "u value is too big");
is( ref $space->range_check([0, 0, -140]),  'ARRAY',   'v value is minimal');
is( ref $space->range_check([0, 0, -140.1 ] ),   '',   "v value is too small");
is( ref $space->range_check([0, 0, 122]),   'ARRAY',   'v value is maximal');
is( ref $space->range_check([0, 0, 122.2] ),     '',   "v value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({u => 1, v => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({u => 1, v => 0, l => 0}), 1, 'found hash with all axis names');
is( $space->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with onw wrong axis name');
is( $space->can_convert('CIEXYZ'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('ciexyz'), 1,                 'namespace can be written lower case');
is( $space->can_convert('luv'), 0,                 'can not convert to itself');
is( $space->format([0,0,0], 'css_string'), 'cieluv(0, 0, 0)', 'can format css string');

my $val = $space->deformat(['CIELUV', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cieluv(0, 1, 0)', 'can format css string');

exit 1;
$val = $space->deconvert( [ 0, 0, 0], 'RGB');
is( ref $val,                    'ARRAY',  'deconverted tuple of zeros (black) from RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

$val = $space->convert( [ 0, 0, 0], 'RGB');
is( ref $val,                    'ARRAY',  'converted black to RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

exit 1;


$val = $space->deconvert( [ 1, 1, 1], 'RGB');
is( ref $val,                    'ARRAY',  'deconverted white from RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 1),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

$val = $space->convert( [ 1, 0, 0], 'RGB');
is( ref $val,                    'ARRAY',  'converted white to RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 1),      1,  'first value good');
is( close_enough( $val->[1] , 1),      1,  'second value good');
is( close_enough( $val->[2] , 1),      1,  'third value good');


$val = $space->deconvert( [ .5, .5, .5], 'RGB');
is( ref $val,                    'ARRAY',  'deconverted gray from RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0.53389),1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

$val = $space->convert( [ .53389, 0, 0], 'RGB');
is( ref $val,                    'ARRAY',  'converted gray to RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , .5),     1,  'first value good');
is( close_enough( $val->[1] , .5),     1,  'second value good');
is( close_enough( $val->[2] , .5),     1,  'third value good');


$val = $space->deconvert( [ 1, 0, 0.5], 'RGB');
is( ref $val,                     'ARRAY', 'converted purple from RGB');
is( int @$val,                          3, 'right amount of values');
is( close_enough( $val->[0] , .54878),  1, 'first value good');
is( close_enough( $val->[1] , .584499), 1, 'second value good');
is( close_enough( $val->[2] , .5109),   1, 'third value good');


exit 0;

__END__
is( ref $space->in_range([0, 0, 0]),          'ARRAY',   'check minimal CIELAB values are in bounds');
is( ref $space->in_range([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELAB values');
is( ref $space->in_range([0,0]),              '',   "CIELAB got too few values");
is( ref $space->in_range([0, 0, 0, 0]),       '',   "CIELAB got too many values");
is( ref $space->in_range([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->in_range([101, 0, 0]),        '',   "L value is too big");
is( ref $space->in_range([0, -500.1, 0]),     '',   "a value is too small");
is( ref $space->in_range([0, 500.1, 0]),        '',   "a value is too big");
is( ref $space->in_range([0, 0, -200.1 ] ),      '',   "b value is too small");
is( ref $space->in_range([0, 0, 200.2] ),       '',   "b value is too big");




$val = $space->denormalize( [0, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized deconverted tuple of zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

$val = $space->normalize( [0, 0, 0] );
is( ref $val,                    'ARRAY',  'normalized tuple of zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0.5),    1,  'second value good');
is( close_enough( $val->[2] , 0.5),    1,  'third value good');

$val = $space->convert( [ 0, 0.5, 0.5], 'RGB');
is( ref $val,                    'ARRAY',  'converted white to RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');


$val = $space->deconvert( [ 1, 1, 1,], 'RGB');
is( ref $val,                     'ARRAY',  'deconverted tuple of ones (white)');
is( int @$val,                          3,  'right amount of values');
is( close_enough($val->[0],   1),       1,  'first value good');
is( close_enough($val->[1],   0.5),     1,  'second value good');
is( close_enough($val->[2],   0.5),     1,  'third value good');

$val = $space->convert( [ 1, 0.5, 0.5], 'RGB');
is( ref $val,                    'ARRAY',  'converted tuple of zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 1),      1,  'first value good');
is( close_enough( $val->[1] , 1),      1,  'second value good');
is( close_enough( $val->[2] , 1),      1,  'third value good');

$val = $space->deconvert( [ 0.5, 0.5, 0.5], 'RGB');
is( ref $val,                     'ARRAY',  'converted gray to RGB');
is( int @$val,                          3,  'right amount of values');
is( close_enough( $val->[0] , .53389),  1,  'first value good');
is( close_enough( $val->[1] , .5),      1,  'second value good');
is( close_enough( $val->[2] , .5),      1,  'third value good');

$val = $space->denormalize( [0.53389, .5, .5] );
is( ref $val,                    'ARRAY',  'denormalized deconverted gray');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 53.389), 1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

$val = $space->convert( [ 0.53389, .5, .5], 'RGB');
is( ref $val,                     'ARRAY', 'converted back gray to RGB');
is( int @$val,                          3, 'right amount of values');
is( close_enough( $val->[0] , .5),      1, 'first value good');
is( close_enough( $val->[1] , .5),      1, 'second value good');
is( close_enough( $val->[2] , .5),      1, 'third value good');


$val = $space->deconvert( [ 1, 0, 0.5], 'RGB');
is( ref $val,                     'ARRAY', 'converted purple from RGB');
is( int @$val,                          3, 'right amount of values');
is( close_enough( $val->[0] , .54878),  1, 'first value good');
is( close_enough( $val->[1] , .584499), 1, 'second value good');
is( close_enough( $val->[2] , .5109),   1, 'third value good');

$val = $space->convert( [ 0.54878, .584499, .5109], 'RGB');
is( ref $val,                     'ARRAY', 'converted back gray to RGB');
is( int @$val,                          3, 'right amount of values');
is( close_enough( $val->[0] ,  1),      1, 'first value good');
is( close_enough( $val->[1] ,  0),      1, 'second value good');
is( close_enough( $val->[2] , .5),      1, 'third value good');


$val = $space->deconvert( [ .1, 0.2, 0.9], 'RGB');
is( ref $val,                    'ARRAY', 'converted BLUE from RGB');
is( int @$val,                          3, 'right amount of values');
is( close_enough( $val->[0] , .34526),  1, 'first value good');
is( close_enough( $val->[1] , .557165), 1, 'second value good');
is( close_enough( $val->[2] , .2757375),1, 'third value good');

$val = $space->convert( [ 0.34526, .557165, .2757375], 'RGB');
is( ref $val,                     'ARRAY', 'converted back BLUE to RGB');
is( int @$val,                          3, 'right amount of values');
is( close_enough( $val->[0] , .1),      1, 'first value good');
is( close_enough( $val->[1] , .2),      1, 'second value good');
is( close_enough( $val->[2] , .9),      1, 'third value good');
