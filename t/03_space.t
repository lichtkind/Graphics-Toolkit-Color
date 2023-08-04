#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 31;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space';

eval "use $module";
is( not($@), 1, 'could load the module');

my $fspace = Graphics::Toolkit::Color::Space->new();
is( ref $fspace, '', 'need vector names to create color space');
my $space = Graphics::Toolkit::Color::Space->new(qw/AAA BBB CCC DDD/);
is( ref $space, $module, 'could create a space object');
is( $space->name,  'ABCD', 'space has right name');
is( $space->dimensions, 4, 'space has four dimension');
is( $space->has_format('bbb'), 1, 'vector name is a format');
is( $space->has_format('c'),   1, 'vector sigil is a format');
is( $space->has_format('list'),1, 'list is a format');
is( $space->has_format('hash'),1, 'hash is a format');
is( $space->has_format('char_hash'),1, 'char_hash is a format');

is( ref $space->format([1,2,3,4], 'hash'), 'HASH', 'formatted values into a hash');
is( int($space->format([1,2,3,4], 'list')),     4, 'got long enough list of values');

is( $space->format([1,2,3,4], 'bbb'),           2, 'got right value by key name');
is( $space->format([1,2,3,4], 'AAA'),           1, 'got right value by uc key name');
is( $space->format([1,2,3,4], 'c'),             3, 'got right value by shortcut name');
is( $space->format([1,2,3,4], 'D'),             4, 'got right value by uc shortcut name');

is( $space->has_format('str'),   0, 'formatter not yet inserted');
$space->add_formatter('str', sub { $_[0] . $_[1] . $_[2] . $_[3]});
is( $space->has_format('str'),   1, 'formatter inserted');
is( $space->format([1,2,3,4], 'str'),     '1234', 'inserted formatter works');

is( $space->can_convert('XYZ'),   0, 'converter not yet inserted');
$space->add_converter('XYZ', sub { $_[0]+1, $_[1]+1, $_[2]+1, $_[3]+1},
                             sub { $_[0]-1, $_[1]-1, $_[2]-1, $_[3]-1} );
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

exit 0;
