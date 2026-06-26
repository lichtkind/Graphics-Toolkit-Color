#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 12;
use Graphics::Toolkit::Color::Space::Util qw/round_decimals/;
use Graphics::Toolkit::Color::Values;

my $module = 'Graphics::Toolkit::Color::Calculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
eval "use $module";
is( not($@), 1, "could load the module $module"); # say "$@"; exit 1;

my $blue   = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $okblue = Graphics::Toolkit::Color::Values->new_from_tuple([ 240,.5,.5], 'okhsl');
my $badblue= Graphics::Toolkit::Color::Values->new_from_tuple([ 240,.5,1.5],'okhsl', undef, 1);
my $black  = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white  = Graphics::Toolkit::Color::Values->new_from_any_input('white');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $CMY = Graphics::Toolkit::Color::Space::Hub::get_space('CMY');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $HWB = Graphics::Toolkit::Color::Space::Hub::get_space('HWB');
my $LAB = Graphics::Toolkit::Color::Space::Hub::get_space('LAB');
my $OKLAB = Graphics::Toolkit::Color::Space::Hub::get_space('OKHSL');

my $lighten  = \&Graphics::Toolkit::Color::Calculator::lighten;
my $darken   = \&Graphics::Toolkit::Color::Calculator::darken;

#### lighten ###########################################################
is(                              $okblue->formatted('OKHSL', 'hash')->{'lightness'}, 0.5, 'reference color has correct lightness');
is( $lighten->($okblue, 0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.6, 'blue was lightened');
is( $lighten->($okblue,-0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.4, 'blue was darkened');
is( $lighten->($okblue, 0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 1  , 'result got clamped to max, because not in raw mode');
is( $lighten->($okblue,-0.6, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0  , 'result got clamped to min, because not in raw mode');
is( $lighten->($okblue, 0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, 1.1, 'result clamped, because raw mode');
is( $lighten->($okblue,-0.6, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, -0.1, 'result clamped, because raw mode');

is(                             $badblue->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, 1.5, 'got original out of range lightness');
is(                             $badblue->formatted('OKHSL', 'hash',                   )->{'lightness'}, 1, 'clamp out of range blue');
is( $lighten->($badblue,-0.1, 0, 'OKHSL')->formatted('OKHSL', 'hash')->{'lightness'}, 0.9, 'bad blue got clamped then darkened');
is( $lighten->($badblue, 0.1, 1, 'OKHSL')->formatted('OKHSL', 'hash',undef,undef,undef,1)->{'lightness'}, 1.6, 'go even more out of range in raw mode');

#say $lighten->($okblue, 0.1, 0, 'OKHSL');


#### darken ############################################################

#### lightness #########################################################

#### saturate ##########################################################

#### desaturate ########################################################

#### saturation ########################################################

#### derive ############################################################

#### tint ##############################################################

#### tone ##############################################################

#### shade #############################################################

exit 0;
