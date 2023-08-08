#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 61;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $red = Graphics::Toolkit::Color->new('#FF0000');
warning_like {$red->add()}                    {carped => qr/argument options/},    "need argument to add to color object";
warning_like {$red->add('weirdcolorname')}    {carped => qr/unknown color/},       "accept only known color names";
warning_like {$red->add('#23232')       }     {carped => qr/hex color definition/}, "hex definition too short";
warning_like {$red->add('#232321f')     }     {carped => qr/hex color definition/}, "hex definition too long";
warning_like {$red->add(1,1)}                 {carped => qr/argument options/},     "too few positional args";
warning_like {$red->add(1,1,1,1)}             {carped => qr/wrong number/},         "too many positional args";
warning_like {$red->add([1,1])}               {carped => qr/ 3 numerical values/},  "too few positional args in ref";
warning_like {$red->add([1,1,1,1])}           {carped => qr/ 3 numerical values/},  "too many positional args in ref";
warning_like {$red->add(r=>1,g=>1,t=>1)}      {carped => qr/unknown hash key/},   "don't invent named args";
warning_like {$red->add({r=>1,g=>1,t=>1})}    {carped => qr/unknown hash key/},   "don't invent named args, in ref";

my $white = Graphics::Toolkit::Color->new('white');
my $black = Graphics::Toolkit::Color->new('black');

is( $white->add( 255, 255, 255 )->name,              'white',   "it can't get whiter than white with additive color adding");
is( $white->add( {Hue => 10} )->name,                'white',   "hue doesnt change when were on level white");
is( $white->add( {Red => 10} )->name,                'white',   "hue doesnt change when adding red on white");
is( $white->add( $white )->name,                     'white',   "adding white on white is still white");
is( $red->add( $black )->name,                         'red',   "red + black = red");
is( $red->add( $black, -1 )->name,                     'red',   "red - black = red");
is( $white->add( $red, -1 )->name,                    'aqua',   "white - red = aqua");
is( $white->add( $white, -0.5 )->name,                'gray',   "white - 0.5 white = grey");
is( Graphics::Toolkit::Color->new(1,2,3)->add( 2,1,0)->name,     'gray1',   "adding positional args"); # = 3, 3, 3
is( $red->add( {Saturation => -10} )->red,               242,   "paling red 10%, red value");
is( $red->add( {Saturation => -10} )->blue,               13,   "paling red 10%, blue value");
is( $white->add( {Lightness => -12} )->name,        'gray88',   "dimming white 12%");
is( $black->add( {Red => 255} )->name,                 'red',   "creating pure red from black");
is( $black->add( {Green => 255} )->name,              'lime',   "creating pure green from black");
is( $black->add( {  b => 255} )->name,                'blue',   "creating pure blue from black with short name");


warning_like {$red->blend_with()}                    {carped => qr/color object/},    "need argument to blend to color object";
warning_like {$red->blend_with('weirdcolorname')}    {carped => qr/unknown color/},   "accept only known color names";
warning_like {$red->blend_with('#23232')       }     {carped => qr/hex color definition/},  "hex definition too short";
warning_like {$red->blend_with('#232321f')     }     {carped => qr/hex color definition/},  "hex definition too long";
warning_like {$red->blend_with([1,1])}               {carped => qr/need exactly 3/},  "too few positional args in ref";
warning_like {$red->blend_with([1,1,1,1])}           {carped => qr/need exactly 3/},  "too many positional args in ref";
warning_like {$red->blend_with({r=>1,g=>1,t=>1})}    {carped => qr/argument keys/},   "don't mix named args, in hash ref color def";
warning_like {$red->blend_with({r=>1,g=>1,l=>1})}    {carped => qr/argument keys/},   "don't invent named args, in hash ref color def";

is( $black->blend_with( $white )->name,                  'gray',   "blend black + white = gray");
is( $black->blend_with( $white, 0 )->name,              'black',   "blend nothing, keep color");
is( $black->blend_with( $white, 1 )->name,              'white',   "blend nothing, take c2");
is( $black->blend_with( $white, 2 )->name,              'white',   "RGB limits kept");
is( $red->blend_with( 'blue')->name,                  'fuchsia',   "blending with name");
is( $red->blend_with( '#0000ff')->name,               'fuchsia',   "blending with hex def");
is( $red->blend_with( [0,0,255])->name,               'fuchsia',   "blending with array ref color def");
is( $red->blend_with({R=> 0, G=> 0, B=>255})->name,   'fuchsia',   "blending with RGB hash ref color def");
is( $red->blend_with({H=> 240, S=> 100, L=>50})->name,'fuchsia',   "blending with HSL hash ref color def");

exit 0;
