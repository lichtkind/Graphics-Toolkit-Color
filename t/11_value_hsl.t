#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 65;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::HSL';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_hsl        = \&Graphics::Toolkit::Color::Value::HSL::check;
my $tr_hsl         = \&Graphics::Toolkit::Color::Value::HSL::trim;
my $d_hsl          = \&Graphics::Toolkit::Color::Value::HSL::delta;

ok( !$chk_hsl->(0,0,0),       'check hsl values works on lower bound values');
ok( !$chk_hsl->(359,100,100), 'check hsl values works on upper bound values');
warning_like {$chk_hsl->(0,0)}       {carped => qr/exactly 3/},   "check rgb got too few values";
warning_like {$chk_hsl->(0,0,0,0)}   {carped => qr/exactly 3/},   "check rgb got too many  values";
warning_like {$chk_hsl->(-1, 0,0)}   {carped => qr/hue value/},   "hue value is too small";
warning_like {$chk_hsl->(0.5, 0,0)}  {carped => qr/hue value/},   "hue value is not integer";
warning_like {$chk_hsl->(360, 0,0)}  {carped => qr/hue value/},   "hue value is too big";
warning_like {$chk_hsl->(0, -1, 0)}  {carped => qr/saturation value/}, "saturation value is too small";
warning_like {$chk_hsl->(0, 0.5, 0)} {carped => qr/saturation value/}, "saturation value is not integer";
warning_like {$chk_hsl->(0, 101,0)}  {carped => qr/saturation value/}, "saturation value is too big";
warning_like {$chk_hsl->(0,0, -1 )}  {carped => qr/lightness value/},  "lightness value is too small";
warning_like {$chk_hsl->(0,0, 0.5 )} {carped => qr/lightness value/},  "lightness value is not integer";
warning_like {$chk_hsl->(0,0, 101)}  {carped => qr/lightness value/},  "lightness value is too big";


my @hsl = $def->trim();
is( int @hsl,  3,     'default color is set');
is( $hsl[0],   0,     'default color is black (H) no args');
is( $hsl[1],   0,     'default color is black (S) no args');
is( $hsl[2],   0,     'default color is black (L) no args');
@hsl = $def->trim(1,2);
is( $hsl[0],   1,     'default color is black (H) too few args');
is( $hsl[1],   2,     'default color is black (S) too few args');
is( $hsl[2],   0,     'default color is black (L) too few args');
@hsl = $def->trim(1,2,3,4);
is( $hsl[0],   1,     'default color is black (H) too many args');
is( $hsl[1],   2,     'default color is black (S) too many args');
is( $hsl[2],   3,     'default color is black (L) too many args');;
@hsl = $def->trim(-1,-1,-1);
is( int @hsl,  3,     'color is trimmed up');
is( $hsl[0], 359,     'too low hue value is rotated up');
is( $hsl[1],   0,     'too low green value is trimmed up');
is( $hsl[2],   0,     'too low blue value is trimmed up');
@hsl = $def->trim(360, 101, 101);
is( int @hsl,  3,     'color is trimmed up');
is( $hsl[0],   0,     'too high hue value is rotated down');
is( $hsl[1], 100,     'too high saturation value is trimmed down');
is( $hsl[2], 100,     'too high lightness value is trimmed down');

@hsl = Graphics::Toolkit::Color::Value::HSL::from_rgb(127, 127, 127);
is( int @hsl,  3,     'converted color grey has three hsl values');
is( $hsl[0],   0,     'converted color grey has computed right hue value');
is( $hsl[1],   0,     'converted color grey has computed right saturation');
is( $hsl[2],  50,     'converted color grey has computed right lightness');

my @rgb = Graphics::Toolkit::Color::Value::HSL::to_rgb(0, 0, 50);
is( int @rgb,  3,     'converted back color grey has three rgb values');
is( $rgb[0], 127,     'converted back color grey has right red value');
is( $rgb[1], 127,     'converted back color grey has right green value');
is( $rgb[2], 127,     'converted back color grey has right blue value');

@rgb = Graphics::Toolkit::Color::Value::HSL::to_rgb(360, -10, 50);
is( int @rgb,  3,     'trimmed and converted back color grey');
is( $rgb[0], 127,     'right red value');
is( $rgb[1], 127,     'right green value');
is( $rgb[2], 127,     'right blue value');

@hsl = Graphics::Toolkit::Color::Value::HSL::from_rgb(0, 40, 120);
is( int @hsl,  3,     'converted nice blue has three hsl values');
is( $hsl[0], 220,     'converted nice blue has computed right hue value');
is( $hsl[1], 100,     'converted nice blue has computed right saturation');
is( $hsl[2],  24,     'converted nice blue has computed right lightness');

@rgb = Graphics::Toolkit::Color::Value::HSL::to_rgb(220, 100, 24);
is( int @rgb,  3,     'converted back nice blue has three rgb values');
is( $rgb[0],   0,     'converted back nice blue has right red value');
is( $rgb[1],  40,     'converted back nice blue has right green value');
is( $rgb[2], 122,     'converted back nice blue has right blue value');


exit 0;
