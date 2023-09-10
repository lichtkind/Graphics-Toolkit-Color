#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 37;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::YIQ';

my $def = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'YIQ',                     'color space has right name');
is( $def->dimensions,     3,                     'color space has 3 dimensions');

ok( !$def->check([0, -0.5959, -0.5227]),         'check YIO values works on lower bound values');
ok( !$def->check([1,  0.5959,  0.5227]),         'check YIO values works on upper bound values');
warning_like {$def->check([0,0])}        {carped => qr/needs 3 values/}, "check YIQ got too few values";
warning_like {$def->check([0, 0, 0, 0])} {carped => qr/needs 3 values/}, "check YIQ got too many values";

is( $def->check([0,0,0]),  undef,     'checked neutral values');
warning_like {$def->check([-0.1, 0, 0])}  {carped => qr/luminance value is below/},  "luminance value is too small";
warning_like {$def->check([ 1.1, 0,0])}  {carped => qr/luminance value is above/},   "luminance value is too big";
warning_like {$def->check([0, -0.6, 0])}  {carped => qr/in-phase value is below/},   "whiteness value is too small";
warning_like {$def->check([0, 0.6,0])}  {carped => qr/in-phase value is above/},     "whiteness value is too big";
warning_like {$def->check([0,0, -0.53 ])}  {carped => qr/quadrature value is below/},"quadrature value is too small";
warning_like {$def->check([0,0, 0.53])}  {carped => qr/quadrature value is above/},  "quadrature value is too big";



my @yiq = $def->deconvert( [ 0.5, 0.5, 0.5], 'RGB');
is( int @yiq,  3,     'converted color grey has three YIQ values');
is( $yiq[0], 0.5,     'converted color grey has computed right luminance value');
is( $yiq[1], 0.5,  'converted color grey has computed right in-phase');
is( $yiq[2], 0.5,  'converted color grey has computed right quadrature');

my @rgb = $def->convert( [0.5, 0.5, 0.5], 'RGB');
is( int @rgb,  3,     'converted back color grey has three rgb values');
is( $rgb[0],   0.5,   'converted back color grey has right red value');
is( $rgb[1],   0.5,   'converted back color grey has right green value');
is( $rgb[2],   0.5,   'converted back color grey has right blue value');

@yiq = $def->deconvert( [0.1, 0, 1], 'RGB');
is( int @yiq,  3,     'converted blue has three YIQ values');
is( close_enough( $yiq[0], 0.1439 )    ,  1 ,  'converted nice blue has right Y value');
is( close_enough( $yiq[1], 0.280407787),  1 ,  'converted nice blue has right I value');
is( close_enough( $yiq[2], 0.817916587),  1 ,  'converted nice blue has right Q value');
exit 0;

@rgb = $def->convert( [0.95555, 0.08, 0.18], 'RGB');
is( int @rgb,  3,     'converted back nice magenta');
is( close_enough( $rgb[0], 210/255), 1,   'right red value');
is( close_enough( $rgb[1], 20/255) , 1,   'right green value');
is( close_enough( $rgb[2], 70/255) , 1,   'right blue value');

@rgb = $def->convert( [0.83333, 0, 1], 'RGB'); # should become black despite color value
is( int @rgb,  3,     'converted black');
is( $rgb[0],   0,     'right red value');
is( $rgb[1],   0,     'right green value');
is( $rgb[2],   0,     'right blue value');


exit 0;

