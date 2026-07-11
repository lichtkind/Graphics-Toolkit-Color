#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 140;
use Graphics::Toolkit::Color::Values;

my $module = 'Graphics::Toolkit::Color::Calculator';
my $value_ref = 'Graphics::Toolkit::Color::Values';
eval "use $module";
is( not($@), 1, "could load the module $module"); # say "$@"; exit 1;

#### reused constants ##################################################
my $blue   = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $okblue = Graphics::Toolkit::Color::Values->new_from_tuple([ 240,.5,.5], 'okhsl');
my $nkblue = Graphics::Toolkit::Color::Values->new_from_tuple([ 240,1.5,1.5],'okhsl', undef, 1);
my $black  = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white  = Graphics::Toolkit::Color::Values->new_from_any_input('white');
my $twhite  = Graphics::Toolkit::Color::Values->new_from_any_input([256,256,256],'RGB', 255, 'raw');

my $lighten    = \&Graphics::Toolkit::Color::Calculator::lighten;
my $darken     = \&Graphics::Toolkit::Color::Calculator::darken;
my $lightness  = \&Graphics::Toolkit::Color::Calculator::lightness;
my $saturate   = \&Graphics::Toolkit::Color::Calculator::saturate;
my $desaturate = \&Graphics::Toolkit::Color::Calculator::desaturate;
my $saturation = \&Graphics::Toolkit::Color::Calculator::saturation;
my $derive     = \&Graphics::Toolkit::Color::Calculator::derive;

my $RGB        =   Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL        =   Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $OKHSL      =   Graphics::Toolkit::Color::Space::Hub::get_space('OKHSL');

my $hsl = [qw/hue saturation lightness/];
my $rgb = [qw/red green blue/];
my @raw = ($OKHSL,undef,-1,1);
#### lighten ###########################################################
# $color_values, $by, $raw, $color_space
is_tuple(                              $okblue->shaped($OKHSL ),[240,.5,.5],  $hsl, 'reference color has correct lightness');
is_tuple( $lighten->($okblue, 0.1, 0, 'OKHSL')->shaped($OKHSL ),[240,.5,.6],  $hsl, 'blue was lightened');
is_tuple( $lighten->($okblue,-0.1, 0, 'OKHSL')->shaped($OKHSL ),[240,.5,.4],  $hsl, 'blue was darkened by negative value');
is_tuple( $lighten->($okblue, 0.6, 0, 'OKHSL')->shaped($OKHSL ),[240,.5,1 ],  $hsl, 'lightness got clamped to max, because lighten was not in raw mode');
is_tuple( $lighten->($okblue,-0.6, 0, 'OKHSL')->shaped($OKHSL ),[240,.5,0 ],  $hsl, 'lightness got clamped to min, because lighten was not in raw mode');
is_tuple( $lighten->($okblue, 0.6, 1, 'OKHSL')->shaped(@raw),   [240,.5,1.1], $hsl, 'lighten above range, because raw mode');
is_tuple( $lighten->($okblue,-0.6, 1, 'OKHSL')->shaped(@raw),   [240,.5,-.1], $hsl, 'lighten below range, because raw mode');
is_tuple(                              $nkblue->shaped(@raw),   [240,1.5,1.5],$hsl, 'got original out of range lightness of bad color');
is_tuple(                              $nkblue->shaped($OKHSL),[240,1,  1 ], $hsl, 'clamped out of range blue');
is_tuple( $lighten->( $nkblue,-0.1, 0,'OKHSL')->shaped($OKHSL),[240,1,  1 ], $hsl, 'above range blue got darkened to 1.4 clamped to 1');
is_tuple( $lighten->( $nkblue, 0.1, 1,'OKHSL')->shaped(@raw),   [240,1.5,1.6],$hsl, 'too bright blue got 1.6, even lighter');
is_tuple( $lighten->( $nkblue, 1.1, 1,'OKHSL')->shaped(@raw),   [240,1.5,2.6],$hsl, 'above range l highten with above range value results in 2.6');
is( $lighten->($okblue,  0.1, 0,  'HSL')->formatted($OKHSL,'hash')->{'lightness'} < 0.6, 1, 'observe the right color space');

#### darken ############################################################
is_tuple(                             $okblue->shaped($OKHSL),[240,.5,.5],  $hsl, 'reference color has correct lightness');
is_tuple( $darken->($okblue, 0.1, 0, 'OKHSL')->shaped($OKHSL),[240,.5,.4],  $hsl, 'blue was darkened');
is_tuple( $darken->($okblue,-0.1, 0, 'OKHSL')->shaped($OKHSL),[240,.5,.6],  $hsl, 'blue was lightened with darken with negative value');
is_tuple( $darken->($okblue, 0.6, 0, 'OKHSL')->shaped($OKHSL),[240,.5,0],   $hsl, 'below range l got clamped to min, because raw mode off');
is_tuple( $darken->($okblue,-0.6, 0, 'OKHSL')->shaped($OKHSL),[240,.5,1],   $hsl, 'above range l got clamped to max, because raw mode off');
is_tuple( $darken->($okblue, 0.6, 1, 'OKHSL')->shaped(@raw),   [240,.5,-.1], $hsl, 'darken below range, because raw mode');
is_tuple( $darken->($okblue,-0.6, 1, 'OKHSL')->shaped(@raw),   [240,.5,1.1], $hsl, 'darken above range, because raw mode');
is_tuple(                             $nkblue->shaped(@raw),   [240,1.5,1.5],$hsl, 'got original out of range lightness of bad color');
is_tuple(                             $nkblue->shaped($OKHSL),[240,1 , 1],  $hsl, 'clamp out of range blue');
is_tuple( $darken->( $nkblue,-0.1, 0,'OKHSL')->shaped($OKHSL),[240,1, 1],   $hsl, 'bad blue got darkened to 1.4 clamped to 1');
is_tuple( $darken->( $nkblue, 0.1, 1,'OKHSL')->shaped(@raw),   [240,1.5,1.4],$hsl, 'too bright blue got 1.6, even lighter');
is_tuple( $darken->( $nkblue, 1.1, 1,'OKHSL')->shaped(@raw),   [240,1.5,.4], $hsl, 'above range l darkened into range');
is( $darken->($okblue, 0.1, 0, 'HSL')->formatted($OKHSL,'hash')->{'lightness'} < 0.4, 1, 'observe the right color space');

#### lightness #########################################################
# $color_values, $set, $mult, $add, $raw, $space_name
is_tuple( $lightness->($okblue, 0.1, undef,undef,0,'OKHSL')->shaped($OKHSL), [240,.5, .1], $hsl, 'blue with freshly set lightness');
is_tuple( $lightness->($okblue, 1.1, undef,undef,0,'OKHSL')->shaped($OKHSL), [240,.5,1 ],  $hsl, 'set out of range lightness, which gets clamped');
is_tuple( $lightness->($okblue, 1.1, undef,undef,1,'OKHSL')->shaped(@raw),    [240,.5,1.1], $hsl, 'set out of range lightness, not clamped');
is_tuple( $lightness->($okblue, undef, 1.5,undef,0,'OKHSL')->shaped($OKHSL), [240,.5,.75], $hsl, 'blue with multiplied lightness');
is_tuple( $lightness->($okblue, undef, 2.5,undef,0,'OKHSL')->shaped($OKHSL), [240,.5,1  ], $hsl, 'multiplied too much, which gets clamped');
is_tuple( $lightness->($okblue, undef, 2.5,undef,1,'OKHSL')->shaped(@raw),    [240,.5,1.25],$hsl, 'multiplied too much, not clamped');
is_tuple( $lightness->($okblue, 0.2,   1.5,undef,0,'OKHSL')->shaped($OKHSL), [240,.5, .3], $hsl, 'blue with multiplied lightness');
is_tuple( $lightness->($okblue, 0.7,   2,  undef,0,'OKHSL')->shaped($OKHSL), [240,.5,1  ], $hsl, 'multiplied too much, which gets clamped');
is_tuple( $lightness->($okblue, 0.7, 2,    undef,1,'OKHSL')->shaped(@raw),    [240,.5,1.4], $hsl, 'multiplied too much, not clamped');
is_tuple( $lightness->($okblue, undef, undef,.1, 0,'OKHSL')->shaped($OKHSL), [240,.5,0.6], $hsl, 'added lightness');
is_tuple( $lightness->($okblue, undef,undef, .6, 0,'OKHSL')->shaped($OKHSL), [240,.5,1  ], $hsl, 'added too much lightness, got clamped');
is_tuple( $lightness->($okblue, undef,undef, .6, 1,'OKHSL')->shaped(@raw),    [240,.5,1.1], $hsl, 'added too much lightness, not clamped');
is_tuple( $lightness->($okblue, undef, .5, .05,  0,'OKHSL')->shaped($OKHSL), [240,.5, 0.3],$hsl, 'multiplied and added lightness');
is_tuple( $lightness->($okblue, undef, 3,  -.7,  0,'OKHSL')->shaped($OKHSL), [240,.5, 0.8],$hsl, 'multiplied and added too much but result is back in range');
is_tuple( $lightness->($okblue, .8, undef,  .3,  0,'OKHSL')->shaped($OKHSL), [240,.5, 1  ],$hsl, 'set and added too much lightness, got clamped');
is_tuple( $lightness->($okblue, .8, undef,  .3,  1,'OKHSL')->shaped(@raw),    [240,.5, 1.1],$hsl, 'set and added too much lightness, not clamped');
is_tuple( $lightness->($okblue, .7, undef, -.1,  0,'OKHSL')->shaped($OKHSL), [240,.5,  .6],$hsl, 'set and subtracted lightness');
is_tuple( $lightness->($okblue, .1, 3,    undef, 0,'OKHSL')->shaped($OKHSL), [240,.5, 0.3],$hsl, 'set and added lightness');
is_tuple( $lightness->($okblue, .7, 2,   undef,  0,'OKHSL')->shaped($OKHSL), [240,.5, 1],  $hsl, 'set and added too much, got clamped');
is_tuple( $lightness->($okblue, .7, 2,   undef,  1,'OKHSL')->shaped(@raw),    [240,.5, 1.4],$hsl, 'set and added too much, not clamped');
is_tuple( $lightness->($okblue, .1, 3,      .2,  0,'OKHSL')->shaped($OKHSL), [240,.5, 0.5],$hsl, 'set multiplied and added lightness');
is_tuple( $lightness->($okblue, .8, 2,     -.5,  0,'OKHSL')->shaped($OKHSL), [240,.5, 1  ],$hsl, 'set multiplied and added lightness, got clamped');
is_tuple( $lightness->($okblue, .8, 2,     -.5,  1,'OKHSL')->shaped(@raw),    [240,.5, 1.1],$hsl, 'set multiplied and added lightness, not clamped');
is_tuple( $lightness->($white, undef,undef,-.1,  1,'HSL'  )->shaped($HSL, 1), [  0, 0,  .9],$hsl, 'added in HSL space');

#### saturate ##########################################################
is_tuple(                               $okblue->shaped($OKHSL),[240,.5,.5], $hsl, 'reference color has correct saturation');
is_tuple( $saturate->($okblue, 0.1, 0, 'OKHSL')->shaped($OKHSL),[240,.6,.5], $hsl, 'blue was saturated');
is_tuple( $saturate->($okblue,-0.1, 0, 'OKHSL')->shaped($OKHSL),[240,.4,.5], $hsl, 'blue was destaurated');
is_tuple( $saturate->($okblue, 0.6, 0, 'OKHSL')->shaped($OKHSL),[240,1, .5], $hsl, 'saturation got clamped to max, because not in raw mode');
is_tuple( $saturate->($okblue,-0.6, 0, 'OKHSL')->shaped($OKHSL),[240,0, .5], $hsl, 'saturation got clamped to min, because not in raw mode');
is_tuple( $saturate->($okblue, 0.6, 1, 'OKHSL')->shaped(@raw), [240,1.1, .5], $hsl, 'saturate above range, because raw mode');
is_tuple( $saturate->($okblue,-0.6, 1, 'OKHSL')->shaped(@raw), [240,-0.1,.5], $hsl, 'saturate below range, because raw mode');
is_tuple(                               $nkblue->shaped(@raw), [240,1.5,1.5], $hsl, 'got original out of range saturation');
is_tuple(                               $nkblue->shaped($OKHSL),[240,1,1  ], $hsl, 'clamp out of range blue');
is_tuple( $saturate->( $nkblue,-0.1, 0,'OKHSL')->shaped($OKHSL),[240,1,1  ], $hsl, 'bad blue got destaurated to 1.4 clamped to 1');
is_tuple( $saturate->( $nkblue, 0.1, 1,'OKHSL')->shaped(@raw), [240,1.6,1.5], $hsl, 'too saturated blue got 1.6, even more saturated');
is_tuple( $saturate->( $nkblue, 1.1, 1,'OKHSL')->shaped(@raw), [240,2.6,1.5], $hsl, 'above range l highten with above range value results in 2.6');
is( $saturate->($okblue, 0.1, 0, 'HSL')->formatted($OKHSL, 'hash')->{'saturation'} > 0.6, 1, 'observe the right color space');

#### desaturate ########################################################
is_tuple(                                 $okblue->shaped($OKHSL),[240,.5,.5], $hsl, 'reference color has correct saturation');
is_tuple( $desaturate->($okblue, 0.1, 0, 'OKHSL')->shaped($OKHSL),[240,.4,.5], $hsl, 'blue was desaturated');
is_tuple( $desaturate->($okblue,-0.1, 0, 'OKHSL')->shaped($OKHSL),[240,.6,.5], $hsl, 'blue was saturated with desaturate by negative values');
is_tuple( $desaturate->($okblue, 0.6, 0, 'OKHSL')->shaped($OKHSL),[240,0, .5], $hsl, 'result got clamped to min, because not in raw mode');
is_tuple( $desaturate->($okblue,-0.6, 0, 'OKHSL')->shaped($OKHSL),[240,1, .5], $hsl, 'result got clamped to max, because not in raw mode');
is_tuple( $desaturate->($okblue, 0.6, 1, 'OKHSL')->shaped(@raw), [240,-.1, .5], $hsl, 'desaturate below range, because raw mode');
is_tuple( $desaturate->($okblue,-0.6, 1, 'OKHSL')->shaped(@raw), [240,1.1, .5], $hsl, 'desaturate above range, because raw mode');
is_tuple(                                 $nkblue->shaped(@raw), [240,1.5,1.5], $hsl, 'got original out of range saturation');
is_tuple(                                 $nkblue->shaped($OKHSL), [240,1, 1], $hsl, 'clamp out of range blue');
is_tuple( $desaturate->($nkblue,-0.1, 0, 'OKHSL')->shaped($OKHSL), [240,1,1], $hsl, 'bad blue got desaturateed to 1.4 clamped to 1');
is_tuple( $desaturate->($nkblue, 0.1, 1, 'OKHSL')->shaped(@raw),[240,1.4,1.5], $hsl, 'too saturated blue got 1.6, even more sturated');
is_tuple( $desaturate->($nkblue, 1.1, 1, 'OKHSL')->shaped(@raw),[240,0.4,1.5], $hsl, 'above range l desaturated into range');
is( $desaturate->($okblue, 0.1, 0, 'HSL')->formatted($OKHSL, 'hash')->{'saturation'} < 0.4, 1, 'observe the right color space');

#### saturation ########################################################
is_tuple( $saturation->($okblue, 0.1, undef,undef,0,'OKHSL')->shaped($OKHSL), [240, .1, .5],$hsl, 'blue with freshly set saturation');
is_tuple( $saturation->($okblue, 1.1, undef,undef,0,'OKHSL')->shaped($OKHSL), [240,1,  .5 ],$hsl, 'set out of range saturation, which gets clamped');
is_tuple( $saturation->($okblue, 1.1, undef,undef,1,'OKHSL')->shaped(@raw),    [240,1.1,.5 ],$hsl, 'set out of range saturation, not clamped');
is_tuple( $saturation->($okblue, undef, 1.5,undef,0,'OKHSL')->shaped($OKHSL), [240,.75,.5 ],$hsl, 'blue with multiplied saturation');
is_tuple( $saturation->($okblue, undef, 2.5,undef,0,'OKHSL')->shaped($OKHSL), [240,1,  .5 ],$hsl, 'multiplied too much, which gets clamped');
is_tuple( $saturation->($okblue, undef, 2.5,undef,1,'OKHSL')->shaped(@raw),    [240,1.25,.5],$hsl, 'multiplied too much, not clamped');
is_tuple( $saturation->($okblue, 0.2,   1.5,undef,0,'OKHSL')->shaped($OKHSL), [240, .3, .5],$hsl, 'blue with multiplied saturation');
is_tuple( $saturation->($okblue, 0.7,   2,  undef,0,'OKHSL')->shaped($OKHSL), [240,1 , .5 ],$hsl, 'multiplied too much, which gets clamped');
is_tuple( $saturation->($okblue, 0.7, 2,    undef,1,'OKHSL')->shaped(@raw),    [240,1.4,.5 ],$hsl, 'multiplied too much, not clamped');
is_tuple( $saturation->($okblue, undef, undef,.1, 0,'OKHSL')->shaped($OKHSL), [240, .6,.5 ],$hsl, 'added saturation');
is_tuple( $saturation->($okblue, undef,undef, .6, 0,'OKHSL')->shaped($OKHSL), [240,1,  .5 ],$hsl, 'added too much saturation, got clamped');
is_tuple( $saturation->($okblue, undef,undef, .6, 1,'OKHSL')->shaped(@raw),    [240,1.1,.5 ],$hsl, 'added too much saturation, not clamped');
is_tuple( $saturation->($okblue, undef, .5, .05,  0,'OKHSL')->shaped($OKHSL), [240, .3,.5 ],$hsl, 'multiplied and added saturation');
is_tuple( $saturation->($okblue, undef, 3,  -.7,  0,'OKHSL')->shaped($OKHSL), [240, .8,.5 ],$hsl, 'multiplied and added too much but result is back in range');
is_tuple( $saturation->($okblue, .8, undef,  .3,  0,'OKHSL')->shaped($OKHSL), [240,1,  .5 ],$hsl, 'set and added too much saturation, got clamped');
is_tuple( $saturation->($okblue, .8, undef,  .3,  1,'OKHSL')->shaped(@raw),    [240,1.1,.5 ],$hsl, 'set and added too much saturation, not clamped');
is_tuple( $saturation->($okblue, .7, undef, -.1,  0,'OKHSL')->shaped($OKHSL), [240, .6,.5 ],$hsl, 'set and subtracted saturation');
is_tuple( $saturation->($okblue, .1, 3,    undef, 0,'OKHSL')->shaped($OKHSL), [240, .3,.5 ],$hsl, 'set and added saturation');
is_tuple( $saturation->($okblue, .7, 2,   undef,  0,'OKHSL')->shaped($OKHSL), [240,1,  .5 ],$hsl, 'set and added too much, got clamped');
is_tuple( $saturation->($okblue, .7, 2,   undef,  1,'OKHSL')->shaped(@raw),    [240,1.4,.5 ],$hsl, 'set and added too much, not clamped');
is_tuple( $saturation->($okblue, .1, 3,      .2,  0,'OKHSL')->shaped($OKHSL), [240,.5, .5 ],$hsl, 'set multiplied and added saturation');
is_tuple( $saturation->($okblue, .8, 2,     -.5,  0,'OKHSL')->shaped($OKHSL), [240,1,  .5 ],$hsl, 'set multiplied and added saturation, got clamped');
is_tuple( $saturation->($okblue, .8, 2,     -.5,  1,'OKHSL')->shaped(@raw),    [240,1.1,.5 ],$hsl, 'set multiplied and added saturation, not clamped');
is( $saturation->($okblue, undef,undef,-.1,  1,'HSL')->formatted($OKHSL, 'hash')->{'saturation'} < 0.4, 1, 'added in HSL space');

@raw = ($RGB, undef,-1,1);
#### derive ############################################################
# $color_values, $set, $mult, $add, $range_def, $raw, $selected_space_name, $default_space_name
is_tuple( $derive->($white, undef, undef, undef, undef, 0, 'RGB')->shaped($RGB),    [255, 255, 255],$rgb, 'white unchanged');
is_tuple( $derive->($twhite, undef, undef,undef, undef, 0, 'RGB')->shaped($RGB),    [255, 255, 255],$rgb, 'too white was clamped');
is_tuple( $derive->($twhite, undef, undef,undef, undef, 1, 'RGB')->shaped(@raw),     [256, 256, 256],$rgb, 'too white was not clamped');
is_tuple( $derive->($white, 2, undef, undef, undef, 0, 'RGB')->shaped($RGB),        [  2,   2,   2],$rgb, 'set rgb values by constant');
is_tuple( $derive->($white,-1, undef, undef, undef, 0, 'RGB')->shaped($RGB),        [  0,   0,   0],$rgb, 'clamped set rgb constant');
is_tuple( $derive->($white,-1, undef, undef, undef, 1, 'RGB')->shaped(@raw),         [ -1,  -1,  -1],$rgb, 'raw set rgb constant');
is_tuple( $derive->($twhite,-1, undef, undef, undef, 1, 'RGB')->shaped(@raw),        [ -1,  -1,  -1],$rgb, 'raw set rgb of out of gamut constant');
is_tuple( $derive->($white,{r =>-1, g=> 1},undef,undef,undef,0,'RGB')->shaped($RGB),[  0  , 1, 255],$rgb, 'set individual axis values, set space RGB');
is_tuple( $derive->($white,{r =>-1, g=> 1},undef,undef,undef,0,undef,'RGB')->shaped($RGB),[0,1,255],$rgb, 'set individual axis values, default space RGB');
is_tuple( $derive->($twhite,{b =>-1, g=> 1},undef,undef,undef,1,'RGB')->shaped(@raw),[256,   1,  -1],$rgb, 'set individual axis values in raw mode');
is_tuple( $derive->($white,undef, 0.2,undef,undef,0,'RGB')->shaped($RGB),           [ 51,  51,  51],$rgb, 'multiply constant');
is_tuple( $derive->($white,undef, -2,undef,undef,0,'RGB')->shaped($RGB),            [  0,   0,   0],$rgb, 'multiply constant out of gamut');
is_tuple( $derive->($twhite,undef, 0.1,undef,undef,0,'RGB')->shaped($RGB,1,4),  [.1004,.1004,.1004],$rgb, 'multiply constant with out of gamut color into gamut');
is_tuple( $derive->($twhite,undef, 2,undef,undef,1,'RGB')->shaped($RGB,1,4,1),  [2.0078,2.0078,2.0078],$rgb, 'multiply constant with out of gamut color furthout out');
is_tuple( $derive->($white,undef, {r=> 0, g=> .5},undef,undef,0,'RGB')->shaped($RGB),[ 0, 128, 255],$rgb, 'multiply hash with in gamut color');
is_tuple( $derive->($twhite,undef,{r=> .5, b=> 1},undef,undef,1,'RGB')->shaped(@raw),[ 128,256, 256],$rgb, 'multiply out of gamut color');
is_tuple( $derive->($white,undef, undef, -10, undef, 0, 'RGB')->shaped($RGB),       [245, 245, 245],$rgb, 'add (subtract) constant');
is_tuple( $derive->($white,undef, undef,  1, undef, 0, 'RGB')->shaped(@raw),         [255, 255, 255],$rgb, 'add constant out of gamut, but got clamped');
is_tuple( $derive->($white,undef, undef,  1, undef, 1, 'RGB')->shaped(@raw),         [256, 256, 256],$rgb, 'add constant out of gamut, not clamped');
is_tuple( $derive->($white,undef,undef,{g=> 2, b=>-7},undef,0,'RGB')->shaped(@raw),  [255, 255, 248],$rgb, 'add hash, got clamped');
is_tuple( $derive->($white,undef,undef,{r=> 0, b=>7},undef,1,'RGB')->shaped(@raw),   [255, 255, 262],$rgb, 'add hash, not clamped');
is_tuple( $derive->($twhite,undef,undef,{r=> 0, b=>7},undef,1,'RGB')->shaped(@raw),  [256, 256, 263],$rgb, 'add hash with out of gamut color');
is_tuple( $derive->($white, 20, 2, 4, undef,1,'RGB')->shaped($RGB),                 [ 44,  44,  44],$rgb, 'set mult and add constant');
is_tuple( $derive->($white, {r=>10}, {g=>.4}, {b=>-10}, undef,1,'RGB')->shaped($RGB),[10, 102, 245],$rgb, 'set mult and add one key hashes');
is_tuple( $derive->($white, {g=>10,b=>100},{r=>.4,g=>2},{r=>10,g=>5},undef,0,'RGB')->shaped($RGB),[112,25,100],$rgb, 'set mult and add two key hashes');

is_tuple( $derive->($white,{h=>100, s=> 20},undef,undef,undef,1,undef,'HSL')->shaped($HSL),  [100, 20, 100], $hsl, 'default to HSL as advised');
is_tuple( $derive->($white,undef,undef,{r=> 0, b=>7},10,1,'RGB')->shaped(@raw),  [255, 255, 433.5], $rgb, 'add hash on in range color with custom range');

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
