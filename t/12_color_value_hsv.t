#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 57;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::HSV';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_hsv        = \&Graphics::Toolkit::Color::Value::HSV::check;
my $tr_hsv         = \&Graphics::Toolkit::Color::Value::HSV::trim;
my $d_hsv          = \&Graphics::Toolkit::Color::Value::HSV::distance;

ok( !$chk_hsv->(0,0,0),       'check hsl values works on lower bound values');
ok( !$chk_hsv->(359,100,100), 'check hsl values works on upper bound values');
warning_like {$chk_hsv->(0,0)}       {carped => qr/exactly 3/},   "check rgb got too few values";
warning_like {$chk_hsv->(0,0,0,0)}   {carped => qr/exactly 3/},   "check rgb got too many  values";
warning_like {$chk_hsv->(-1, 0,0)}   {carped => qr/hue value/},   "hue value is too small";
warning_like {$chk_hsv->(0.5, 0,0)}  {carped => qr/hue value/},   "hue value is not integer";
warning_like {$chk_hsv->(360, 0,0)}  {carped => qr/hue value/},   "hue value is too big";
warning_like {$chk_hsv->(0, -1, 0)}  {carped => qr/saturation value/}, "saturation value is too small";
warning_like {$chk_hsv->(0, 0.5, 0)} {carped => qr/saturation value/}, "saturation value is not integer";
warning_like {$chk_hsv->(0, 101,0)}  {carped => qr/saturation value/}, "saturation value is too big";
warning_like {$chk_hsv->(0,0, -1 )}  {carped => qr/value value/},  "value value is too small";
warning_like {$chk_hsv->(0,0, 0.5 )} {carped => qr/value value/},  "value value is not integer";
warning_like {$chk_hsv->(0,0, 101)}  {carped => qr/value value/},  "value value is too big";


my @hsv = $tr_hsv->();
is( int @hsv,  3,     'default color kicked in');
is( $hsv[0],   0,     'default color is black (H) no args');
is( $hsv[1],   0,     'default color is black (S) no args');
is( $hsv[2],   0,     'default color is black (V) no args');
@hsv = $tr_hsv->(1,2);
is( int @hsv,  3,     'missing values filled in');
is( $hsv[0],   1,     'passed color value (H)');
is( $hsv[1],   2,     'passed color value (S)');
is( $hsv[2],   0,     'default color value (V) was inserted');
@hsv = $tr_hsv->(1,2,3,4);
is( int @hsv,  3,     'superfluous value was trimmed');
is( $hsv[0],   1,     'default color is black (H) too many args');
is( $hsv[1],   2,     'default color is black (S) too many args');
is( $hsv[2],   3,     'default color is black (V) too many args');
@hsv = $tr_hsv->(-1,-1,-1);
is( int @hsv,  3,     'vector kept correct length');
is( $hsv[0], 359,     'too low hue value is rotated up');
is( $hsv[1],   0,     'too low green value is rounded up');
is( $hsv[2],   0,     'too low blue value is rounded up');

@hsv = $tr_hsv->(360, 101, 101);
is( int @hsv,  3,     'vector kept correct length');
is( $hsv[0],   0,     'too high hue value is rotated down');
is( $hsv[1], 100,     'too high saturation value is rounded down');
is( $hsv[2], 100,     'too high lightness value is rounded down');


@hsv = Graphics::Toolkit::Color::Value::HSV::from_rgb(127, 127, 127);
is( int @hsv,  3,     'converted color grey has three hsl values');
is( $hsv[0],   0,     'converted color grey has computed right hue value');
is( $hsv[1],   0,     'converted color grey has computed right saturation');
is( $hsv[2],  50,     'converted color grey has computed right lightness');

my @rgb = Graphics::Toolkit::Color::Value::HSV::to_rgb(0, 0, 50);
is( int @rgb,  3,     'converted back color grey has three rgb values');
is( $rgb[0], 128,     'converted back color grey has right red value');
is( $rgb[1], 128,     'converted back color grey has right green value');
is( $rgb[2], 128,     'converted back color grey has right blue value');
# hsv(220, 100%, 47%)
@hsv = Graphics::Toolkit::Color::Value::HSV::from_rgb(0, 40, 120);
is( int @hsv,  3,     'converted nice blue has three hsv values');
is( $hsv[0], 220,     'converted nice blue has computed right hue value');
is( $hsv[1], 100,     'converted nice blue has computed right saturation');
is( $hsv[2],  24,     'converted nice blue has computed right value');

@rgb = Graphics::Toolkit::Color::Value::HSV::to_rgb(220, 100, 24);
is( int @rgb,  3,     'converted back nice blue has three rgb values');
is( $rgb[0],   0,     'converted back nice blue has right red value');
is( $rgb[1],  40,     'converted back nice blue has right green value');
is( $rgb[2], 120,     'converted back nice blue has right blue value');


exit 0;
