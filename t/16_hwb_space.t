#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 37;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::HWB';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'HWB',                     'color space has right name');
is( $def->axis,           3,                     'color space has 3 axis');
is( ref $def->in_range([0, 0, 0]),     'ARRAY',   'check HWB values works on lower bound values');
is( ref $def->in_range([360,100,100]), 'ARRAY',   'check HWB values works on upper bound values');
is( ref $def->in_range([0,0]),              '',   "HWB got too few values");
is( ref $def->in_range([0, 0, 0, 0]),       '',   "HWB got too many values");
is( ref $def->in_range([-1, 0, 0]),         '',   "hue value is too small");
is( ref $def->in_range([1.1, 0, 0]),        '',   "hue is not integer");
is( ref $def->in_range([361, 0, 0]),        '',   "hue value is too big");
is( ref $def->in_range([0, -1, 0]),         '',   "whiteness value is too small");
is( ref $def->in_range([0, 1.1, 0]),        '',   "whiteness value is not integer");
is( ref $def->in_range([0, 101, 0]),        '',   "whiteness value is too big");
is( ref $def->in_range([0, 0, -1 ] ),       '',   "blackness value is too small");
is( ref $def->in_range([0, 0, 1.1] ),       '',   "blackness value is not integer");
is( ref $def->in_range([0, 0, 101] ),       '',   "blackness value is too big");


my $hwb = $def->deconvert( [ .5, .5, .5], 'RGB');
is( int @$hwb,   3,     'converted color grey has three hwb values');
is( $hwb->[0],   0,     'converted color grey has computed right hue value');
is( $hwb->[1],  .5,     'converted color grey has computed right whiteness');
is( $hwb->[2],  .5,     'converted color grey has computed right blackness');

my $rgb = $def->convert( [0, 0.5, .5], 'RGB');
is( int @$rgb,     3,   'converted back color grey has three rgb values');
is( $rgb->[0],   0.5,   'converted back color grey has right red value');
is( $rgb->[1],   0.5,   'converted back color grey has right green value');
is( $rgb->[2],   0.5,   'converted back color grey has right blue value');

$hwb = $def->deconvert( [210/255, 20/255, 70/255], 'RGB');
is( int @$hwb,  3,     'converted nice magents has three hwb values');
is( close_enough( $hwb->[0], 0.95555),  1,   'converted nice magenta has computed right hue value');
is( close_enough( $hwb->[1], 0.08,   ), 1,  'converted nice magenta has computed right whiteness');
is( close_enough( $hwb->[2], 0.18,   ), 1,  'converted nice magenta has computed right blackness');

$rgb = $def->convert( [0.95555, 0.08, 0.18], 'RGB');
is( int @$rgb,  3,     'converted back nice magenta');
is( close_enough( $rgb->[0], 210/255), 1,   'right red value');
is( close_enough( $rgb->[1], 20/255) , 1,   'right green value');
is( close_enough( $rgb->[2], 70/255) , 1,   'right blue value');

$rgb = $def->convert( [0.83333, 0, 1], 'RGB'); # should become black despite color value
is( int @$rgb,  3,     'converted black');
is( $rgb->[0],   0,     'right red value');
is( $rgb->[1],   0,     'right green value');
is( $rgb->[2],   0,     'right blue value');


exit 0;
