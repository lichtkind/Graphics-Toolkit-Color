#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 118;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Shape';

use_ok( $module, 'could load the module');
my $obj = Graphics::Toolkit::Color::Space::Shape->new();
is( $obj,  undef,       'constructor needs arguments');

my $basis = Graphics::Toolkit::Color::Space::Basis->new( [qw/AAA BBB CCC/] );
my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis);
is( ref $shape,  $module, 'created shape with default settings');

like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, {}), qr/invalid axis type/, 'type definition needs to be an ARRAY');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, []), qr/invalid axis type/, 'type definition needs to have same length');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, ['yes','no','maybe']), qr/invalid axis type/, 'undefined values');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, [1,2,3]), qr/invalid axis type/, 'undefined numeric values');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, ['linear','circular','no']), $module, 'valid type def');

like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, {}), qr/invalid range/, 'range definition needs to be an ARRAY');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 1), $module, 'uniform scalar range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 'normal'), $module, 'normal scalar range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 'percent'), $module, 'percent scalar range');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, []), qr/invalid range/, 'range definition ARRAY has to have same lngth');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [1,2,3]), $module, 'ARRAY range with right amount of ints');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2],[1,2]]), $module, 'full ARRAY range');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1.1,1.2],[1,2]]), $module, 'full ARRAY range with decimals');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2]]), qr/invalid range/, 'not enough elements in range def');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2],[1,2],[1,2]]), qr/invalid range/, 'too many elements in range def');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[2,1],[1,2]]), qr/lower bound/, 'one range def element is backward');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1],[1,2]]), qr/two elements/, 'one range def element is too small');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,2,3],[1,2]]), qr/two elements/, 'one range def element is too big');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[1,2],[1,'-'],[1,2]]), qr/none numeric/, 'one range def element has a none number');

is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef, 0), $module, 'accepting third constructor arg - precision zero');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef, 2), $module, 'precision 2');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef, -1), $module, 'precision -1');
is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef, [0,1,-1]), $module, 'full precision def');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef, [1,2]), qr/value precision/, 'precision def too short');
like(   Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef, [1,2,3,-1]), qr/value precision/, 'precision def too long');

is( ref Graphics::Toolkit::Color::Space::Shape->new( $basis, undef,undef,undef, '%'), $module, 'accepting fourth constructor arg - a suffix for axis numbers');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular','linear','no'], 20, [-1,0,1]);
is( ref $shape,  $module, 'created shape with 0..20 range');
is( $shape->axis_is_numeric(0), 1, 'first dimension is numeric');
is( $shape->axis_is_numeric(1), 1, 'second dimension is numeric');
is( $shape->axis_is_numeric(2), 0, 'third dimension is not numeric');
is( $shape->axis_is_numeric(3), 0, 'there is no fourth dimension ');
is( $shape->axis_value_precision(0), -1, 'first dimension precision');
is( $shape->axis_value_precision(1), 0, 'second dimension precision');
is( $shape->axis_value_precision(2), undef, 'third dimension precision does not count (not numeric)');


my $bshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular', 'circular', 0], [[-5,5],[0,5],[-5,0]], );
is( ref $bshape,  $module, 'created 3D bowl shape with -5..5 range');
is( $bshape->axis_value_precision(0), 0, 'first dimension is int on default');
is( $bshape->axis_value_precision(1), 0, 'second dimension is int on default');
is( $bshape->axis_value_precision(2), 0, 'third dimension is int on default');

my $nshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, 'normal');
is( $nshape->axis_value_precision(0) < 0, 1, 'first normal dimension is real because normal');
is( $nshape->axis_value_precision(1) < 0, 1, 'second normal dimension is real because normal');
is( $nshape->axis_value_precision(2) < 0, 1, 'third normal dimension is real because normal');

my $mshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, ['normal', 100, [2, 2.2]]);
is( $mshape->axis_value_precision(0) < 0, 1, 'first particular normal dimension is real');
is( $mshape->axis_value_precision(1), 0, 'second dimension defined by upper int bound is int');
is( $mshape->axis_value_precision(2) < 0, 1, 'third dimension defined by real range is real');

my $oshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[0, 10], [0, 10], [0, 10]], [2, 0, -1]);
is( ref $oshape,  $module, 'space shape with 0..10 axis and hand set precision');
is( $oshape->axis_value_precision(0), 2, 'first dimension has set precision');
is( $oshape->axis_value_precision(1), 0, 'second dimension has set precision');
is( $oshape->axis_value_precision(2), -1,'third dimension has set precision');

my $d = $bshape->delta(1, [1,5,4,5] );
is( ref $d,  '', 'reject compute delta on none vector on first arg position');
$d = $shape->delta([1,5,4,5], 1 );
is( ref $d,  '', 'reject compute delta on none vector on second arg position');
$d = $shape->delta([2,3,4,5], [1,5,4] );
is( ref $d,  '', 'reject compute delta on too long first vector');
$d = $shape->delta([2,3], [1,5,1] );
is( ref $d,  '', 'reject compute delta on too short first  vector');
$d = $shape->delta([2,3,4], [5,1,4,5] );
is( ref $d,  '', 'reject compute delta on too long second vector');
$d = $shape->delta([2,3,4], [5,1] );
is( ref $d,  '', 'reject compute delta on too short second  vector');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, undef, [[-5,5],[-5,5],[-5,5]], );
$d = $shape->delta([2,3,4], [1,5,1.1] );
is( ref $d,   'ARRAY', 'linear delta result ist vector');
is( int @$d,   3, 'linear delta result has right length');
is( $d->[0],   -1, 'first delta value correct');
is( $d->[1],    2, 'second delta value correct');
is( $d->[2],  -2.9, 'third delta value correct');

$d = $bshape->delta([0.1,0.9, .2], [0.9, 0.1, 0.8] );
is( int @$d,   3, 'circular delta result has right length');
is( $d->[0],   -0.2, 'first delta value correct');
is( $d->[1],     .2, 'second delta value correct');
is( $d->[2],   -0.4, 'third delta value correct');

my $tr = $shape->clamp([-1.1, 0, 20.1, 21, 1]);
is( int @$tr,   3, 'clamp down to correct vector length = 3');
is( $tr->[0],  -1, 'clamp real into int');
is( $tr->[1],   0, 'do not touch minimal value');
is( $tr->[2],   5, 'clamp too large nr into upper bound');

$shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, [ 'circular', 'linear', 'linear'], [[-5,5],[-5,5],[-5,5]], );
$tr = $shape->clamp( [-10, 20] );
is( int @$tr,  3, 'clamp added missing value');
is( $tr->[0],  0, 'rotates in circular value');
is( $tr->[1],  5, 'value was just max, clamped to min');
is( $tr->[2],  0, 'added a zero into missing value');

$tr = $shape->clamp( [6, -1, 11], [5,7,[-5, 10]]  );
is( int @$tr,   3, 'clamp with special range def');
is( $tr->[0],    1, 'rotated larg value down');
is( $tr->[1],    0, 'too small value clamped up to min');
is( $tr->[2],   10, 'clamped down into special range');

$bshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, ['angular', 'circular', 0], [[-5,5],[-5,5],[-5,5]], [0,1,-1]);
$tr = $bshape->clamp( [-.1, 1.123, 2.54], ['normal',2,[-1,4]], [0,1,-1] );
is( int @$tr,   3, 'clamp kept right amount of values');
is( $tr->[0],   1, 'rotated and rounded value to int');
is( $tr->[1],   1.1, 'rounded in range value to set precision');
is( $tr->[2],   2.54, 'in range value is kept');


is( ref $shape->in_range(1,2,3),        '',  'need array ref, not list');
is( ref $shape->in_range({}),           '',  'need array, not other ref');
is( ref $shape->in_range([1,2,3]), 'ARRAY',  'all values in range');
is( ref $shape->in_range([1,2]),        '',  "not enough values");
is( ref $shape->in_range([1,2,3,4]),    '',  "too many values");
is( ref $shape->in_range([1,22,3]),     '',  "too big second value");
is( ref $shape->in_range([0,1,3.1]),    '',  "too many decimals in third value");


my $norm = $shape->normalize([-5, 0, 5]);
is( ref $norm,   'ARRAY', 'normalized values');
is( int @$norm,   3, 'normalized 3 into 3 values');
is( $norm->[0],    0, 'normalized first min value');
is( $norm->[1],    0.5, 'normalized second mid value');
is( $norm->[2],    1,   'normalized third max value');

$norm = $shape->denormalize([0, 0.5 , 1]);
is( @$norm,        3, 'denormalized 3 into 3 values');
is( $norm->[0],   -5, 'denormalized min value');
is( $norm->[1],    0, 'denormalized second mid value');
is( $norm->[2],    5, 'denormalized third max value');

$norm = $bshape->normalize([-1, 0, 5]);
is( @$norm,   3, 'normalize bawl coordinates');
is( $norm->[0],    0.4, 'normalized first min value');
is( $norm->[1],    0.5, 'normalized second mid value');
is( $norm->[2],    1,   'normalized third max value');

$norm = $bshape->denormalize([0.4, 0.5, 1]);
is( @$norm,   3, 'denormalized 3 into 3 values');
is( $norm->[0],   -1, 'denormalized small value');
is( $norm->[1],    0, 'denormalized mid value');
is( $norm->[2],    5, 'denormalized max value');

$norm = $bshape->denormalize([1, 0, 0.5], [[-10,250],[30,50], [-70,70]]);
is( @$norm,   3, 'denormalized bowl with custom range');
is( $norm->[0],  250, 'denormalized with special ranges max value');
is( $norm->[1],   30, 'denormalized with special ranges min value');
is( $norm->[2],    0, 'denormalized with special ranges mid value');

$norm = $bshape->normalize([250, 30, 0], [[-10,250],[30,50], [-70,70]]);
is( @$norm,  3,  'normalized  bowl with custom range');
is( $norm->[0],   1,  'normalized with special ranges max value');
is( $norm->[1],   0,  'normalized with special ranges min value');
is( $norm->[2],   0.5,'normalized with special ranges mid value');

$norm = $shape->denormalize_delta([0, 0.5 , 1]);
is( @$norm,        3, 'denormalized 3 into 3 values');
is( $norm->[0],    0, 'denormalized min delta');
is( $norm->[1],    5, 'denormalized second mid delta');
is( $norm->[2],   10, 'denormalized third max delta');


exit 0;
