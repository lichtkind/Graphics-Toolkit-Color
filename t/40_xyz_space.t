#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 67;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::CIEXYZ';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,          'XYZ',                  'color space name is XYZ');
is( $space->alias,      'CIEXYZ',                  'color space alias name is CIEXYZ');
is( $space->axis_count,        3,                  'color space has 3 axis');

is( ref $space->check_range([0, 0, 0]),          'ARRAY',  'check minimal XYZ values are in bounds');
is( ref $space->check_range([95.0, 100, 108.8]), 'ARRAY',  'check maximal XYZ values');
is( ref $space->check_range([0,0]),              '',   "XYZ got too few values");
is( ref $space->check_range([0, 0, 0, 0]),       '',   "XYZ got too many values");
is( ref $space->check_range([-0.1, 0, 0]),       '',   "X value is too small");
is( ref $space->check_range([96, 0, 0]),         '',   "X value is too big");
is( ref $space->check_range([0, -0.1, 0]),       '',   "Y value is too small");
is( ref $space->check_range([0, 100.1, 0]),      '',   "Y value is too big");
is( ref $space->check_range([0, 0, -.1 ] ),      '',   "Z value is too small");
is( ref $space->check_range([0, 0, 108.9] ),     '',   "Z value is too big");

is( $space->is_value_tuple([0,0,0]),           1,   'vector has 3 elements');
is( $space->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('RGB'), 1,                 'namespace can be written upper case');
is( $space->is_partial_hash({x => 1, y => 0}), 1,  'found hash with some keys');
is( $space->is_partial_hash({x => 1, z => 0}), 1,  'found hash with some other keys');
is( $space->can_convert('yiq'), 0,                 'can not convert to yiq');

my $val = $space->deformat(['CIEXYZ', 1, 0, -0.1]);
is( int @$val,  3,     'deformated value triplet (vector)');
is( $val->[0], 1,     'first value good');
is( $val->[1], 0,     'second value good');
is( $val->[2], -0.1,  'third value good');
is( $space->format([0,1,0], 'css_string'), 'xyz(0, 1, 0)', 'can format css string');


my $xyz = $space->convert_from( 'RGB', [ 0, 0, 0]);
is( int @$xyz,  3,  'converted color black has three XYZ values');
is( $xyz->[0],   0,  'converted color black has computed right X value');
is( $xyz->[1],   0,  'converted color black has computed right Y value');
is( $xyz->[2],   0,  'converted color black has computed right Z value');

my $rgb = $space->convert_to( 'RGB', [0, 0, 0]);
is( int @$rgb,                  3,    'converted back black with 3 values');
is( close_enough($rgb->[0],  0), 1,   'conversion of black has right red value');
is( close_enough($rgb->[1],  0), 1,   'conversion of black has right green value');
is( close_enough($rgb->[2],  0), 1,   'conversion of black has right blue value');


$xyz = $space->convert_from( 'RGB', [ 0.5, 0.5, 0.5]);
is( ref $xyz,                     'ARRAY',  'converted color grey has three XYZ values');
is( int @$xyz,                          3,  'got three values');
is( close_enough($xyz->[0], 0.21404),   1,  'converted color grey has computed right X value');
is( close_enough($xyz->[1], 0.21404),   1,  'converted color grey has computed right Y value');
is( close_enough($xyz->[2], 0.21404),  1,  'converted color grey has computed right Z value');

$rgb = $space->convert_to( 'RGB', [0.21404, 0.21404, 0.214037]);
is( int @$rgb,                     3,   'converted back gray with 3 values');
is( close_enough($rgb->[0],  0.5), 1,   'right red value');
is( close_enough($rgb->[1],  0.5), 1,   'right green value');
is( close_enough($rgb->[2],  0.5), 1,   'right blue value');


$xyz = $space->convert_from( 'RGB', [ 1, 1, 1]);
is( int @$xyz,                          3,  'converted color white has three XYZ values');
is( close_enough($xyz->[0],       1),   1,  'converted color white has computed right X value');
is( close_enough($xyz->[1],       1),   1,  'converted color white has computed right Y value');
is( close_enough($xyz->[2],       1),   1,  'converted color white has computed right Z value');

$rgb = $space->convert_to( 'RGB', [1, 1, 1]);
is( int @$rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb->[0],  1), 1,   'right red value');
is( close_enough($rgb->[1],  1), 1,   'right green value');
is( close_enough($rgb->[2],  1), 1,   'right blue value');

# pink
$xyz = $space->convert_from( 'RGB', [ 1, 0, 0.5]);
is( int @$xyz,                          3,  'converted color pink has three XYZ values');
is( close_enough($xyz->[0], 0.474586),  1,  'converted color pink has computed right X value');
is( close_enough($xyz->[1], 0.22821),   1,  'converted color pink has computed right Y value');
is( close_enough($xyz->[2], 0.204568),  1,  'converted color pink has computed right Z value');

$rgb = $space->convert_to( 'RGB', [0.474586, 0.22821, 0.204568]);
is( int @$rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb->[0],  1  ), 1,   'right red value');
is( close_enough($rgb->[1],  0  ), 1,   'right green value');
is( close_enough($rgb->[2],  0.5), 1,   'right blue value');

# mid blue
$xyz = $space->convert_from( 'RGB', [ .2, .2, .6]);
is( int @$xyz,                           3,  'converted color mid blue has three XYZ values');
is( close_enough($xyz->[0],  0.087293),  1,  'converted color mid blue has computed right X value');
is( close_enough($xyz->[1],  0.05371),   1,  'converted color mid blue has computed right Y value');
is( close_enough($xyz->[2],  0.2822315), 1,  'converted color mid blue has computed right Z value');

$rgb = $space->convert_to( 'RGB', [0.0872931606914908, 0.0537065470652866, 0.282231548430505]);
is( int @$rgb,                      3,   'converted back gray with 3 values');
is( close_enough($rgb->[0],  .2  ), 1,   'right red value');
is( close_enough($rgb->[1],  .2  ), 1,   'right green value');
is( close_enough($rgb->[2],  .6, ), 1,   'right blue value');


exit 0;
