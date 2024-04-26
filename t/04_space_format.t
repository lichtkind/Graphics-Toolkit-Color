#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 111;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Format';

use_ok( $module, 'could load the module');
use Graphics::Toolkit::Color::Space::Basis;
my $basis = Graphics::Toolkit::Color::Space::Basis->new([qw/alpha beta gamma/]);

my $obj = Graphics::Toolkit::Color::Space::Format->new( );
like( $obj,   qr/first argument/,      'constructor needs basis as first argument');

$obj = Graphics::Toolkit::Color::Space::Format->new( $basis );
is( ref $obj, $module,  'one constructor argument is enough');

my $pobj = Graphics::Toolkit::Color::Space::Format->new( $basis, '%' );
is( ref $pobj, $module,  'used second argument: suffix');


is( $obj->is_named_string([]),                  0, 'array is not a string');
is( $obj->is_named_string(''),                  0, 'empty string is not named');
is( $obj->is_named_string('abg:'),              0, 'name string lacks values');
is( $obj->is_named_string('1,2,3'),             0, 'values lack name');
is( $obj->is_named_string('abg:1,2,3'),         1, 'full named string');
is( $obj->is_named_string('abg:1.1,-2,0.003'),  1, 'testing different value formats');
is( $obj->is_named_string('abg:1%,2,3'),        0, 'suffix will not be tolerated');
is( $pobj->is_named_string('abg:1%,2%,3%'),     1, 'find string format with suffixes');

my ($vals, $name) = $obj->deformat('abg:0,2.2,-3');
is( ref $vals,        'ARRAY', 'could deformat values');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             0, 'first value');
is( $vals->[1],           2.2, 'secong value');
is( $vals->[2],            -3, 'third value');
is( $name,           'string', 'found right format name');

($vals, $name) = $pobj->deformat('abg:1%,2%,3%');
is( ref $vals,        'ARRAY', 'could deformat values with suffix');
is( @$vals,                 3, 'right amount of values');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');
is( $name,           'string', 'found right format name');

($vals, $name) = $pobj->deformat(' abg: 1 %, 2 % , 3% ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in named string');
($vals, $name) = $pobj->deformat(' abg( 1 %, 2 % , 3% ) ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in css string');
($vals, $name) = $pobj->deformat(' abg( 1 , 2  , 3 ) ');
is( ref $vals,        'ARRAY', 'ignored missing suffixes');


($vals, $name) = $obj->deformat( ['ABG',1,2,3] );
is( $name,       'named_array', 'recognized named array');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $obj->deformat( ['ABG',' - 1','2.2 ','.3'] );
is( $name,       'named_array', 'recognized named array with spaces');
is( ref $vals,         'ARRAY', 'got values in a vector');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],             -1, 'first value');
is( $vals->[1],            2.2, 'second value');
is( $vals->[2],             .3, 'third value');

($vals, $name) = $obj->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with lc name');

($vals, $name) = $obj->deformat( [' abg',1,2,3] );
is( ref $vals,              '', 'spaces in name are not acceptable');

($vals, $name) = $pobj->deformat( ['abg',1,2,3] );
is( $name,       'named_array', 'recognized named array with suffix missing');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $pobj->deformat( ['abg',' 1%',' 2 %','3% '] );
is( $name,       'named_array', 'recognized named array with suffix missing');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');


($vals, $name) = $obj->deformat( {a=>1, b=>2, g=>3} );
is( $name,              'hash', 'recognized hash format');
is( ref $vals,         'ARRAY', 'could deformat values');
is( @$vals,                  3, 'right amount of values');
is( $vals->[0],              1, 'first value');
is( $vals->[1],              2, 'second value');
is( $vals->[2],              3, 'third value');

($vals, $name) = $obj->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash format with full names');
($vals, $name) = $pobj->deformat( {ALPHA =>1, BETA =>2, GAMMA=>3} );
is( $name,            'hash', 'recognized hash even when left suffixes');
($vals, $name) = $pobj->deformat( {ALPHA =>'1 %', BETA =>'2% ', GAMMA=>' 3%'} );
is( $name,            'hash', 'recognized hash with suffixes');

exit 0;


__END__


$obj->add_formatter()

$obj->add_deformatter()
