#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 67;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::RGB';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');

my $chk_rgb        = \&Graphics::Toolkit::Color::Value::RGB::check;
my $rgb2h          = \&Graphics::Toolkit::Color::Value::RGB::hex_from_rgb;

ok( !$chk_rgb->(0,0,0),       'check rgb values works on lower bound values');
ok( !$chk_rgb->(255,255,255), 'check rgb values works on upper bound values');
warning_like {$chk_rgb->(0,0)}       {carped => qr/exactly 3/},   "check rgb got too few values";
warning_like {$chk_rgb->(0,0,0,0)}   {carped => qr/exactly 3/},   "check rgb got too many  values";
warning_like {$chk_rgb->(-1, 0,0)}   {carped => qr/red value/},   "red value is too small";
warning_like {$chk_rgb->(0.5, 0,0)}  {carped => qr/red value/},   "red value is not integer";
warning_like {$chk_rgb->(256, 0,0)}  {carped => qr/red value/},   "red value is too big";
warning_like {$chk_rgb->(0, -1, 0)}  {carped => qr/green value/}, "green value is too small";
warning_like {$chk_rgb->(0, 0.5, 0)} {carped => qr/green value/}, "green value is not integer";
warning_like {$chk_rgb->(0, 256,0)}  {carped => qr/green value/}, "green value is too big";
warning_like {$chk_rgb->(0,0, -1 )}  {carped => qr/blue value/},  "blue value is too small";
warning_like {$chk_rgb->(0,0, 0.5 )} {carped => qr/blue value/},  "blue value is not integer";
warning_like {$chk_rgb->(0,0, 256)}  {carped => qr/blue value/},  "blue value is too big";

my @rgb = $def->clamp();
is( int @rgb,  3,     'clamp resets missing color to black');
is( $rgb[0],   0,     'default color is black (R)');
is( $rgb[1],   0,     'default color is black (G)');
is( $rgb[2],   0,     'default color is black (B)');
@rgb = $def->clamp(1,2);
is( $rgb[0],   1,     'carry over first arg');
is( $rgb[1],   2,     'carry over second arg');
is( $rgb[2],   0,     'set missing color value to zero');
@rgb = $def->clamp(1.1, 2, 3, 4);
is( $rgb[0],   1,     'clamped none int value down');
is( $rgb[1],   2,     'carried color is black (G) took second of too many args');
is( $rgb[2],   3,     'default color is black (B) too third of too many args');
is( int @rgb,  3,     'left out the needless argument');
@rgb = $def->clamp(-1,-1,-1);
is( int @rgb,  3,     'clamp does not change number of negative values');
is( $rgb[0],   0,     'too low red value is trimmed up');
is( $rgb[1],   0,     'too low green value is trimmed up');
is( $rgb[2],   0,     'too low blue value is trimmed up');
@rgb = $def->clamp(256, 256, 256);
is( int @rgb,  3,     'trim do not change number of positive values');
is( $rgb[0], 255,     'too high red value is trimmed down');
is( $rgb[1], 255,     'too high green value is trimmed down');
is( $rgb[2], 255,     'too high blue value is trimmed down');

is( $rgb2h->(0,0,0),          '#000000',     'converted black from rgb to hex');
is( uc $rgb2h->(255,255,255), '#FFFFFF',     'converted white from rgb to hex');
is( uc $rgb2h->( 10, 20, 30), '#0A141E',     'converted random color from rgb to hex');

@rgb = Graphics::Toolkit::Color::Value::RGB::rgb_from_hex('#000000');
is( $rgb[0],   0,     'converted black from hex to RGB red is correct');
is( $rgb[1],   0,     'converted black from hex to RGB green is correct');
is( $rgb[2],   0,     'converted black from hex to RGB blue is correct');

@rgb = Graphics::Toolkit::Color::Value::RGB::rgb_from_hex('#FFF');
is( $rgb[0], 255,     'converted white (short form) from hex to RGB red is correct');
is( $rgb[1], 255,     'converted white (short form) from hex to RGB green is correct');
is( $rgb[2], 255,     'converted white (short form) from hex to RGB blue is correct');

@rgb = Graphics::Toolkit::Color::Value::RGB::rgb_from_hex('#0a141e');
is( $rgb[0],  10,     'deformatted random color (lower case) from hex to RGB red is correct');
is( $rgb[1],  20,     'deformatted random color (lower case) from hex to RGB green is correct');
is( $rgb[2],  30,     'deformatted random color (lower case) from hex to RGB blue is correct');

@rgb = $def->deformat('#0A141e');
is( $rgb[0],  10,     'OO deformat random color (upper case) from hex to RGB red is correct');
is( $rgb[1],  20,     'OO deformat random color (upper case) from hex to RGB green is correct');
is( $rgb[2],  30,     'OO deformat random color (upper case) from hex to RGB blue is correct');

@rgb = $def->deformat([ 33, 44, 55]);
is( int @rgb,  3,     'OO deformat ARRAY: got 3 values');
is( $rgb[0],  33,     'OO deformat ARRAY to RGB red is correct');
is( $rgb[1],  44,     'OO deformat ARRAY to RGB green is correct');
is( $rgb[2],  55,     'OO deformat ARRAY to RGB blue is correct');

@rgb = $def->deformat([rgb => 11, 22, 33]);
is( int @rgb,  3,     'OO deformat lc named ARRAY: got 3 values');
is( $rgb[0],  11,     'OO deformat lc named ARRAY to RGB red is correct');
is( $rgb[1],  22,     'OO deformat lc named ARRAY to RGB green is correct');
is( $rgb[2],  33,     'OO deformat lc named ARRAY to RGB blue is correct');

@rgb = $def->deformat(['RGB', 11, 22, 33]);
is( int @rgb,  3,     'OO deformat uc named ARRAY: got 3 values');
is( $rgb[0],  11,     'OO deformat uc named ARRAY to RGB red is correct');
is( $rgb[1],  22,     'OO deformat uc named ARRAY to RGB green is correct');
is( $rgb[2],  33,     'OO deformat uc named ARRAY to RGB blue is correct');

@rgb = $def->deformat(['CMY', 11, 22, 33]);
is( $rgb[0],  undef,  'OO deformat reacts only to right name');

@rgb = $def->deformat('rgb: 1,2,3.3');
is( int @rgb,  3,     'OO deformat STRING: got 3 values');
is( $rgb[0],   1,     'OO deformat STRING to RGB red is correct');
is( $rgb[1],   2,     'OO deformat STRING to RGB green is correct');
is( $rgb[2], 3.3,     'OO deformat STRING to RGB blue is correct');

@rgb = $def->deformat('cmy: 1,2,3.3');
is( $rgb[0],  undef,  'OO deformat STRING reacts only to right space name');

exit 0;
