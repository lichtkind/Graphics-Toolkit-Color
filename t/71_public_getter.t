#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 60;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';
use Graphics::Toolkit::Color qw/color/;

my $red   = color('red');
my $blue  = color('blue');
my $black = color('black');
my $white = color('white');

exit 0;

__END__
values name closest_name distance

my $red = Graphics::Toolkit::Color->new('red');
my @rgb = $red->values;
is( ref $red,        $module, 'could create object by name');
is( $rgb[0],           255, 'named red has correct red component value');
is( $rgb[1],             0, 'named red has correct green component value');
is( $rgb[2],             0, 'named red has correct blue component value');
@rgb = $red->values( as => 'list' );
is( $rgb[0],           255, 'correct red in explicit list format');
is( $rgb[1],             0, 'correct green in explicit list format');
is( $rgb[2],             0, 'correct blue in explicit list format');
my @hsl = $red->values( 'HSL' );
is( $hsl[0],               0, 'named red has correct hue component value');
is( $hsl[1],             100, 'named red has correct saturation component value');
is( $hsl[2],              50, 'named red has correct lightness component value');
is( $red->name,        'red', 'named red has correct name');
my $hex = $red->values(as => 'hex');
is( ref $hex, '', 'hex format has no ref value');
is( $hex, '#ff0000', 'named red has correct hex value');

my $rgb_hash = $red->values(as=>'HASH');
is(ref $rgb_hash, 'HASH', 'get HASH ref in HASH format');
is(int keys(%$rgb_hash),   3, 'HASH has right amount of keys');
is( $rgb_hash->{'red'},  255, 'named red has correct red value in rgb HASH');
is( $rgb_hash->{'green'},  0, 'named red has correct green value in rgb HASH');
is( $rgb_hash->{'blue'},   0, 'named red has correct blue value in rgb HASH');

my $hsl_hash = $red->values(in => 'HSL', as=>'char_HASH');
is(ref $hsl_hash, 'HASH', 'named red has correct hsl HASH');
is(int keys(%$hsl_hash),       3, 'HASH has right amount of keys');
is( $hsl_hash->{'h'},          0, 'named red has correct hue value in hsl HASH');
is( $hsl_hash->{'s'},        100, 'named red has correct saturation value in hsl HASH');
is( $hsl_hash->{'l'},         50, 'named red has correct lightness value in hsl HASH');
my $cc = Graphics::Toolkit::Color->new(15,12,13);
is( $cc->new(15,12,13)->values(as => 'string'), 'rgb: 15, 12, 13', 'random color does stringify correctly');
is( $cc->new(15,12,13)->values(as => 'css_string'), 'rgb(15,12,13)', 'random color does stringify correctly');
my $na = $cc->new(15,12,13)->values(as => 'array');
is( ref $na,        'ARRAY', 'named array output is ARRAY ref');
is( int @$na,             4, 'ARRAY has right length');
is( $na->[0],         'rgb', 'named array output is ARRAY ref');
is( $na->[1],            15, 'correct red value');
is( $na->[2],            12, 'correct green value');
is( $na->[3],            13, 'correct blue value');

$red = Graphics::Toolkit::Color->new('#FF0000');
is( ref $red,        $module, 'could create object by hex value');
is( $red->values(as => 'hex'), '#ff0000', 'red has correct value in hex format');
is( $red->name,         'red', 'hex red has correct name');
is(($red->values)[0],     255, 'hex red has correct rgb red component value');
is(($red->values)[1],       0, 'hex red has correct rgb green component value');
is(($red->values)[2],       0, 'hex red has correct rgb blue component value');
my @hwb = $red->values( 'HWB');
is($hwb[0],                 0, 'hex red has correct hsl hue component value');
is($hwb[1],                 0, 'hex red has correct hsl whitness component value');
is($hwb[2],                 0, 'hex red has correct hsl blackness component value');

$red = Graphics::Toolkit::Color->new('#f00');
is( ref $red,     $module, 'could create object by short hex value');
is( $red->name,        'red', 'short hex red has correct name');

$red = Graphics::Toolkit::Color->new('RGB: 255,0 ,0  ');
is( ref $red,         $module, 'could create object by RGB string');
is( $red->name,         'red', 'got correct name from RGB string');
is(($red->values)[0],     255, 'red value from RGB string format');
is(($red->values)[1],       0, 'green value from RGB string format');
is(($red->values)[2],       0, 'blue value from RGB string format');

$red = Graphics::Toolkit::Color->new('rgb( 255, 0 ,0 )');
is( ref $red,         $module, 'could create object by RGB css_string');
is( $red->name,         'red', 'got correct name from RGB css_string');
is(($red->values)[0],     255, 'red value from RGB css_string format');
is(($red->values)[1],       0, 'green value from RGB css_string format');
is(($red->values)[2],       0, 'blue value from RGB css_string format');

$red = Graphics::Toolkit::Color->new([255, 0, 0]);
is( ref $red, $module, 'could create object by RGB array ref');
is( $red->name,        'red', 'array ref red has correct name');
is(($red->values)[0],     255, 'red value from default ARRAY format');
is(($red->values)[1],       0, 'green value from default ARRAY format');
is(($red->values)[2],       0, 'blue value from default ARRAY format');

$red = Graphics::Toolkit::Color->new([RGB => 255, 0, 0]);
is( ref $red, $module, 'could create object by RGB named ARRAY ref');
is( $red->name,         'red', 'correct name from named ARRAY ref');
is(($red->values)[0],     255, 'red value from named ARRAY ref format');
is(($red->values)[1],       0, 'green value from named ARRAY ref format');
is(($red->values)[2],       0, 'blue value from named ARRAY ref format');

$red = Graphics::Toolkit::Color->new(RGB => 255, 0, 0);
is( ref $red, $module, 'could create object by RGB named ARRAY');
is( $red->name,         'red', 'correct name from named ARRAY');
is(($red->values)[0],     255, 'red value from named ARRAY format');
is(($red->values)[1],       0, 'green value from named ARRAY format');
is(($red->values)[2],       0, 'blue value from named ARRAY format');

$red = Graphics::Toolkit::Color->new(r => 255, g => 0, b => 0);
is( ref $red, $module, 'could create object by RGB named args');
is( $red->name,        'red', 'named arg red has correct name');
is(($red->values)[0],     255, 'red value from default char_hash format');
is(($red->values)[1],       0, 'green value from default char_hash format');
is(($red->values)[2],       0, 'blue value from default char_hash format');

$red = Graphics::Toolkit::Color->new({Red => 255, Green => 0, Blue => 0 });
is( ref $red, $module, 'could create object by RGB hash ref');
is( $red->name,        'red', 'got correct color name from HASH ref');
is(($red->values)[0],     255, 'red value from default HASH format');
is(($red->values)[1],       0, 'green value from default HASH format');
is(($red->values)[2],       0, 'blue value from default HASH format');

$red = Graphics::Toolkit::Color->new({h => 0, s => 100, l => 50 });
is( ref $red, $module, 'could create object by HSL hash ref');
is( $red->name,         'red', 'got name from hsl char HASH ref');
is(($red->values)[0],     255, 'red value from hsl char HASH ref format');
is(($red->values)[1],       0, 'green value from hsl char HASH ref format');
is(($red->values)[2],       0, 'blue value from hsl char HASH ref format');

$red = Graphics::Toolkit::Color->new( Hue => 0, Saturation => 100, Lightness => 50 );
is( ref $red, $module, 'could create object by HSL named args');
is( $red->name,        'red', 'hash ref red has correct name');
is(($red->values)[0],     255, 'red value from hsl HASH format');
is(($red->values)[1],       0, 'green value from hsl HASH format');
is(($red->values)[2],       0, 'blue value from hsl HASH format');

my $green = Graphics::Toolkit::Color->new(0, 128, 0);
is( ref $green, $module, 'could create object by positional RGB');
is( $green->name,       'green', 'positional red has correct name');
is(($green->values)[0],       0, 'green has correct rgb red component value');
is(($green->values)[1],     128, 'green has correct rgb green component value');
is(($green->values)[2],       0, 'green has correct rgb blue component value');
is(($green->values('HSL'))[0],     120, 'green has correct rgb red component value');
is(($green->values('HSL'))[1],     100, 'green has correct rgb green component value');
is(($green->values('HSL'))[2],      25, 'green has correct rgb blue component value');

my $c = Graphics::Toolkit::Color->new( 1,2,3 );
is( ref $red,     $module, 'could create object by random unnamed color');
is(($c->values)[0],       1, 'random color has correct rgb red component value');
is(($c->values)[1],       2, 'random color has correct rgb green component value');
is(($c->values)[2],       3, 'random color has correct rgb blue component value');
is( $c->name,          '', 'random color has no name');

my $recursive = Graphics::Toolkit::Color->new( $red );
is(  ref $recursive,                                  $module,   "recursive constructor option works");
ok(  $recursive != $red,                                         "recursive constructor produced object is new");
is(  $recursive->name,                                  'red',   "recursive constructor produced correct onject");


eval "color('blue')";
is( substr($@, 0, 20),  'Undefined subroutine', 'sub not there when not imported');

package New;

use Graphics::Toolkit::Color qw/color/;
use Test::More;

is (ref color('blue'), $module,                    'sub there when imported');
is (ref color('#ABC'), $module,                    'created color from short RGB hex string');
is (ref color('#AABBCC'), $module,                 'created color from long RGB hex string');
is (ref color([1,2,3]),   $module,                 'created color from Array Input');
is (ref color({r => 1, g => 2, b => 3,}), $module, 'created color from RGB hash');
is (ref color({h => 1, s => 2, l => 3,}), $module, 'created color from HSL hash');

