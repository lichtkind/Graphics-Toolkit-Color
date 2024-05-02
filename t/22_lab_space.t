#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 57;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::LAB';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELAB',                  'color space has right name');
is( $space->axis,              3,                     'color space has 3 axis');


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

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('RGB'), 1,                 'namespace can be written upper case');
is( $space->can_convert('xyz'), 0,                 'can not convert to xyz');
is( $space->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $space->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');

my $val = $space->deformat(['CIELAB', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'deformated named ARRAY into tuple');
is( int @$val,   3,     'right amount of values');
is( $val->[0],   0,     'first value good');
is( $val->[1],  -1,     'second value good');
is( $val->[2], -0.1,    'third value good');
is( $space->format([0,1,0], 'css_string'), 'cielab(0, 1, 0)', 'can format css string');

$val = $space->deconvert( [ 0, 0, 0], 'RGB');
is( ref $val,                    'ARRAY',  'deconverted tuple of zeros');
is( int @$val,                         3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

$val = $space->convert( [ 0, 0, 0], 'RGB');
is( ref $val,  'ARRAY',  'converted tuple of zeros');
is( int @$val,       3,  'right amount of values');
is( close_enough( $val->[0] , 0),      1,  'first value good');
is( close_enough( $val->[1] , 0),      1,  'second value good');
is( close_enough( $val->[2] , 0),      1,  'third value good');

exit 0;

my @xyz = $space->deconvert( [ 0.5, 0.5, 0.5], 'RGB');
is( int @xyz,                         3,  'converted color grey has three XYZ values');
is( close_enough($xyz[0], 0.20344),   1,  'converted color grey has computed right X value');
is( close_enough($xyz[1], 0.21404),   1,  'converted color grey has computed right Y value');
is( close_enough($xyz[2], 0.23305),   1,  'converted color grey has computed right Z value');

@xyz = $space->deconvert( [ 1, 1, 1], 'RGB');
is( int @xyz,                         3,  'converted color white has three XYZ values');
is( close_enough($xyz[0], 0.95047),   1,  'converted color white has computed right X value');
is( close_enough($xyz[1],       1),   1,  'converted color white has computed right Y value');
is( close_enough($xyz[2], 1.08883),   1,  'converted color white has computed right Z value');

@xyz = $space->deconvert( [ 1, 0, 0.5], 'RGB');
is( int @xyz,                         3,  'converted color pink has three XYZ values');
is( close_enough($xyz[0], 0.45108),   1,  'converted color pink has computed right X value');
is( close_enough($xyz[1], 0.22821),   1,  'converted color pink has computed right Y value');
is( close_enough($xyz[2], 0.22274),   1,  'converted color pink has computed right Z value');

my @rgb = $space->convert( [0, 0, 0], 'RGB');
is( int @rgb,                  3,     'converted back black with 3 values');
is( close_enough($rgb[0],  0), 1,   'right red value');
is( close_enough($rgb[1],  0), 1,   'right green value');
is( close_enough($rgb[2],  0), 1,   'right blue value');

@rgb = $space->convert( [0.20344, 0.21404, 0.23305], 'RGB');
is( int @rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb[0],  0.5), 1,   'right red value');
is( close_enough($rgb[1],  0.5), 1,   'right green value');
is( close_enough($rgb[2],  0.5), 1,   'right blue value');

@rgb = $space->convert( [0.95047, 1, 1.08883], 'RGB');
is( int @rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb[0],  1), 1,   'right red value');
is( close_enough($rgb[1],  1), 1,   'right green value');
is( close_enough($rgb[2],  1), 1,   'right blue value');

@rgb = $space->convert( [0.45108, 0.22821, 0.22274], 'RGB');
is( int @rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb[0],  1  ), 1,   'right red value');
is( close_enough($rgb[1],  0  ), 1,   'right green value');
is( close_enough($rgb[2],  0.5), 1,   'right blue value');

exit 0;
