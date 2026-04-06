#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 130;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color::Space::Hub;

my $convert       = \&Graphics::Toolkit::Color::Space::Hub::convert;
my $deconvert     = \&Graphics::Toolkit::Color::Space::Hub::deconvert;

########################################################################
is( ref $convert->(),                       '', 'convert needs at least one argument');
is( ref $convert->({r => 1,g => 1,b => 1}), '', 'convert only value ARRAY no HASH');
is( ref $convert->([0,0]),                  '', 'tuple has not enough values');
is( ref $convert->([0,0,0], 'Jou'),         '', 'convert needs a valid target name space');

is( ref $deconvert->(),                       '', 'deconvert needs at least one argument');
is( ref $deconvert->('JAP'),                  '', 'deconvert needs a valid source space name name');
is( ref $deconvert->('RGB', {r => 1,g => 1,b => 1}), '', 'deconvert tule as ARRAY');
is( ref $deconvert->('JAP', [0,0,0]),                '', 'space name bad but tuple good');

#### simple conversion #################################################
my $tuple = $convert->([0,1/255,1], 'RGB');
is( ref $tuple,      'ARRAY', 'did minimal none conversion');
is( int @$tuple,           3, 'RGB has 3 axis');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],           1, 'green value is right');
is( $tuple->[2],         255, 'blue value is right');

$tuple = $convert->([0,1/255,1], 'RGB', 'normal');
is( int @$tuple,           3, 'wanted  normalized result');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],       1/255, 'green value is right');
is( $tuple->[2],           1, 'blue value is right');

$tuple = $convert->([.1, .2, .3], 'YUV', 'normal', [1, .1, 0] ,'YUV');
is( int @$tuple,           3, 'take source values instead of convert RGB');
is( $tuple->[0],           1, 'Red value is right');
is( $tuple->[1],          .1, 'green value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $convert->([.1, .2, .3], 'YUV', undef, [1, 0.1, 0] ,'YUV');
is( int @$tuple,           3, 'get normalized source values');
is( $tuple->[0],           1, 'Red value is right');
is( $tuple->[1],         -.4, 'green value is right');
is( $tuple->[2],         -.5, 'blue value is right');

$tuple = $convert->([0, 0.1, 1], 'CMY');
is( int @$tuple,           3, 'invert RGB values');
is( $tuple->[0],           1, 'cyan value is right');
is( $tuple->[1],         0.9, 'magenta value is right');
is( $tuple->[2],           0, 'yellow value is right');

$tuple = $deconvert->([1, 0.9, 0], 'CMY', 'normal');
is( ref $tuple,      'ARRAY', 'deconvert from CMY to normal RGB');
is( int @$tuple,           3, 'invert CMY values');
is( $tuple->[0],           0, 'cyan value is right');
is( $tuple->[1],         0.1, 'magenta value is right');
is( $tuple->[2],           1, 'yellow value is right');

#### chained conversion ################################################
$tuple = $convert->([0, 0, 0], 'XYZ');
is( ref $tuple,                'ARRAY', 'convert black to XYZ (2 hop conversion)');
is( int @$tuple,                     3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 5), 0, 'X value is right');
is( round_decimals( $tuple->[1], 5), 0, 'Y value is right');
is( round_decimals( $tuple->[2], 5), 0, 'Z value is right');

$tuple = $deconvert->([0, 0, 0], 'XYZ');
is( ref $tuple,                'ARRAY', 'convert black from XYZ (2 hop conversion)');
is( int @$tuple,                     3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 5), 0, 'R value is right');
is( round_decimals( $tuple->[1], 5), 0, 'G value is right');
is( round_decimals( $tuple->[2], 5), 0, 'B value is right');

$tuple = $convert->([1, 1, 1], 'XYZ');
is( ref $tuple,                'ARRAY', 'convert white to XYZ (2 hop conversion)');
is( int @$tuple,                     3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 6), 95.047, 'X value is right');
is( round_decimals( $tuple->[1], 4), 100, 'Y value is right');
is( round_decimals( $tuple->[2], 6), 108.883, 'Z value is right');

$tuple = $deconvert->([1, 1, 1], 'XYZ');
is( ref $tuple,                  'ARRAY', 'deconvert white from XYZ (2 hop conversion)');
is( int @$tuple,                       3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 4), 255, 'R value is right');
is( round_decimals( $tuple->[1], 4), 255, 'G value is right');
is( round_decimals( $tuple->[2], 4), 255, 'B value is right');

$tuple = $convert->([1, 1, 1], 'XYZ', 'normal');
is( ref $tuple,                'ARRAY', 'convert white to XYZ (2 hop conversion) and normalisation');
is( int @$tuple,                     3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 6), 1, 'X value is right');
is( round_decimals( $tuple->[1], 6), 1, 'Y value is right');
is( round_decimals( $tuple->[2], 6), 1, 'Z value is right');

$tuple = $convert->([.1, .2, .3], 'XYZ');
is( ref $tuple,                'ARRAY', 'convert dark blue to XYZ');
is( int @$tuple,                     3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 4), 2.9187, 'X value is right');
is( round_decimals( $tuple->[1], 4), 3.1093, 'Y value is right');
is( round_decimals( $tuple->[2], 4), 7.3739, 'Z value is right');

$tuple = $deconvert->([0.030707966, 0.031093, 0.067723152], 'XYZ', 'normal');
is( ref $tuple,                  'ARRAY', 'deconvert dark blue from XYZ (2 hop conversion)');
is( int @$tuple,                       3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 4), 0.1, 'R value is right');
is( round_decimals( $tuple->[1], 4), 0.2, 'G value is right');
is( round_decimals( $tuple->[2], 4), 0.3, 'B value is right');

$tuple = $convert->([1, 1, 1], 'LAB', 'normal');
is( ref $tuple,      'ARRAY', 'convert white to LAB (3 hop conversion)');
is( int @$tuple,           3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 5), 1, 'L value is right');
is( round_decimals( $tuple->[1], 5), 0.5, 'a value is right');
is( round_decimals( $tuple->[2], 5), 0.5, 'b value is right');

$tuple = $deconvert->([1, 0.5, 0.5], 'LAB');
is( ref $tuple,                  'ARRAY', 'deconvert white from LAB (3 hop conversion)');
is( int @$tuple,                       3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 4), 255, 'R value is right');
is( round_decimals( $tuple->[1], 4), 255, 'G value is right');
is( round_decimals( $tuple->[2], 4), 255, 'B value is right');

$tuple = $convert->([.1, .2, .3], 'CIELAB');
is( ref $tuple,                'ARRAY', 'convert dark blue to CIELAB');
is( int @$tuple,                     3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 4), 20.4762, 'L value is right');
is( round_decimals( $tuple->[1], 4), -0.6518, 'A value is right');
is( round_decimals( $tuple->[2], 4), -18.632, 'B value is right');

$tuple = $deconvert->([.204762, 0.4993482, 0.45341975], 'CIELAB', 'normal');
is( ref $tuple,                  'ARRAY', 'deconvert white from LAB (3 hop conversion)');
is( int @$tuple,                       3, 'got 3 value tuple');
is( round_decimals( $tuple->[0], 5), 0.1, 'R value is right');
is( round_decimals( $tuple->[1], 5), 0.2, 'G value is right');
is( round_decimals( $tuple->[2], 5), 0.3, 'B value is right');

$tuple = $convert->([1, 1/255, 0], 'CIELCHab');
is( int @$tuple,           3, 'convert bright red to LCHab (4 hop conversion)');
is( round_decimals( $tuple->[0],  3),  53.264, 'L value is right');
is( round_decimals( $tuple->[1],  3), 104.505, 'C value is right');
is( round_decimals( $tuple->[2],  3),  40.026, 'H value is right');

$tuple = $convert->([1, 1/255, 0], 'CIELCHab', 1);
is( int @$tuple,           3, 'convert bright red to normalized LCH');
is( round_decimals( $tuple->[0],  5), .53264, 'L value is right');
is( round_decimals( $tuple->[1],  5), .19389, 'C value is right');
is( round_decimals( $tuple->[2],  5), 0.11118, 'H value is right');

$tuple = $convert->([0.1, 0.2, 0.9], 'CIELCHuv');
is( int @$tuple,           3, 'convert bright blue to LCHuv (4 hop conversion)');
is( round_decimals( $tuple->[0],  4),  34.5264, 'L value is right');
is( round_decimals( $tuple->[1],  4), 119.3958, 'C value is right');
is( round_decimals( $tuple->[2],  5), 264.63634, 'H value is right'); # ...64 is right

$tuple = $deconvert->([0.3453, 0.4575, 0.7351], 'CIELCHuv', 'normal');
is( int @$tuple,           3, 'deconvert bright blue back to normal RGB');
is( round_decimals( $tuple->[0],  4), .1, 'R value is right');
is( round_decimals( $tuple->[1],  4), .2, 'G value is right');
is( round_decimals( $tuple->[2],  3), .9, 'B value is right');

########################################################################
$tuple = $deconvert->( [0,1/255,1], 'RGB');
is( ref $tuple,      'ARRAY', 'did minimal none deconversion');
is( int @$tuple,           3, 'RGB has 3 axis');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],           1, 'green value is right');
is( $tuple->[2],         255, 'blue value is right');

$tuple = $deconvert->( [0,1/255,1], 'RGB', 'normal');
is( int @$tuple,           3, 'wanted  normalized result');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],       1/255, 'green value is right');
is( $tuple->[2],           1, 'blue value is right');

$tuple = $deconvert->( [0, 0.1, 1], 'CMY' );
is( int @$tuple,           3, 'invert values from CMY');
is( $tuple->[0],         255, 'red value is right');
is( $tuple->[1],       229.5, 'green  value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $deconvert->( [0, 0.1, 1], 'CMY', 'normal' );
is( int @$tuple,           3, 'invert values from CMY');
is( $tuple->[0],           1, 'red value is right');
is( $tuple->[1],         0.9, 'green  value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $deconvert->( [0, 0.5, 0.5], 'LAB' );
is( int @$tuple,           3, 'convert black from LAB');
is( round_decimals( $tuple->[0], 5), 0, 'red value is right');
is( round_decimals( $tuple->[1], 5), 0, 'green value is right');
is( round_decimals( $tuple->[2], 5), 0, 'blue value is right');

$tuple = $deconvert->( [.53264, 104.505/539, 40.026/360], 'LCH', 1);
is( int @$tuple,           3, 'convert bright red from LCH');
is( round_decimals( $tuple->[0], 5), 1, 'L value is right');
is( round_decimals( $tuple->[1], 4), 0.0039, 'C value is right');
is( round_decimals( $tuple->[2], 5), 0, 'H value is right');

########################################################################

exit 0;
