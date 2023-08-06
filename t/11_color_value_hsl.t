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
my $d_hsl          = \&Graphics::Toolkit::Color::Value::HSL::distance;

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


my @hsl = $tr_hsl->();
is( int @hsl,  3,     'default color is set');
is( $hsl[0],   0,     'default color is black (H) no args');
is( $hsl[1],   0,     'default color is black (S) no args');
is( $hsl[2],   0,     'default color is black (L) no args');
@hsl = $tr_hsl->(1,2);
is( $hsl[0],   1,     'default color is black (H) too few args');
is( $hsl[1],   2,     'default color is black (S) too few args');
is( $hsl[2],   0,     'default color is black (L) too few args');
@hsl = $tr_hsl->(1,2,3,4);
is( $hsl[0],   1,     'default color is black (H) too many args');
is( $hsl[1],   2,     'default color is black (S) too many args');
is( $hsl[2],   3,     'default color is black (L) too many args');;
@hsl = $tr_hsl->(-1,-1,-1);
is( int @hsl,  3,     'color is trimmed up');
is( $hsl[0], 359,     'too low hue value is rotated up');
is( $hsl[1],   0,     'too low green value is trimmed up');
is( $hsl[2],   0,     'too low blue value is trimmed up');
@hsl = $tr_hsl->(360, 101, 101);
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


warning_like {$d_hsl->( []) }                     {carped => qr/two triplets/},"can't get distance without hsl values";
warning_like {$d_hsl->( [1,1,1],[1,1,1],[1,1,1])} {carped => qr/two triplets/},'too many array arg';
warning_like {$d_hsl->( [1,2],[1,2,3])}           {carped => qr/two triplets/},'first color is missing a value';
warning_like {$d_hsl->( [1,2,3],[2,3])}           {carped => qr/two triplets/},'second color is missing a value';
warning_like {$d_hsl->( [-1,2,3],[1,2,3])}        {carped => qr/hue value/},   'first hue value is too small';
warning_like {$d_hsl->( [1,2,3],[360,2,3])}       {carped => qr/hue value/},   'second hue value is too large';
warning_like {$d_hsl->( [1,-1,3],[2,10,3])}       {carped => qr/saturation value/},'first saturation value is too small';
warning_like {$d_hsl->( [1,2,3],[2,101,3])}       {carped => qr/saturation value/},'second saturation value is too large';
warning_like {$d_hsl->( [1,1,-1],[2,10,3])}       {carped => qr/lightness value/}, 'first lightness value is too small';
warning_like {$d_hsl->( [1,2,3],[2,1,101])}       {carped => qr/lightness value/}, 'second lightness value is too large';

is( Graphics::Toolkit::Color::Value::HSL::distance([1, 2, 3], [  2, 6, 11]), 9,     'compute hsl distance');
is( Graphics::Toolkit::Color::Value::HSL::distance([0, 2, 3], [359, 6, 11]), 9,     'compute hsl distance (test circular property of hsl)');

exit 0;
