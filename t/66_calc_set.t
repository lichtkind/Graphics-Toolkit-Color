#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 140;
BEGIN { unshift @INC, 'lib', '../lib'}

my $module = 'Graphics::Toolkit::Color::SetCalculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
use_ok( $module, 'could load the module');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $XYZ = Graphics::Toolkit::Color::Space::Hub::get_space('XYZ');
my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $red  = Graphics::Toolkit::Color::Values->new_from_any_input('red');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');
my (@colors, $values);

#### complement ########################################################
my $complement = \&Graphics::Toolkit::Color::SetCalculator::complement;

#### gradient ##########################################################
# @:colors, +steps, +tilt, :space --> @:values
my $gradient = \&Graphics::Toolkit::Color::SetCalculator::gradient;
@colors = $gradient->([$black, $white], 2, 0, $RGB);
is( int @colors,                       2,  'gradient has length of two');
is( $colors[0]->name,            'black',  'first one is black');
is( $colors[1]->name,            'white',  'second one is white');

@colors = $gradient->([$black, $white], 3, 0, $RGB);
is( int @colors,                        3,  'gradient has length of three');
is( $colors[0]->name,             'black',  'first one is black');
is( $colors[1]->name,              'gray',  'second one is grey');
is( $colors[2]->name,             'white',  'third one is white');

@colors = $gradient->([$blue, $white], 4, 0, $RGB);
is( int @colors,                       4,   '4 colors from blue to white');
is( $colors[0]->name,             'blue',   'first one is blue');
is( ref $colors[1],           $value_ref,   'second one is a color value obj');
is( ref $colors[2],           $value_ref,   'third one is a color value obj');
is( $colors[3]->name,            'white',   'fourth one is blue');

$values = $colors[1]->in_shape();
is( ref $values,                   'ARRAY',   'RGB values of color 2');
is( int @$values,                        3,   'are 3 values');
is( $values->[0],                       85,   'red value is right');
is( $values->[1],                       85,   'green value is right');
is( $values->[2],                      255,   'blue value is right');
$values = $colors[2]->in_shape();
is( $values->[0],                      170,   'red value of third color is right');

@colors = $gradient->([$red, $white], 3, 0, $HSL);
is( int @colors,                         3,    'got 3 color gradient in HSL');
$values = $colors[0]->in_shape('HSL');
is( $values->[0],                        0,    'hue of red is zero');
is( $values->[1],                      100,    'full saturation of red in HSL');
is( $values->[2],                       50,    'half lightness of red in HSL');
$values = $colors[1]->in_shape('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       50,    'full saturation of red in HSL');
is( $values->[2],                       75,    '3/4 lightness of red in HSL');
$values = $colors[2]->in_shape('HSL');
is( $values->[0],                        0,    'hue of white is zero');
is( $values->[1],                        0,    'no saturation of white in HSL');
is( $values->[2],                      100,    'full lightness of white in HSL');

@colors = $gradient->([$red, $white], 3, 1, $HSL);
$values = $colors[1]->in_shape('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       63,    '5/8 rose saturation in HSL gradient with tilt');
is( $values->[2],                       69,    '5/8 rose lightness in HSL');
@colors = $gradient->([$red, $white], 3, -1, $HSL);
$values = $colors[1]->in_shape('HSL');
is( $values->[0],                        0,    'hue of rose is zero');
is( $values->[1],                       38,    '3/8 rose saturation in HSL gradient with tilt');
is( $values->[2],                       81,    '3/8 rose lightness in HSL');

@colors = $gradient->([$red, $white, $blue], 9, 0, $RGB);
is( int @colors,                         9,    'got 9 color gradient in RGB');
is( $colors[0]->name,                'red',    'starting with red');
is( $colors[4]->name,              'white',    'white is in the middle');
is( $colors[8]->name,               'blue',    'blue is at the end');
$values = $colors[5]->in_shape('RGB');
is( ref $values,                  'ARRAY',      'get RGB values inside multi segment gradient');
is( $values->[0],                     191,      'red value is right');
is( $values->[1],                     191,      'green value is right');
is( $values->[2],                     255,      'blue value is right');

#### cluster ###########################################################
my $cluster = \&Graphics::Toolkit::Color::SetCalculator::cluster;

exit 0;
