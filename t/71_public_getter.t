#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 60;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';
use Graphics::Toolkit::Color qw/color/;

my $red   = color(255,0,0);
my $blue  = color({r => 0, g => 0, b=>255});
my $purple = color({hue => 300, s => 100, l => 25});
my $black = color([0,0,0]);
my $white = color(['cmy',0,0,0]);

is( $red->name,          'red', 'color name "red" is correct');
is( $blue->name,        'blue', 'color name "blue" is correct');
is( $purple->name,    'purple', 'color name "purple" is correct');
is( $black->name,      'black', 'color name "black" is correct');
is( $white->name,      'white', 'color name "white" is correct');

is( $red->closest_name,          'red', 'color "red" is also closest name');
is( $blue->closest_name,        'blue', 'color "blue" is also closest name');
is( $purple->closest_name,    'purple', 'color "purple" is also closest name');
is( $black->closest_name,      'black', 'color "black" is also closest name');
is( $white->closest_name,      'white', 'color "white" is also closest name');
my ($name, $d) = $red->closest_name;
is( $name,               'red', 'color name is "red" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $blue->closest_name;
is( $name,              'blue', 'color name is "blue" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $purple->closest_name;
is( $name,            'purple', 'color name is "purple" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $black->closest_name;
is( $name,             'black', 'color name is "black" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $white->closest_name;
is( $name,             'white', 'color name is "white" also in array context');
is( $d,                      0, 'and has no distance');

exit 0;

__END__
values distance name closest_name

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

