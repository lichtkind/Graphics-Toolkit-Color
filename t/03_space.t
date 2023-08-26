#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 102;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space';

eval "use $module";
is( not($@), 1, 'could load the module');

my $fspace = Graphics::Toolkit::Color::Space->new();
is( ref $fspace, '', 'need vector names to create color space');
my $space = Graphics::Toolkit::Color::Space->new(axis => [qw/AAA BBB CCC DDD/], range => 20);

is( ref $space, $module, 'could create a space object');
is( $space->name,  'ABCD', 'space has right name');
is( $space->dimensions, 4, 'space has four dimension');
is( $space->has_format('bbb'), 0, 'vector name is not a format');
is( $space->has_format('c'),   0, 'vector sigil is not  a format');
is( $space->has_format('list'),1, 'list is a format');
is( $space->has_format('hash'),1, 'hash is a format');
is( $space->has_format('char_hash'),1, 'char_hash is a format');

is( ref $space->format([1,2,3,4], 'hash'), 'HASH', 'formatted values into a hash');
is( int($space->format([1,2,3,4], 'list')),     4, 'got long enough list of values');

is( $space->format([1,2,3,4], 'bbb'),           0, 'got no value by key name');
is( $space->format([1,2,3,4], 'AAA'),           0, 'got no value by uc key name');
is( $space->format([1,2,3,4], 'c'),             0, 'got no value by shortcut name');
is( $space->format([1,2,3,4], 'D'),             0, 'got no value by uc shortcut name');

is( $space->has_format('str'),   0, 'formatter not yet inserted');
my $c = $space->add_formatter('str', sub { $_[0] . $_[1] . $_[2] . $_[3]});
is( ref $c, 'CODE', 'formatter code accepted');
is( $space->has_format('str'),   1, 'formatter inserted');
is( $space->format([1,2,3,4], 'str'),     '1234', 'inserted formatter works');

my @fval = $space->deformat({a => 1, b => 2, c => 3, d => 4});
is( int @fval,   4, 'deformatter recognized char hash');
is( $fval[0],    1, 'first value correctly deformatted');
is( $fval[1],    2, 'second value correctly deformatted');
is( $fval[2],    3, 'third value correctly deformatted');
is( $fval[3],    4, 'fourth value correctly deformatted');

@fval = $space->deformat({aaa => 1, bbb => 2, ccc => 3, ddd => 4});
is( int @fval,   4, 'deformatter recognized hash');
is( $fval[0],    1, 'first value correctly deformatted');
is( $fval[1],    2, 'second value correctly deformatted');
is( $fval[2],    3, 'third value correctly deformatted');
is( $fval[3],    4, 'fourth value correctly deformatted');

@fval = $space->deformat({a => 1, b => 2, c => 3, e => 4});
is( $fval[0],  undef, 'char hash with bad key got ignored');
@fval = $space->deformat({aaa => 1, bbb => 2, ccc => 3, dd => 4});
is( $fval[0],  undef, 'char hash with bad key got ignored');

my $dc = $space->add_deformatter('str', sub { split ':', $_[0] });
is( ref $dc, 'CODE', 'deformatter code accepted');
@fval = $space->deformat('1:2:3:4');
is( int @fval,  4, 'self made deformatter recognized str');
is( $fval[0],    1, 'first value correctly deformatted');
is( $fval[1],    2, 'second value correctly deformatted');
is( $fval[2],    3, 'third value correctly deformatted');
is( $fval[3],    4, 'fourth value correctly deformatted');

is( $space->can_convert('XYZ'),   0, 'converter not yet inserted');
my $h = $space->add_converter('XYZ', sub { $_[0]+1, $_[1]+1, $_[2]+1, $_[3]+1},
                                     sub { $_[0]-1, $_[1]-1, $_[2]-1, $_[3]-1} );
is( ref $h, 'HASH', 'converter code accepted');
is( $space->can_convert('XYZ'),   1, 'converter inserted');
my @val = $space->convert([1,2,3,4], 'XYZ');
is( int @val,   4, 'converter did something');
is( $val[0],    2, 'first value correctly converted');
is( $val[1],    3, 'second value correctly converted');
is( $val[2],    4, 'third value correctly converted');
is( $val[3],    5, 'fourth value correctly converted');
@val = $space->deconvert([2,3,4,5], 'xyz');
is( int @val,   4, 'deconverter did something even if space spelled in lower case');
is( $val[0],    1, 'first value correctly deconverted');
is( $val[1],    2, 'second value correctly deconverted');
is( $val[2],    3, 'third value correctly deconverted');
is( $val[3],    4, 'fourth value correctly deconverted');

my @d = $space->delta(1, [1,5,4,5] );
is( int @d,   0, 'reject compute delta on none vector on first arg position');
@d = $space->delta([1,5,4,5], 1 );
is( int @d,   0, 'reject compute delta on none vector on second arg position');
@d = $space->delta([2,3,4,5,1], [1,5,4,5] );
is( int @d,   0, 'reject compute delta on too long first vector');
@d = $space->delta([2,3,4], [1,5,1,1] );
is( int @d,   0, 'reject compute delta on too short first  vector');
@d = $space->delta([2,3,4,5], [1,5,1,4,5] );
is( int @d,   0, 'reject compute delta on too long second vector');
@d = $space->delta([2,3,4,5], [1,5,1] );
is( int @d,   0, 'reject compute delta on too short second  vector');

@d = $space->delta([2,3,4,5], [1,5,1,1] );
is( int @d,   4, 'delta result has right length');
is( $d[0],   -1, 'first value correctly deconverted');
is( $d[1],    2, 'second value correctly deconverted');
is( $d[2],   -3, 'third value correctly deconverted');
is( $d[3],   -4, 'fourth value correctly deconverted');

my $hspace = Graphics::Toolkit::Color::Space->new(axis => [qw/hue aa bb/], range => [359,100,[-50,50]], type => ['angle',0,'circular']);
@d = $hspace->delta( [0.1, 0.9, 0.8], [.9, .1, .2] );
is( int @d,   3, 'hab delta has three values');
is( $d[0], -0.2, 'rotate value wehn jump over circular gap');
is( $d[1],   .2, 'rotate value wehn jump over circular gap in other direction');
is( $d[2],   .4, 'rotate in too large angle');

my @tr = $space->clamp([-1, 0, 20.1, 21, 1]);
is( int @tr,   4, 'clamp kept correct vector length = 4');
is( $tr[0],    0, 'clamp up value below minimum');
is( $tr[1],    0, 'do not touch minimal value');
is( $tr[2],   20, 'clamp real into int');
is( $tr[3],   20, 'clamp down value above range max');

@tr = $hspace->clamp( [360, 100] );
is( int @tr,   3, 'clamp added missing value');
is( $tr[0],    1, 'clamp down too large circular value');
is( $tr[1],    0, 'value was just max, clamped to min');
is( $tr[2],    0, 'added a zero');

is( $space->check([1,2,3,4]),   undef, 'all values in range');
warning_like {$space->check([1,2,3])}       {carped => qr/value vector/},  "not enough values";
warning_like {$space->check([1,2,3,4,5])}   {carped => qr/value vector/},  "too much values";
warning_like {$space->check([-11,2,3,4])} {carped => qr/aaa value is below/},  "too small first value";
warning_like {$space->check([0,21,3,4])}  {carped => qr/bbb value is above/},  "too large second value";
warning_like {$space->check([0,1,3.1,4])} {carped => qr/be an integer/},        "third value was not int";

my @norm = $space->normalize([0, 10, 20, 15]);
is( int @norm,   4, 'normalized 4 into 4 values');
is( $norm[0],    0, 'normalized first min value');
is( $norm[1],    0.5, 'normalized second mid value');
is( $norm[2],    1,   'normalized third max value');
is( $norm[3],    0.75, 'normalized fourth value');

@norm = $hspace->normalize([359, 0, 0]);
is( int @norm,   3,  'normalized 3 into 3 values');
is( $norm[0],    1,  'normalized first max value');
is( $norm[1],    0,  'normalized second min value');
is( $norm[2],    0.5,'normalized third mid with range into negative');

@norm = $hspace->denormalize([1, 0, 0.5]);
is( int @norm,   3, 'denormalized 3 into 3 values');
is( $norm[0],  359, 'denormalized first max value');
is( $norm[1],    0, 'denormalized second min value');
is( $norm[2],    0, 'denormalized third mid with range into negative');

@norm = $hspace->denormalize([1, 0, 0.5], [[-10,250],[30,50], [-70,70]]);
is( int @norm,   3, 'denormalized 3 into 3 values');
is( $norm[0],  250, 'denormalized with special ranges max value');
is( $norm[1],   30, 'denormalized with special ranges min value');
is( $norm[2],    0, 'denormalized with special ranges mid value');

@norm = $hspace->normalize([250, 30, 0], [[-10,250],[30,50], [-70,70]]);
is( int @norm,  3,  'normalized 3 into 3 values');
is( $norm[0],   1,  'normalized with special ranges max value');
is( $norm[1],   0,  'normalized with special ranges min value');
is( $norm[2],   0.5,'normalized with special ranges mid value');

