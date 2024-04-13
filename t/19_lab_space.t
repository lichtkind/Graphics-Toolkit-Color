#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 47;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::LAB';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'CIELAB',                  'color space has right name');
is( $def->dimensions,     3,                     'color space has 3 dimensions');


is( ref $def->in_range([0, 0, 0]),              'ARRAY',   'check minimal XYZ values are in bounds');
is( ref $def->in_range([0.950, 1, 1.088]),  'ARRAY',   'check maximal XYZ values');
is( ref $def->in_range([0,0]),              '',   "XYZ got too few values");
is( ref $def->in_range([0, 0, 0, 0]),       '',   "XYZ got too many values");
is( ref $def->in_range([-0.1, 0, 0]),       '',   "X value is too small");
is( ref $def->in_range([1, 0, 0]),          '',   "X value is too big");
is( ref $def->in_range([0, -0.1, 0]),       '',   "Y value is too small");
is( ref $def->in_range([0, 1.1, 0]),        '',   "Y value is too big");
is( ref $def->in_range([0, 0, -.1 ] ),      '',   "Z value is too small");
is( ref $def->in_range([0, 0, 1.2] ),       '',   "Z value is too big");

is( $def->is_array([0,0,0]), 1,                  'vector has 3 elements');
is( $def->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $def->can_convert('RGB'), 1,                 'namespace can be written upper case');
is( $def->can_convert('xyz'), 0,                 'can not convert to xyz');
is( $def->is_partial_hash({l => 1, a => 0}), 1,  'found hash with some keys');
is( $def->is_partial_hash({a => 1, b => 0}), 1,  'found hash with some other keys');
is( $def->is_partial_hash({a => 1, x => 0}), 0,  'partial hash with bad keys');

my @val = $def->deformat(['CIELAB', 1, 0, -0.1]);
is( int @val,  3,     'deformated value triplet (vector)');
is( $val[0], 1,     'first value good');
is( $val[1], 0,     'second value good');
is( $val[2], -0.1,  'third value good');
is( $def->format([0,1,0], 'css_string'), 'cielab(0,1,0)', 'can format css string');


my @lab = $def->deconvert( [ 0, 0, 0], 'RGB');
is( int @lab,  3,  'converted color black has three LAB values');
is( $lab[0],   0,  'converted color black has computed right L value');
is( $lab[1],   0,  'converted color black has computed right a value');
is( $lab[2],   0,  'converted color black has computed right b value');

exit 0;

my @xyz = $def->deconvert( [ 0.5, 0.5, 0.5], 'RGB');
is( int @xyz,                         3,  'converted color grey has three XYZ values');
is( close_enough($xyz[0], 0.20344),   1,  'converted color grey has computed right X value');
is( close_enough($xyz[1], 0.21404),   1,  'converted color grey has computed right Y value');
is( close_enough($xyz[2], 0.23305),   1,  'converted color grey has computed right Z value');

@xyz = $def->deconvert( [ 1, 1, 1], 'RGB');
is( int @xyz,                         3,  'converted color white has three XYZ values');
is( close_enough($xyz[0], 0.95047),   1,  'converted color white has computed right X value');
is( close_enough($xyz[1],       1),   1,  'converted color white has computed right Y value');
is( close_enough($xyz[2], 1.08883),   1,  'converted color white has computed right Z value');

@xyz = $def->deconvert( [ 1, 0, 0.5], 'RGB');
is( int @xyz,                         3,  'converted color pink has three XYZ values');
is( close_enough($xyz[0], 0.45108),   1,  'converted color pink has computed right X value');
is( close_enough($xyz[1], 0.22821),   1,  'converted color pink has computed right Y value');
is( close_enough($xyz[2], 0.22274),   1,  'converted color pink has computed right Z value');

my @rgb = $def->convert( [0, 0, 0], 'RGB');
is( int @rgb,                  3,     'converted back black with 3 values');
is( close_enough($rgb[0],  0), 1,   'right red value');
is( close_enough($rgb[1],  0), 1,   'right green value');
is( close_enough($rgb[2],  0), 1,   'right blue value');

@rgb = $def->convert( [0.20344, 0.21404, 0.23305], 'RGB');
is( int @rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb[0],  0.5), 1,   'right red value');
is( close_enough($rgb[1],  0.5), 1,   'right green value');
is( close_enough($rgb[2],  0.5), 1,   'right blue value');

@rgb = $def->convert( [0.95047, 1, 1.08883], 'RGB');
is( int @rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb[0],  1), 1,   'right red value');
is( close_enough($rgb[1],  1), 1,   'right green value');
is( close_enough($rgb[2],  1), 1,   'right blue value');

@rgb = $def->convert( [0.45108, 0.22821, 0.22274], 'RGB');
is( int @rgb,                    3,     'converted back gray with 3 values');
is( close_enough($rgb[0],  1  ), 1,   'right red value');
is( close_enough($rgb[1],  0  ), 1,   'right green value');
is( close_enough($rgb[2],  0.5), 1,   'right blue value');

exit 0;
