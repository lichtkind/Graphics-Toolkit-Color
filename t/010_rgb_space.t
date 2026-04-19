#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 68;

my $rgb_axis   = [qw/red green blue/];
my $module = 'Graphics::Toolkit::Color::Space::Instance::RGB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got right return value by loading module');
is( $space->name,              'RGB',              'color space has right name');
is( $space->name('alias'),    'SRGB',              'color space has no alias name');
is( $space->is_name('rgb'),        1,              'asked for right space name');
is( $space->is_name('srgb'),       1,              'asked for right space name alias');
is( $space->is_name('lrgb'),       0,              'asked for wrong space name');
is( $space->axis_count,            3,              'color space has 3 axis');
is( $space->is_euclidean,          1,              'RGB is is_euclidean');
is( $space->is_cylindrical,        0,              'RGB is not cylindrical');

is( ref $space->check_value_shape( [0,0,0]),       'ARRAY', 'check RGB values works on lower bound values');
is( ref $space->check_value_shape( [255,255,255]), 'ARRAY', 'check RGB values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),              '', "RGB got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),       '', "RGB got too many values");
is( ref $space->check_value_shape( [-1, 0, 0]),         '', "red value is too small");
is( ref $space->check_value_shape( [0.5, 0, 0]),        '', "red value is not integer");
is( ref $space->check_value_shape( [256, 0, 0]),        '', "red value is too big");
is( ref $space->check_value_shape( [0, -1, 0]),         '', "green value is too small");
is( ref $space->check_value_shape( [0, 0.5, 0]),        '', "green value is not integer");
is( ref $space->check_value_shape( [0, 256, 0]),        '', "green value is too big");
is( ref $space->check_value_shape( [0, 0, -1 ] ),       '', "blue value is too small");
is( ref $space->check_value_shape( [0, 0, 0.5] ),       '', "blue value is not integer");
is( ref $space->check_value_shape( [0, 0, 256] ),       '', "blue value is too big");

my $rgb = $space->clamp([]);
is( int @$rgb,  3,     'clamp resets missing color to black');
is( $rgb->[0],   0,     'default color is black (R)');
is( $rgb->[1],   0,     'default color is black (G)');
is( $rgb->[2],   0,     'default color is black (B)');

$rgb = $space->clamp([1,2]);
is( $rgb->[0],   1,     'carry over first arg');
is( $rgb->[1],   2,     'carry over second arg');
is( $rgb->[2],   0,     'set missing color value to zero');

$rgb = $space->clamp([1.1, 2, 3, 4]);
is( int @$rgb,   3,     'left out the needless argument');
is( $rgb->[0],  1.1,    'not clamped badly rounded value (job of round)');
is( $rgb->[1],   2,     'kept second value');
is( $rgb->[2],   3,     'kept third value');

$rgb = $space->clamp([-1,10,256]);
is( int @$rgb,   3,     'clamp does not change number of negative values');
is( $rgb->[0],   0,     'too low red value is clamp up');
is( $rgb->[1],  10,     'in range green value is not touched');
is( $rgb->[2], 255,     'too large blue value is clamp down');

is(    $space->format([0,0,0],      'hex_string'), '#000000',     'converted black from rgb to hex');
is( uc $space->format([255,255,255],'HEX_string'), '#FFFFFF',     'converted white from rgb to hex');
is( uc $space->format([ 10, 20, 30],'hex_strinG'), '#0A141E',     'converted random color from rgb to hex');

($rgb, my $name) = $space->deformat('#332200');
is( $name,  'hex_string', 'recognized long hex string format');
is_tuple( $rgb, [51, 34, 0], $rgb_axis, 'got right values from long hex_string');

($rgb, $name) = $space->deformat('#DEF');
is( $name,  'hex_string', 'recognized short hex_string format');
is_tuple( $rgb, [221, 238, 255], $rgb_axis, 'got right values from short hex_string');

($rgb, $name) = $space->deformat([33, 44, 55]);
is( $name,     'array', 'could deformat ARRAY ref (RGB special)');
is_tuple( $rgb, [33, 44, 55], $rgb_axis, 'got right values from ARRAY');

($rgb, $name) = $space->deformat([rgb => 11, 22, 256]);
is( $name,     'named_array', 'recognized named_string format with in values');
is_tuple( $rgb, [11, 22, 256], $rgb_axis, 'got right values from named_string');

$rgb = $space->deformat(['CMY', 11, 22, 33]);
is( $rgb->[0],  undef,  'OO deformat reacts only to right name');

($rgb, $name) = $space->deformat('RGB: -1, 256, 3.3 ');
is( $name,  'named_string', 'recognized named_string format');
is_tuple( $rgb, [-1, 256, 3.3], $rgb_axis, 'got right values from named_string');

($rgb, $name) = $space->deformat('rgb:0,1,2');
is( $name,  'named_string', 'recognized named_string format without spaces between comma');
is_tuple( $rgb, [0, 1, 2], $rgb_axis, 'got right values from named_string');

$rgb = $space->deformat('cmy: 1,2,3.3');
is( $rgb->[0],  undef,  'deformat STRING reacts only to right space name');
is( $space->format([0,256,3.3], 'named_string'), 'rgb: 0, 256, 3.3', 'formated rgb triplet into value string');

($rgb, $name) = $space->deformat('rgb( -1 , 2.3, 4444)');
is( $name,    'css_string', 'recognized css_string format');
is_tuple( $rgb, [-1, 2.3, 4444], $rgb_axis, 'got right values from CSS_string');

is( $space->format([-1,2.3,4444], 'css_string'), 'rgb(-1, 2.3, 4444)', 'formated rgb triplet into css string');

$rgb = $space->format([0,256,3.3], 'named_array');
is( ref $rgb,  'ARRAY',  'formated into named ARRAY');
is( @$rgb,           4,  'named RGB tuple has 4 elements');
is( $rgb->[0],   'RGB',  'tuple color name space');
is( $rgb->[1],    0,     'red in minimal');
is( $rgb->[2],    256,   'green is too large');
is( $rgb->[3],    3.3,   'blue still has decimal');

is( $space->format([10,20,30], 'hex_string'), '#0A141E', 'formated rgb triplet into hex string');

my $d = $space->delta( [0,44,256], [256,88,0] );
is_tuple( $d, [256, 44, -256], $rgb_axis, 'computes in standard range distance');

$rgb = $space->denormalize( [0.3, 0.4, 0.5], 255, 0 );
is_tuple( $rgb, [76.5, 102, 127.5], $rgb_axis, 'denormalized tuple');

exit 0;
