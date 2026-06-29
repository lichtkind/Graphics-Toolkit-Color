#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 63;
use Graphics::Toolkit::Color::Space::Util qw/round_decimals/;
use Graphics::Toolkit::Color::Values;

my $module = 'Graphics::Toolkit::Color::Calculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
eval "use $module";
is( not($@), 1, "could load the module $module"); # say "$@"; exit 1;

my $blue   = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $okblue = Graphics::Toolkit::Color::Values->new_from_tuple([ 240,.5,.5], 'okhsl');
my $badblue= Graphics::Toolkit::Color::Values->new_from_tuple([ 240,1.5,1.5],'okhsl', undef, 1);
my $black  = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white  = Graphics::Toolkit::Color::Values->new_from_any_input('white');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $CMY = Graphics::Toolkit::Color::Space::Hub::get_space('CMY');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $HWB = Graphics::Toolkit::Color::Space::Hub::get_space('HWB');
my $LAB = Graphics::Toolkit::Color::Space::Hub::get_space('LAB');
my $OKLAB = Graphics::Toolkit::Color::Space::Hub::get_space('OKHSL');

my $lighten    = \&Graphics::Toolkit::Color::Calculator::lighten;
my $darken     = \&Graphics::Toolkit::Color::Calculator::darken;
my $lightness  = \&Graphics::Toolkit::Color::Calculator::lightness;
my $saturate   = \&Graphics::Toolkit::Color::Calculator::saturate;
my $desaturate = \&Graphics::Toolkit::Color::Calculator::desaturate;
my $saturation = \&Graphics::Toolkit::Color::Calculator::saturation;
my $derive     = \&Graphics::Toolkit::Color::Calculator::derive;

#### lighten ###########################################################
is(                              $okblue->formatted('OKHSL', 'hash')->{'lightness'}, 0.5, 'reference color has correct lightness');
is( $lighten->($okblue, 0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.6, 'blue was lightened');
is( $lighten->($okblue,-0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.4, 'blue was darkened by negative value');
is( $lighten->($okblue, 0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 1  , 'lightness got clamped to max, because lighten was not in raw mode');
is( $lighten->($okblue,-0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0  , 'lightness got clamped to min, because lighten was not in raw mode');
is( $lighten->($okblue, 0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, 1.1, 'lighten above range, because raw mode');
is( $lighten->($okblue,-0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, -0.1,'lighten below range, because raw mode');
is(                             $badblue->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, 1.5, 'got original out of range lightness of bad color');
is(                             $badblue->formatted('OKHSL', 'hash',                   )->{'lightness'}, 1, 'clamped out of range blue');
is( $lighten->($badblue,-0.1, 0, 'OKHSL')->formatted('OKHSL','hash')->{'lightness'},  1, 'bad blue got darkened to 1.4 clamped to 1');
is( $lighten->($badblue, 0.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'lightness'}, 1.6, 'too bright blue got 1.6, even lighter');
is( $lighten->($badblue, 1.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'lightness'}, 2.6, 'above range l highten with above range value results in 2.6');
is( $lighten->($okblue, 0.1, 0, 'HSL')->formatted('OKHSL', 'hash')->{'lightness'} < 0.6, 1, 'observe the right color space');

#### darken ############################################################
is( $darken->($okblue, 0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.4, 'blue was darkened');
is( $darken->($okblue,-0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.6, 'blue was lightened with darken with negative value');
is( $darken->($okblue, 0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0  , 'result got clamped to min, because not in raw mode');
is( $darken->($okblue,-0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 1  , 'result got clamped to max, because not in raw mode');
is( $darken->($okblue, 0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, -.1, 'darken below range, because raw mode');
is( $darken->($okblue,-0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, 1.1, 'darken above range, because raw mode');
is(                             $badblue->formatted('OKHSL', 'hash',                   )->{'lightness'}, 1, 'clamp out of range blue');
is( $darken->($badblue,-0.1, 0, 'OKHSL')->formatted('OKHSL','hash')->{'lightness'},  1, 'bad blue got darkened to 1.4 clamped to 1');
is( $darken->($badblue, 0.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'lightness'}, 1.4, 'too bright blue got 1.6, even lighter');
is( $darken->($badblue, 1.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'lightness'}, 0.4, 'above range l darkened into range');
is( $darken->($okblue, 0.1, 0, 'HSL')->formatted('OKHSL', 'hash')->{'lightness'} < 0.4, 1, 'observe the right color space');

#### lightness #########################################################

#### saturate ##########################################################
is(                              $okblue->formatted('OKHSL', 'hash')->{'saturation'},  0.5, 'reference color has correct saturation');
is( $saturate->($okblue, 0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 0.6, 'blue was saturated');
is( $saturate->($okblue,-0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 0.4, 'blue was destaurated');
is( $saturate->($okblue, 0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 1  , 'saturation got clamped to max, because not in raw mode');
is( $saturate->($okblue,-0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 0  , 'saturation got clamped to min, because not in raw mode');
is( $saturate->($okblue, 0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'saturation'}, 1.1, 'saturate above range, because raw mode');
is( $saturate->($okblue,-0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'saturation'}, -0.1,'saturate below range, because raw mode');

is(                             $badblue->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'saturation'}, 1.5, 'got original out of range saturation');
is(                             $badblue->formatted('OKHSL', 'hash',                   )->{'saturation'}, 1, 'clamp out of range blue');
is( $saturate->($badblue,-0.1, 0, 'OKHSL')->formatted('OKHSL','hash')->{'saturation'},  1, 'bad blue got destaurated to 1.4 clamped to 1');
is( $saturate->($badblue, 0.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'saturation'}, 1.6, 'too saturated blue got 1.6, even more saturated');
is( $saturate->($badblue, 1.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'saturation'}, 2.6, 'above range l highten with above range value results in 2.6');
is( $saturate->($okblue, 0.1, 0, 'HSL')->formatted('OKHSL', 'hash')->{'saturation'} > 0.6, 1, 'observe the right color space');

#### desaturate ########################################################
is(                             $okblue->formatted('OKHSL', 'hash')->{'saturation'}, 0.5, 'reference color has correct saturation');
is( $desaturate->($okblue, 0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 0.4, 'blue was desaturated');
is( $desaturate->($okblue,-0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 0.6, 'blue was saturated with desaturate by negative values');
is( $desaturate->($okblue, 0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 0  , 'result got clamped to min, because not in raw mode');
is( $desaturate->($okblue,-0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'saturation'}, 1  , 'result got clamped to max, because not in raw mode');
is( $desaturate->($okblue, 0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'saturation'}, -.1, 'desaturate below range, because raw mode');
is( $desaturate->($okblue,-0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'saturation'}, 1.1, 'desaturate above range, because raw mode');

is(                             $badblue->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'saturation'}, 1.5, 'got original out of range saturation');
is(                             $badblue->formatted('OKHSL', 'hash',                   )->{'saturation'}, 1, 'clamp out of range blue');
is( $desaturate->($badblue,-0.1, 0, 'OKHSL')->formatted('OKHSL','hash')->{'saturation'},  1, 'bad blue got desaturateed to 1.4 clamped to 1');
is( $desaturate->($badblue, 0.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'saturation'}, 1.4, 'too saturated blue got 1.6, even more sturated');
is( $desaturate->($badblue, 1.1, 1, 'OKHSL')->formatted('OKHSL','hash',undef,undef,undef,1)->{'saturation'}, 0.4, 'above range l desaturated into range');
is( $desaturate->($okblue, 0.1, 0, 'HSL')->formatted('OKHSL', 'hash')->{'saturation'} < 0.4, 1, 'observe the right color space');

#### saturation ########################################################

#### derive ############################################################

#### set_value #########################################################
my $cyan = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 255} );
is( ref $cyan,    $value_ref,  'aqua (set green value to max) value object');
is( $cyan->name,      'cyan',  'color has the name "cyan" (blue + green)');
my $values = $cyan->normalized();
is_tuple( $values, [0, 1, 1], [qw/red green blue/], 'created cyan by maxing green on blue color');

my $ret = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 255}, 'CMY' );
is( ref $ret,             '',  'green is axis in RGB, not CMY');
$ret = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 255, yellow => 0} );
is( ref $ret,             '',  'green and yellow axis are from different spaces');
$cyan = Graphics::Toolkit::Color::Calculator::set_value( $blue, {green => 255}, 'RGB' );
$values = $cyan->normalized();
is_tuple( $values, [0, 1, 1], [qw/red green blue/], 'created cyan by maxing green on blue color in RGB');

#### add_value #########################################################
$cyan = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 255} );
is( ref $cyan,    $value_ref,  'aqua (add green value to max) value object');
is( $cyan->name,      'cyan',  'color has the name "cyan"');
$values = $cyan->normalized();
is_tuple( $values, [0, 1, 1], [qw/red green blue/], 'created cyan by adding max green on blue color');

$ret = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 255}, 'CMY' );
is( ref $ret,             '',  'green is in RGB, not CMY');
$ret = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 255, yellow => 0}, 'CMY' );
is( ref $ret,             '',  'green and yellow axis are from different spaces');
$cyan = Graphics::Toolkit::Color::Calculator::add_value( $blue, {green => 255}, 'RGB' );
$values = $cyan->normalized();
is_tuple( $values, [0, 1, 1], [qw/red green blue/], 'created cyan by adding max green on blue color in RGB');


exit 0;
