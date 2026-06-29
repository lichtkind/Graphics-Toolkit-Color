#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 29;
use Graphics::Toolkit::Color::Calculator;

my $module = 'Graphics::Toolkit::Color::Calculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';

my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $CMY = Graphics::Toolkit::Color::Space::Hub::get_space('CMY');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $HWB = Graphics::Toolkit::Color::Space::Hub::get_space('HWB');
my $LAB = Graphics::Toolkit::Color::Space::Hub::get_space('LAB');

#### transfer ##########################################################
my $nice_blue = Graphics::Toolkit::Color::Values->new_from_any_input([10,20,200]);
my $nblue = Graphics::Toolkit::Color::Calculator::apply_gamma( $nice_blue, 1,  $RGB);
is( ref $nblue,    $value_ref, 'gamma of one does not change anything');
my $values = $nblue->shaped();
is_tuple( $values, [10, 20, 200], [qw/red green blue/], 'nice blue with no gamma');

$nblue = Graphics::Toolkit::Color::Calculator::apply_gamma( $nice_blue, 2.2,  $RGB);
is( ref $nblue,    $value_ref, 'gamma of 2.2 does skew down values');
$values = $nblue->shaped();
is_tuple( $values, [0, 1, 149], [qw/red green blue/], 'nice blue with gamma 2.2');

$nblue = Graphics::Toolkit::Color::Calculator::apply_gamma( $nice_blue, 0.5, $CMY);
is( ref $nblue,    $value_ref, 'gamma correction in CMY space');
$values = $nblue->shaped();
is_tuple( $values, [5, 10, 137], [qw/red green blue/], 'nice blue with gamma 0.5');

$nblue = Graphics::Toolkit::Color::Calculator::apply_gamma( $nice_blue, {red => 0.1, cyan => 3},  $RGB);
is( ref $nblue,           '', 'gamma value hash had names that not belong to RGB');

$nblue = Graphics::Toolkit::Color::Calculator::apply_gamma( $nice_blue, {red => 0.1, blue => 3},  $RGB);
is( ref $nblue,    $value_ref, 'mixed gamma values skew too');
$values =$nblue->shaped();
is_tuple( $values, [184, 20, 123], [qw/red green blue/], 'red and blue values have individual gamma applied');

#### tint ##############################################################

#### tone ##############################################################

#### shade #############################################################


#### mix ###############################################################
my $grey = Graphics::Toolkit::Color::Calculator::mix ( $white, [$black], undef, 0, $RGB );
is( ref $grey,                   $value_ref,  'created gray by mixing black and white without amount');
$values = $grey->shaped();
is_tuple( $values, [128, 128, 128], [qw/red green blue/], 'mixed grey from black and white');
is( $grey->name(),                'gray',  'created gray by mixing black and white');
$grey = Graphics::Toolkit::Color::Calculator::mix ( $white, [$black], .5, 0,  $RGB );
is( $grey->name(),                'gray',  'created gray by mixing black and white with percentage amount');
$grey = Graphics::Toolkit::Color::Calculator::mix ( $white, [$black], [.50], 0,  $RGB );
is( $grey->name(),                'gray',  'the percentage amount is in ARRAY this time');

my $lgrey = Graphics::Toolkit::Color::Calculator::mix ( $white, [$black, $white], [5,95], 0, $RGB);
is( ref $lgrey,                   $value_ref,  'created light gray');
$values = $lgrey->shaped();
is_tuple( $values, [242, 242, 242], [qw/red green blue/], 'mixed light grey from black and white');
is( $lgrey->name(),             'gray95',  'created gray by mixing black and white');

my $darkblue = Graphics::Toolkit::Color::Calculator::mix ( $white, [$blue, $black], [50, 50], 0, $HSL);
is( ref $darkblue,               $value_ref,  'mixed black and blue in HSL, recalculated percentages from sum of 120%');
$values = $darkblue->shaped('HSL');
is_tuple( $values, [120, 50, 25], [qw/hue saturation lightness/], 'mixed grey from black and white in HSL');

#### random ############################################################


#### invert ############################################################
my $nblack = Graphics::Toolkit::Color::Calculator::invert ( $white, undef, 0, $RGB );
is( $nblack->name,    'black',  'black is white inverted');
my $nwhite = Graphics::Toolkit::Color::Calculator::invert ( $nblack, undef, 0, $RGB );
is( $nwhite->name,    'white',  'white is black inverted');
my $nyellow = Graphics::Toolkit::Color::Calculator::invert ( $blue, undef,  0, $RGB );
is(  $nyellow->name,  'yellow', 'yellow is blue inverted');
my $ngray = Graphics::Toolkit::Color::Calculator::invert ( $blue, undef,  0, $HSL );
is( $ngray->name,     'gray',   'in HSL is gray opposite to any color');
$nblue = Graphics::Toolkit::Color::Calculator::invert ( $blue, undef,  0, $LAB );
is( $nblue->name,         '',   'LAB is not symmetrical');
$nblack = Graphics::Toolkit::Color::Calculator::invert ( $white, undef,  0, $HSL );
is( $nblack->name,   'black',   'primary contrast works in HSL');
$nblack = Graphics::Toolkit::Color::Calculator::invert ( $white, undef,  0, $HWB );
is( $nblack->name,   'black',  'primary contrast works in HWB');
my $ncyan = Graphics::Toolkit::Color::Calculator::invert ( $white, 'red',  0, $RGB );
is( $ncyan->name,     'cyan',  'inverted only on red axis: white to cyan');
my $nred = Graphics::Toolkit::Color::Calculator::invert ( $white, [qw/b g/],  0, $RGB );
is( $nred->name,       'red',  'inverted on two axis with short names');

my $ndb = Graphics::Toolkit::Color::Calculator::invert ( $darkblue, [qw/h/], $HSL );
$values = $ndb->shaped('HSL');
is_tuple( $values, [300, 50, 25], [qw/hue saturation lightness/], 'inverted dark blue in HSL');

exit 0;
