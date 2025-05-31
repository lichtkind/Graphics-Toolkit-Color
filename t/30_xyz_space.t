#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 58;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::CIEXYZ';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'CIEXYZ',                  'color space has right name');
is( $def->axis,              3,                     'color space has 3 axis');

is( ref $def->range_check([0, 0, 0]),          'ARRAY',  'check minimal XYZ values are in bounds');
is( ref $def->range_check([95.0, 100, 108.8]), 'ARRAY',  'check maximal XYZ values');
is( ref $def->range_check([0,0]),              '',   "XYZ got too few values");
is( ref $def->range_check([0, 0, 0, 0]),       '',   "XYZ got too many values");
is( ref $def->range_check([-0.1, 0, 0]),       '',   "X value is too small");
is( ref $def->range_check([96, 0, 0]),         '',   "X value is too big");
is( ref $def->range_check([0, -0.1, 0]),       '',   "Y value is too small");
is( ref $def->range_check([0, 100.1, 0]),      '',   "Y value is too big");
is( ref $def->range_check([0, 0, -.1 ] ),      '',   "Z value is too small");
is( ref $def->range_check([0, 0, 108.9] ),     '',   "Z value is too big");

is( $def->is_value_tuple([0,0,0]),           1,   'vector has 3 elements');
is( $def->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $def->can_convert('RGB'), 1,                 'namespace can be written upper case');
is( $def->is_partial_hash({x => 1, y => 0}), 1,  'found hash with some keys');
is( $def->is_partial_hash({x => 1, z => 0}), 1,  'found hash with some other keys');
is( $def->can_convert('yiq'), 0,                 'can not convert to yiq');

my $val = $def->deformat(['CIEXYZ', 1, 0, -0.1]);
is( int @$val,  3,     'deformated value triplet (vector)');
is( $val->[0], 1,     'first value good');
is( $val->[1], 0,     'second value good');
is( $val->[2], -0.1,  'third value good');
is( $def->format([0,1,0], 'css_string'), 'ciexyz(0, 1, 0)', 'can format css string');

my $xyz = $def->deconvert( [ 0, 0, 0], 'RGB');
is( int @$xyz,  3,  'converted color black has three XYZ values');
is( $xyz->[0],   0,  'converted color black has computed right X value');
is( $xyz->[1],   0,  'converted color black has computed right Y value');
is( $xyz->[2],   0,  'converted color black has computed right Z value');

$xyz = $def->deconvert( [ 0.5, 0.5, 0.5], 'RGB');
is( ref $xyz,                     'ARRAY',  'converted color grey has three XYZ values');
is( int @$xyz,                          3,  'got three values');
is( close_enough($xyz->[0], 0.21404),   1,  'converted color grey has computed right X value');
is( close_enough($xyz->[1], 0.21404),   1,  'converted color grey has computed right Y value');
is( close_enough($xyz->[2], 0.214037),  1,  'converted color grey has computed right Z value');

$xyz = $def->deconvert( [ 1, 1, 1], 'RGB');
is( int @$xyz,                          3,  'converted color white has three XYZ values');
is( close_enough($xyz->[0],       1),   1,  'converted color white has computed right X value');
is( close_enough($xyz->[1],       1),   1,  'converted color white has computed right Y value');
is( close_enough($xyz->[2],       1),   1,  'converted color white has computed right Z value');

$xyz = $def->deconvert( [ 1, 0, 0.5], 'RGB');
is( int @$xyz,                          3,  'converted color pink has three XYZ values');
is( close_enough($xyz->[0], 0.474586),  1,  'converted color pink has computed right X value');
is( close_enough($xyz->[1], 0.22821),   1,  'converted color pink has computed right Y value');
is( close_enough($xyz->[2], 0.204568),  1,  'converted color pink has computed right Z value');

my $rgb = $def->convert( [0, 0, 0], 'RGB');
is( int @$rgb,                  3,     'converted back black with 3 values');
is( close_enough($rgb->[0],  0), 1,   'right red value');
is( close_enough($rgb->[1],  0), 1,   'right green value');
is( close_enough($rgb->[2],  0), 1,   'right blue value');

$rgb = $def->convert( [0.21404, 0.21404, 0.214037], 'RGB');
is( int @$rgb,                     3,   'converted back gray with 3 values');
is( close_enough($rgb->[0],  0.5), 1,   'right red value');
is( close_enough($rgb->[1],  0.5), 1,   'right green value');
is( close_enough($rgb->[2],  0.5), 1,   'right blue value');

$rgb = $def->convert( [1, 1, 1], 'RGB');
is( int @$rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb->[0],  1), 1,   'right red value');
is( close_enough($rgb->[1],  1), 1,   'right green value');
is( close_enough($rgb->[2],  1), 1,   'right blue value');

$rgb = $def->convert( [0.474586, 0.22821, 0.204568], 'RGB');
is( int @$rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb->[0],  1  ), 1,   'right red value');
is( close_enough($rgb->[1],  0  ), 1,   'right green value');
is( close_enough($rgb->[2],  0.5), 1,   'right blue value');

exit 0;
