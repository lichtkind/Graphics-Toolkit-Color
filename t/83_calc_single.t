#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 53;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color::Values;

my $module = 'Graphics::Toolkit::Color::Calculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
eval "use $module";
is( not($@), 1, "could load the module $module");

my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $HWB = Graphics::Toolkit::Color::Space::Hub::get_space('HWB');
my $LAB = Graphics::Toolkit::Color::Space::Hub::get_space('LAB');

#### apply_gamma #######################################################

#### set_value #########################################################
my $cyan = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 255} );
is( ref $cyan,    $value_ref,  'aqua (set green value to max) value object');
is( $cyan->name,      'cyan',  'color has the name "cyan" (blue + green)');
my $values = $cyan->normalized();
is( ref $values,     'ARRAY',  'RGB value ARRAY');
is( @$values,              3,  'has three values');
is( $values->[0],          0,  'red value is zero');
is( $values->[1],          1,  'green value is one (max)');
is( $values->[2],          1,  'blue value is one too');
my $ret = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 256}, 'CMY' );
is( ref $ret,             '',  'green is in RGB, not CMY');
$ret = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 256, yellow => 0} );
is( ref $ret,             '',  'green and yellow axis are from different spaces');
$cyan = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 256}, 'RGB' );
$values = $cyan->normalized();
is( ref $cyan,    $value_ref,  'green is in RGB, and set green over max, got clamped');
is( @$values,              3,  'has three values');
is( $values->[0],          0,  'red value is zero');
is( $values->[1],          1,  'green value is one (max)');
is( $values->[2],          1,  'blue value is one too');

#### add_value #########################################################
$cyan = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 255} );
is( ref $cyan,    $value_ref,  'aqua (add green value to max) value object');
is( $cyan->name,      'cyan',  'color has the name "cyan"');
$values = $cyan->normalized();
is( ref $values,     'ARRAY',  'RGB value ARRAY');
is( @$values,              3,  'has three values');
is( $values->[0],          0,  'red value is zero');
is( $values->[1],          1,  'green value is one (max)');
is( $values->[2],          1,  'blue value is one too');
$ret = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 255}, 'CMY' );
is( ref $ret,             '',  'green is in RGB, not CMY');
$ret = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 256, yellow => 0}, 'CMY' );
is( ref $ret,             '',  'green and yellow axis are from different spaces');
$cyan = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 256}, 'RGB' );
$values = $cyan->normalized();
is( ref $cyan,    $value_ref,  'green is in RGB, and set green over max, got clamped');
is( @$values,              3,  'has three values');
is( $values->[0],          0,  'red value is zero');
is( $values->[1],          1,  'green value is one (max)');
is( $values->[2],          1,  'blue value is one too');

#### mix ###############################################################
my $grey = Graphics::Toolkit::Color::Calculator::mix ( 
	$white, [{color => $black, percent => 50}, {color => $white, percent => 50}], $RGB );
is( ref $grey,                   $value_ref,  'created gray by mixing black and white');
$values = $grey->shaped();
is( @$values,                          3,  'get RGB values of grey');
is( $values->[0],                    128,  'red value of gray');
is( $values->[1],                    128,  'green value of gray');
is( $values->[2],                    128,  'blue value of gray');
is( $grey->name(),                'gray',  'created gray by mixing black and white');

my $lgrey = Graphics::Toolkit::Color::Calculator::mix ( 
	$white, [{color => $black, percent => 5}, {color => $white, percent => 95}], $RGB);
is( ref $lgrey,                   $value_ref,  'created light gray');
$values = $lgrey->shaped();
is( @$values,                          3,  'get RGB values of grey');
is( $values->[0],                    242,  'red value of gray');
is( $values->[1],                    242,  'green value of gray');
is( $values->[2],                    242,  'blue value of gray');
is( $lgrey->name(),             'gray95',  'created gray by mixing black and white');

my $darkblue = Graphics::Toolkit::Color::Calculator::mix ( 
	$white, [{color => $blue, percent => 50},{color => $black, percent => 50},], $HSL);
is( ref $darkblue,               $value_ref,  'mixed black and blue in HSL, recalculated percentages from sum of 120%');
$values = $darkblue->shaped('HSL');
is( @$values,                          3,  'get 3 HSL values');
is( $values->[0],                    120,  'hue value is right');
is( $values->[1],                     50,  'sat value is right');
is( $values->[2],                     25,  'light value is right');

#### invert ############################################################
my $nblack = Graphics::Toolkit::Color::Calculator::invert ( $white, $RGB ) ;
is( $nblack->name,    'black',  'black is white inverted');
my $nwhite = Graphics::Toolkit::Color::Calculator::invert ( $nblack, $RGB ) ;
is( $nwhite->name,    'white',  'white is black inverted');
my $nyellow = Graphics::Toolkit::Color::Calculator::invert ( $blue, $RGB ) ;
is(  $nyellow->name,  'yellow', 'yellow is blue inverted');
my $ngray = Graphics::Toolkit::Color::Calculator::invert ( $blue, $HSL ) ;
is( $ngray->name,     'gray',  'in HSL is gray opposite to any color');
my $nblue = Graphics::Toolkit::Color::Calculator::invert ( $blue, $LAB ) ;
is( $nblue->name,         '',  'LAB is not symmetrical');
$nblack = Graphics::Toolkit::Color::Calculator::invert ( $white, $HSL ) ;
is( $nblack->name,   'black',  'primary contrast works in HSL');
$nblack = Graphics::Toolkit::Color::Calculator::invert ( $white, $HWB ) ;
is( $nblack->name,   'black',  'primary contrast works in HWB');

exit 0;
