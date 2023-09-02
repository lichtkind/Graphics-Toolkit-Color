#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 89;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Hub';

eval "use $module";
use Graphics::Toolkit::Color::Space::Util ':all';
is( not($@), 1, 'could load the module');

my $deformat      = \&Graphics::Toolkit::Color::Space::Hub::deformat;
my $format        = \&Graphics::Toolkit::Color::Space::Hub::format;
my $deconvert     = \&Graphics::Toolkit::Color::Space::Hub::deconvert;
my $convert       = \&Graphics::Toolkit::Color::Space::Hub::convert;


my @hsl = $convert->([.5, .5, .5], 'HSL');
is( int @hsl,  3,     'converted hsl vector has right length');
is( $hsl[0],   0,     'converted color grey has computed right hue value');
is( $hsl[1],   0,     'converted color grey has computed right saturation');
is( $hsl[2],  .5,     'converted color grey has computed right lightness');

my @rgb = $deconvert->([0, 0, .5], 'hsl');
is( int @rgb,  3,     'converted back color grey has rgb values');
is( $rgb[0], .5,     'converted back color grey has right red value');
is( $rgb[1], .5,     'converted back color grey has right green value');
is( $rgb[2], .5,     'converted back color grey has right blue value');

warning_like {$format->('112233', 'RGB', 'list')}      {carped => qr/array with right amount of values/},  "dont format none vectors";
warning_like {$format->([11,22,33,44], 'RGB', 'list')} {carped => qr/array with right amount of values/},  "dont format too long vectors";
warning_like {$format->([11,22], 'RGB', 'list')}       {carped => qr/array with right amount of values/},  "dont format too short vectors";

my $str = $format->([11,22,33], 'RGB', 'hex');
is( ref $str,           '',   'RGB string is not a reference');
is( uc $str,     '#0B1621',   'created a RGB hex string');

@rgb = $format->([11,22,33], 'RGB', 'list');
is( int @rgb,            3,   'RGB list has right length');
is( $rgb[0],            11,   'put red value first');
is( $rgb[1],            22,   'put green value second');
is( $rgb[2],            33,   'put red value third');

my $h = $format->([1,2,3],'HSL', 'hash');
is( ref $h,         'HASH',   'created a HSL hash');
is( $h->{'hue'},         1,   'put hue value under the right key');
is( $h->{'saturation'},  2,   'put saturation value under the right key');
is( $h->{'lightness'},   3,   'put lightness value under the right key');

$h = $format->([.2,.3,.4],'CMY', 'char_hash');
is( ref $h,         'HASH',   'created a CMY hash');
is( $h->{'c'},          .2,   'put hue value under the right key');
is( $h->{'m'},          .3,   'put saturation value under the right key');
is( $h->{'y'},          .4,   'put lightness value under the right key');

my ($rgb, $f) = $deformat->('#010203');
is( ref $rgb,      'ARRAY',   'deformated values int a list');
is( int @$rgb,           3,   'deformatted RGB hex string into triplet');
is( $rgb->[0],           1,   'deformatted red value from RGB hex string');
is( $rgb->[1],           2,   'deformatted green value from RGB hex string');
is( $rgb->[2],           3,   'deformatted blue value from RGB hex string');
is( $f,              'RGB',   'hex string was formatted in RGB');

($rgb, $f) = $deformat->('#FFF');
is( ref $rgb,      'ARRAY',   'deformated values int a list');
is( int @$rgb,           3,   'deformatted RGB short hex string into triplet');
is( $rgb->[0],         255,   'deformatted red value from short RGB hex string');
is( $rgb->[1],         255,   'deformatted green value from short RGB hex string');
is( $rgb->[2],         255,   'deformatted blue value from short RGB hex string');
is( $f,              'RGB',   'short hex string was formatted in RGB');

my($cmy, $for) = $deformat->({c => 0.1, m => 0.5, Y => 1});
is( ref $cmy,      'ARRAY',   'got cmy key hash deformatted');
is( int @$cmy,           3,   'deformatted CMY HASH into triplet');
is( $cmy->[0],         0.1,   'cyan value correct');
is( $cmy->[1],         0.5,   'magenta value correct');
is( $cmy->[2],           1,   'yellow value is correct');
is( $for,            'CMY',   'key hash was formatted in CMY');

my($cmyk, $form) = $deformat->({c => -0.1, m => 0.5, Y => 2, k => 7});
is( ref $cmyk,     'ARRAY',   'got cmyk key hash deformatted');
is( int @$cmyk,          4,   'deformatted CMYK HASH into quadruel');
is( $cmyk->[0],       -0.1,   'cyan value correct');
is( $cmyk->[1],        0.5,   'magenta value correct');
is( $cmyk->[2],          2,   'yellow value is correct');
is( $cmyk->[3],          7,   'key value got transported correctly');
is( $form,          'CMYK',   'key hash was formatted in CMY');

($cmyk, $form) = $deformat->([cmyk => -0.1, 0.5, 2, 7]);
is( ref $cmyk,     'ARRAY',   'got cmyk named ARRAY deformatted');
is( int @$cmyk,          4,   'deformatted CMYK ARRAY into quadrupel');
is( $cmyk->[0],       -0.1,   'cyan value correct');
is( $cmyk->[1],        0.5,   'magenta value correct');
is( $cmyk->[2],          2,   'yellow value is correct');
is( $cmyk->[3],          7,   'key value got transported correctly');
is( $form,          'CMYK',   'named array recognized as CMYK');

($cmyk, $form) = $deformat->('CMYK: -0.1, 0.5, 2, 7');
is( ref $cmyk,     'ARRAY',   'got cmyk STRING deformatted');
is( int @$cmyk,          4,   'deformatted CMYK STRING into quadruel');
is( $cmyk->[0],       -0.1,   'cyan value correct');
is( $cmyk->[1],        0.5,   'magenta value correct');
is( $cmyk->[2],          2,   'yellow value is correct');
is( $cmyk->[3],          7,   'key value got transported correctly');
is( $form,          'CMYK',   'named array recognized as CMYK');


($rgb, $f) = $deformat->({c => 0.1, n => 0.5, Y => 1});
is( ref $rgb,           '',   'could not deformat cmy hash due bak key name');

# test partial_hash_deformat

my $ph_deformat  = \&Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat;
my $lp_hash      = \&Graphics::Toolkit::Color::Space::Hub::list_from_pos_hash;

my ($pos_hash, $space_name) = $ph_deformat->();
is( $pos_hash, undef, 'got no HASH');
($pos_hash, $space_name) = $ph_deformat->({});
is( $pos_hash, undef, 'HASH was empty');

my @list = $lp_hash->();
is( int @list, 0, 'list_from_pos_hash: no result on no input');
is( $list[0], undef, 'undef is there');

@list = $lp_hash->({0 => 1,1 => 1,2 => 1,3 =>1}, 'RGB');
is( int @list, 3, 'took only three values of too large hash');


($pos_hash, $space_name) = $ph_deformat->({red => 255});
is( ref $pos_hash, 'HASH', 'partial hash could be deformated');
is( keys %$pos_hash,    1,    'there was only one key');
is( $pos_hash->{0},   255,    'red value belongs on first position');
is( $space_name,    'RGB',    'found keys in RGB');

@list = $lp_hash->($pos_hash, 'RGB');
is( int @list,      3,    'result of complete deformat to list has right length');
is( $list[0],     255,    'red landed on right position');
is( $list[1],       0,    'none red was set to zero');
is( $list[2],       0,    'other none red was set to zero');

($pos_hash, $space_name) = $ph_deformat->({H => 2, vAlue => 3});
is( ref $pos_hash, 'HASH', 'partial hash could be deformated, even one key was shortcut');
is( keys %$pos_hash,    2,    'there were two keys');
is( $pos_hash->{2},     3,    'value is on third position in HSV');
is( $space_name,    'HSV',    'found keys in HSV');

@list = $lp_hash->($pos_hash, 'HSV');
is( int @list,      3,    'deformat result has right length');
is( $list[0],       2,    'hue value landed on right position');
is( $list[1],       0,    'middle value got filled in with zero');
is( $list[2],       3,    'value landed right');

($pos_hash, $space_name) = $ph_deformat->({ whiteness => 1});
is( $pos_hash->{1},     1,    'value is on second position in HWB');
is( $space_name,    'HWB',    'found keys in HWB');

# normalize and denormalize


exit 0;
