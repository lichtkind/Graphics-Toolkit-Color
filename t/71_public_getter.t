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

my $snow = color(['rgb', 254, 255, 255]);
is( $snow->name,               '', 'this color has no name in default constants');
($name, $d) = $snow->closest_name;
is( $name,             'white', 'color "white" is closest to snow');
is( $d,                      1, 'and has a distance of 1');
is( close_enough($snow->distance($white), 1), 1, 'distance method calculates (almost) the same');
is( close_enough($snow->distance(to => $white), 1), 1, 'use named argument to calculate distance');
is( close_enough($snow->distance(to => $white, range => 511), 2), 1, 'test reaction to the "range" argument');
is( close_enough($snow->distance(to => $white, select => 'red'), 1), 1, 'test reaction to the "select" argument');
is( close_enough($snow->distance(to => $white, select => 'blue'), 0), 1, 'select axis with no value difference');
is( close_enough($snow->distance(to => $white, select => ['red','blue']), 1), 1, 'select axis with and without value difference');
is( close_enough($snow->distance(to => $white, in => 'cmy', range => 255), 1), 1, 'test reaction to the "in" argument');
is( ref $snow->distance( blub => $white),        '', 'false arguments get caught');
is( ref $snow->distance( in => 'LAB'),           '', 'missing required argument gets caught');




exit 0;

__END__
values

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

