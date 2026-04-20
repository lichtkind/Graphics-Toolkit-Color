#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 40;

my $module = 'Graphics::Toolkit::Color::Space::Instance::ProPhotoRGB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,      'PROPHOTORGB',              'color space has name: "PROPHOTORGB"');
is( $space->name('alias'), 'ROMMRGB',              'color space has alias name is "ROMMRGB"');
is( $space->is_name('romm RGB'), 1,                'one way to write the space name');
is( $space->is_name('Pro-Photo RGB'), 1,           'another way to write the space name');
is( $space->is_name('RGB'),        0,              'SRGB is not ProPhoto SRGB');
is( $space->axis_count,            3,              'lin RGB color space has 3 axis');
is( $space->is_euclidean,          1,              'lin RGB is euclidean');
is( $space->is_cylindrical,        0,              'lin RGB is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('XYZ'),                        1,  'do only convert from and to rgb');
is( $space->can_convert('xyz'),                        1,  'color space name can be written lower case');
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
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], 'clamped empty tuple into default color (black)');

$rgb = $space->clamp([0, 1]);
is_tuple( $rgb, [0, 1, 0], [qw/red green blue/], 'clamp inserted zero for missing value');

$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], [qw/red green blue/], 'clamp changes values to min, max and removes superfluous values');

($rgb, my $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,    undef,     'array format is RGB only');

($rgb, $name) = $space->deformat('pro_photo_rgb: 0.2, 0.3, 0.7');
is( $name, 'named_string',     "recognized 'named_string' format");
is_tuple( $rgb, [0.2, 0.3, 0.7], [qw/red green blue/], "got values out of 'named_string'");

($rgb, $name) = $space->deformat('romm-rgb(0, 1, 0.7)');
is( $name, 'css_string',     "recognized 'CSS_string' format with alias space name");
is_tuple( $rgb, [0, 1, 0.7], [qw/red green blue/], "got values out of 'CSS_string'");

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is_tuple( $d, [0, 0, 0], [qw/red green blue/], "delta vector of a tuple with itself is zero");

$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is_tuple( $d, [-0.1, 0.3, 0.6], [qw/red green blue/], "correct delta vector between two tuple");

$rgb = $space->convert_to( 'XYZ', [0, 0, 0 ]);
is_tuple( $rgb, [0, 0, 0], [qw/red green blue/], "convert black to XYZ");

my $xyz = $space->convert_from( 'XYZ', [0, 0, 0 ]);
is_tuple( $xyz, [0, 0, 0], [qw/X Y Z/], "convert black back from XYZ");

$rgb = $space->convert_to( 'XYZ', [1, 1, 1 ]);
is_tuple( $rgb, [1, 1, 1], [qw/red green blue/], "convert white to XYZ");

exit 0;

$rgb = $space->convert_to( 'XYZ', [1, 0.9, 0 ]);
is_tuple( $rgb, [-0.1, 0.3, 0.6], [qw/red green blue/], "convert deep yellow to XYZ");


$rgb = $space->convert_from( 'RGB', [0, 0.01, 1]);

exit 0;
# $space->round($rgb, 9)
