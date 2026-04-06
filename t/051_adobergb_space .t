#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/';
use Test::More tests => 58;
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Instance::AdobeRGB';

my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,         'ADOBERGB',              'color space has right name');
is( $space->name('alias'),   'OPRGB',              'color space has alias name: "OPRGB"');
is( $space->is_name('AdobeRGB'),   1,              'one way to write the space name');
is( $space->is_name('opRGB'),      1,              'another way to write the space name');
is( $space->is_name('RGB'),        0,              'Adobe RGB is not standard RGB');
is( $space->axis_count,            3,              'Adobe RGB color space has 3 axis');
is( $space->is_euclidean,          1,              'Adobe RGB is euclidean');
is( $space->is_cylindrical,        0,              'Adobe RGB is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('CIEXYZ'),                     1,  'normal converter parent, can only convert to and from XYZ');
is( $space->can_convert('CIE_xyz'),                    1,  'converter parent gets normalized');
is( $space->can_convert('RGB'),                        0,  'does not convert directly to RGB');
is( $space->is_partial_hash({r => 1, b => 0, g=>0}),   1,  'found hash with some short axis names as keys');
is( $space->is_partial_hash({green => 1, blue => 0}),  1,  'found hash with some other long axis names as keys');
is( $space->is_partial_hash({green => 1, cyan => 0}),  0,  'some axis name match some do not');

is( ref $space->check_value_shape( [0,0,0]),    'ARRAY', 'check LRGB values works on lower bound values');
is( ref $space->check_value_shape( [1, 1, 1]),  'ARRAY', 'check LRGB values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),           '', "LRGB got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),    '', "LRGB got too many values");
is( ref $space->check_value_shape( [-0.1, 0, 0]),    '', "red value is too small");
is( ref $space->check_value_shape( [1.1, 0, 0]),     '', "reg value is too big");
is( ref $space->check_value_shape( [0, -0.001, 0]),  '', "green value is too small");
is( ref $space->check_value_shape( [0, 1.1, 0]),     '', "green value is too big");
is( ref $space->check_value_shape( [0, 0, -0.1 ] ),  '', "blue value is too small");
is( ref $space->check_value_shape( [0, 0, 1.1] ),    '', "blue value is too big");

my $rgb = $space->clamp([]);
is( int @$rgb,   3,     'default color is set by clamp');
is( $rgb->[0],   0,     'default color is black (R) no args');
is( $rgb->[1],   0,     'default color is black (G) no args');
is( $rgb->[2],   0,     'default color is black (B) no args');

$rgb = $space->clamp([0, 1]);
is( int @$rgb,   3,     'clamp added missing argument in vector');
is( $rgb->[0],   0,     'passed (R) value');
is( $rgb->[1],   1,     'passed (G) value');
is( $rgb->[2],   0,     'added (B) value when too few args');

$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is( ref $rgb,   'ARRAY',  'clamped tuple and got tuple back');
is( int @$rgb,   3,     'removed missing argument in value vector by clamp');
is( $rgb->[0],   0,     'clamped up  (R) value to minimum');
is( $rgb->[1],   1,     'clamped down (G) value to maximum');
is( $rgb->[2],  0.5,    'passed (B) value');

($rgb, my $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is( int @$d,    3,      'zero delta vector has right length');
is( $d->[0],    0,      'no delta in R component');
is( $d->[1],    0,      'no delta in G component');
is( $d->[2],    0,      'no delta in B component');

$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is( int @$d,   3,      'delta vector has right length');
is( $d->[0],  -0.1,    'R delta');
is( $d->[1],   0.3,    'G delta');
is( $d->[2],   0.6,    'B delta');

$rgb = $space->convert_from( 'RGB', [0, 0.01, 1]);
is( ref $rgb,   'ARRAY', 'converted XYZ values tuple into ADOBERGB tuple');
is( int @$rgb,   3,      'got three values');
is( $rgb->[0],   0,      'converted to minimal red value');
is( round_decimals($rgb->[1],9), 0.000773994, 'converted to mid magenta value');
is( $rgb->[2],   1,      'converted to maximal blue value');

$rgb = $space->convert_to( 'CIEXYZ', [1, 0.9, 0 ]);
is( ref $rgb,  'ARRAY',  'converted CMY values tuple into RGB tuple');
is( int @$rgb,   3,      'got three values');
is( $rgb->[0],   1,      'converted max red value');
is( round_decimals($rgb->[1],9),   0.954687172,    'converted green value');
is( $rgb->[2],   0,      'converted minimal blue value');



exit 0;
