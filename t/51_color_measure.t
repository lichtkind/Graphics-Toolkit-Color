#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 321;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $red = Graphics::Toolkit::Color->new('red');
my $blue = Graphics::Toolkit::Color->new('blue');

# exit (0);
is( $blue->distance_to($red),            120, 'correct default hsl distance between red and blue');
is( $blue->distance_to($red, 'HSL'),     120, 'correct hsl distance between red and blue');
is( $blue->distance_to($red, 'Hue'),     120, 'correct hue distance between red and blue, long name');
is( $blue->distance_to($red, 'h'),       120, 'correct hue distance between red and blue');
is( $blue->distance_to($red, 's'),         0, 'correct sturation distance between red and blue');
is( $blue->distance_to($red, 'Sat'),       0, 'correct sturation distance between red and blue, long name');
is( $blue->distance_to($red, 'l'),         0, 'correct lightness distance between red and blue');
is( $blue->distance_to($red, 'Light'),     0, 'correct lightness distance between red and blue, long name');
is( $blue->distance_to($red, 'hs'),      120, 'correct hs distance between red and blue');
is( $blue->distance_to($red, 'hl'),      120, 'correct hl distance between red and blue');
is( $blue->distance_to($red, 'sl'),        0, 'correct sl distance between red and blue');
is( int $blue->distance_to($red, 'rgb'), 360, 'correct rgb distance between red and blue');
is( $blue->distance_to($red, 'Red'),     255, 'correct red distance between red and blue, long name');
is( $blue->distance_to($red, 'r'),       255, 'correct red distance between red and blue');
is( $blue->distance_to($red, 'Green'),     0, 'correct green distance between red and blue, long name');
is( $blue->distance_to($red, 'g'),         0, 'correct green distance between red and blue');
is( $blue->distance_to($red, 'Blue'),    255, 'correct blue distance between red and blue, long name');
is( $blue->distance_to($red, 'b'),       255, 'correct blue distance between red and blue');
is( $blue->distance_to($red, 'rg'),      255, 'correct rg distance between red and blue');
is( int $blue->distance_to($red, 'rb'),  360, 'correct rb distance between red and blue');
is( $blue->distance_to($red, 'gb'),      255, 'correct gb distance between red and blue');

is( int $blue->distance_to([10, 10, 245],      ),   8, 'correct default hsl  distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'HSL'),   8, 'correct hsl distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Hue'),   0, 'correct hue distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'h'),     0, 'correct hue distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 's'),     8, 'correct sturation distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'Sat'),   8, 'correct sturation distance between own rgb blue and blue, long name');
is( int $blue->distance_to([10, 10, 245], 'l'),     0, 'correct lightness distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'Light'), 0, 'correct lightness distance between own rgb blue and blue, long name');
is( int $blue->distance_to([10, 10, 245], 'hs'),    8, 'correct hs distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'hl'),    0, 'correct hl distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'sl'),    8, 'correct sl distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'rgb'),  17, 'correct rgb distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Red'),  10, 'correct red distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'r'),    10, 'correct red distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Green'),10, 'correct green distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'g'),    10, 'correct green distance between own rgb blue and blue');
is(     $blue->distance_to([10, 10, 245], 'Blue'), 10, 'correct blue distance between own rgb blue and blue, long name');
is(     $blue->distance_to([10, 10, 245], 'b'),    10, 'correct blue distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'rg'),   14, 'correct rg distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'rb'),   14, 'correct rb distance between own rgb blue and blue');
is( int $blue->distance_to([10, 10, 245], 'gb'),   14, 'correct gb distance between own rgb blue and blue');

is( int $blue->distance_to({h =>230, s => 90, l=>40}),         17, 'correct default hsl distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'HSL'),  17, 'correct hsl distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'Hue'),  10, 'correct hue distance between own hsl blue and blue, long name');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'h'),    10, 'correct hue distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 's'),    10, 'correct sturation distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'Sat'),  10, 'correct sturation distance between own hsl blue and blue, long name');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'l'),    10, 'correct lightness distance between own hsl blue and blue');
is(     $blue->distance_to({h =>230, s => 90, l=>40}, 'Light'),10, 'correct lightness distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'hs'),   14, 'correct hs distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'hl'),   14, 'correct hl distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'sl'),   14, 'correct sl distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'rgb'),  74, 'correct rgb distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'Red'),  10, 'correct red distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'r'),    10, 'correct red distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'Green'),41, 'correct green distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'g'),    41, 'correct green distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'Blue'), 61, 'correct blue distance between own hsl blue and blue, long name');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'b'),    61, 'correct blue distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'rg'),   42, 'correct rg distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'rb'),   61, 'correct rb distance between own hsl blue and blue');
is( int $blue->distance_to({h =>230, s => 90, l=>40}, 'gb'),   73, 'correct gb distance between own hsl blue and blue');

exit 0;
