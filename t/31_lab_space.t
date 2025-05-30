#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 93;

BEGIN { unshift @INC, 'lib', '../lib', 't/lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::LAB';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELAB',                  'color space has right name');
is( $space->axis,              3,                  'color space has 3 axis');

is( ref $space->range_check([0, 0, 0]),          'ARRAY',   'check minimal CIELAB values are in bounds');
is( ref $space->range_check([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELAB values');
is( ref $space->range_check([0,0]),              '',   "CIELAB got too few values");
is( ref $space->range_check([0, 0, 0, 0]),       '',   "CIELAB got too many values");
is( ref $space->range_check([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->range_check([101, 0, 0]),        '',   "L value is too big");
is( ref $space->range_check([0, -500.1, 0]),     '',   "a value is too small");
is( ref $space->range_check([0, 500.1, 0]),      '',   "a value is too big");
is( ref $space->range_check([0, 0, -200.1 ] ),   '',   "b value is too small");
is( ref $space->range_check([0, 0, 200.2] ),     '',   "b value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');
is( $space->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('RGB'), 1,                 'namespace can be written upper case');
is( $space->can_convert('xyz'), 0,                 'can not convert to xyz');
is( $space->format([0,0,0], 'css_string'), 'cielab(0, 0, 0)', 'can format css string');


my $val = $space->deformat(['CIELAB', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cielab(0, 1, 0)', 'can format css string');

$val = $space->deconvert( [ 0, 0, 0], 'RGB');
is( ref $val,                    'ARRAY',  'deconverted tuple of zeros (black) from RGB');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0.5),    1,  'second value good');
is( close_enough( $val->[2] , 0.5),    1,  'third value good');

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

exit 0;
