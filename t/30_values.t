#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 32;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Values';

eval "use $module";
is( not($@), 1, 'could load the module');
use Graphics::Toolkit::Color::Space::Util ':all';

my $v = Graphics::Toolkit::Color::Values->new('#010203');
is( ref $v,        $module,    'could create an object from rgb hex');
is( close_enough($v->{'RGB'}[0],  1/255), 1,  'normalized red value correct');
is( close_enough($v->{'RGB'}[1],  2/255), 1,  'normalized green value correct');
is( close_enough($v->{'RGB'}[2],  3/255), 1,  'normalized blue value correct');

my @values = $v->get;
is( int @values,           3,    'rgb values are three');
is( $values[0],            1,    'spat out original red');
is( $values[1],            2,    'spat out original green');
is( $values[2],            3,    'spat out original blue');

$v = Graphics::Toolkit::Color::Values->new('hsl(240,100,50)');
is( ref $v,        $module,    'could create an object from hsl css_string');
is( $v->{'RGB'}[0],  0,  'normalized red value');
is( $v->{'RGB'}[1],  0,  'normalized green value');
is( $v->{'RGB'}[2],  1,  'normalized blue value');
is( close_enough($v->{'HSL'}[0],  2/3), 1, 'normalized hue value');
is( close_enough($v->{'HSL'}[1],  1),   1, 'normalized saturation value');
is( close_enough($v->{'HSL'}[2],  0.5), 1, 'normalized lightness value');

is( $v->get('hsl','string'), 'hsl: 240, 100, 50', 'got all original values back in string format');
is( $v->string(),            'hsl: 240, 100, 50', 'string method works');
is( uc $v->get('RGB','HEX'), '#0000FF', 'got values in RGB hex format');

my $violet = $v->set({red => 255});
is( ref $violet,     $module,             'created related color by set method');
is( uc $violet->get('RGB','HEX'), '#FF00FF', 'red value got boosted');

my $black = $violet->set({blackness => 100});
is( $black->get('RGB','HEX'), '#000000', 'made color black');


my $vn = $v->add({green => -10}) ;
is( ref $violet,     $module,             'added negative green value');
is( uc $vn->get('RGB','HEX'), '#0000FF', 'color got clamped into defined RGB');

$vn = $v->add({green => 10});
is( uc $vn->get('RGB','HEX'), '#000AFF', 'could add green');

my $vb = $v->blend( $vn, undef, 'RGB' );
is( ref $vb,      $module,    'could blend two colors');
is( $vb->{'RGB'}[0], 0, 'red value correct');
is( close_enough($vb->{'RGB'}[1], 5/255), 1, 'blue value correct');
is( $vb->{'RGB'}[2], 1, 'blue value correct');

is( uc $v->blend( $vn, 0 )->get('RGB','HEX'), '#0000FF', 'blended nothing, kept original');
is( uc $v->blend( $violet, 1 )->get('RGB','HEX'), '#FF00FF', 'blended nothing, kept paint color');
is( uc $v->blend( $violet, 3, 'RGB' )->get('RGB','HEX'), '#FF00FF', 'clamp kept color in range');

exit 0;

__END__

warning_like { $d->([1, 2, 3,4], [  2, 6,11], 'RGB')}  {carped => qr/bad input values/},  "bad distance input: first vector";
warning_like { $d->([1, 2, 3],  [ 2, 6,11,4], 'RGB')}  {carped => qr/bad input values/},  "bad distance input: second vector";
warning_like { $d->([1, 2, 3],  [ 6,11,4], 'ABC')}     {carped => qr/unknown color space name/}, "bad distance input: space name";
warning_like { $d->([1, 2, 3],  [ 6,11,4], 'RGB','acd')} {carped => qr/that does not fit color space/}, "bad distance input: invalid subspace";


is( $d->([1, 2, 3], [  2, 6, 11], 'RGB'), 9,     'compute rgb distance');
is( $d->([1, 2, 3], [  2, 6, 11], 'HSL'), 9,     'compute hsl distance');
is( $d->([0, 2, 3], [359, 6, 11], 'HSL'), 9,     'compute hsl distance (test circular property of hsl)');

is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'r'),  1, 'compute distance in red subspace');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'R'),  1, 'subspace initials are case insensitive');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'g'),  2, 'compute distance in green subspace');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'b'),  3, 'compute distance in blue subspace');
is( $d->([1, 1, 1], [  4, 5, 6], 'RGB', 'rg'), 5, 'compute distance in rg subspace');
is( $d->([1, 1, 1], [  4, 5, 6], 'RGB', 'gr'), 5, 'compute distance in gr subspace');
is( $d->([1, 1, 1], [  4, 6, 5], 'RGB', 'rb'), 5, 'compute distance in rb subspace');
is( $d->([1, 1, 1], [ 12, 4, 5], 'RGB', 'gb'), 5, 'compute distance in gb subspace');
is( $d->([1, 2, 3], [  2, 6,11], 'RGB','rgb'), 9, 'distance in full subspace');
is( $d->([1, 2, 3], [  2, 6,11],            ), 9, 'default space is RGB');

exit 0;

my $d             = \&Graphics::Toolkit::Color::Space::Hub::distance;

warning_like { $d->([1, 2, 3,4], [  2, 6,11], 'RGB')}  {carped => qr/bad input values/},  "bad distance input: first vector";
warning_like { $d->([1, 2, 3],  [ 2, 6,11,4], 'RGB')}  {carped => qr/bad input values/},  "bad distance input: second vector";
warning_like { $d->([1, 2, 3],  [ 6,11,4], 'ABC')}     {carped => qr/unknown color space name/}, "bad distance input: space name";
warning_like { $d->([1, 2, 3],  [ 6,11,4], 'RGB','acd')} {carped => qr/that does not fit color space/}, "bad distance input: invalid subspace";


is( $d->([1, 2, 3], [  2, 6, 11], 'RGB'), 9,     'compute rgb distance');
is( $d->([0, 2, 3], [  1, 5,  7], 'HSL'), 5,     'test normalized circular property of hsl');
is( $d->([0.2, 0, 0], [0.8, 0, 0], 'HSL'), .4,   'test circular property - only one dimensional delta');

is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'r'),  1, 'compute distance in red subspace');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'R'),  1, 'subspace initials are case insensitive');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'g'),  2, 'compute distance in green subspace');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'b'),  3, 'compute distance in blue subspace');
is( $d->([1, 1, 1], [  4, 5, 6], 'RGB', 'rg'), 5, 'compute distance in rg subspace');
is( $d->([1, 1, 1], [  4, 5, 6], 'RGB', 'gr'), 5, 'compute distance in gr subspace');
is( $d->([1, 1, 1], [  4, 6, 5], 'RGB', 'rb'), 5, 'compute distance in rb subspace');
is( $d->([1, 1, 1], [ 12, 4, 5], 'RGB', 'gb'), 5, 'compute distance in gb subspace');
is( $d->([1, 2, 3], [  2, 6,11], 'RGB','rgb'), 9, 'distance in full subspace');
is( $d->([1, 2, 3], [  2, 6,11],            ), 9, 'default space is RGB');
