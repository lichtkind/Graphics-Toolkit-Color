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
is( $name,           'string', 'recognized named string format');


($vals, $name) = $pobj->deformat(' abg( 1 %, 2 % , 3% ) ');
is( ref $vals,        'ARRAY', 'ignored inserted spaces in css string');
is( $name,       'css_string', 'recognized CSS string format');
($vals, $name) = $pobj->deformat(' abg( 1 , 2  , 3 ) ');
is( ref $vals,        'ARRAY', 'ignored missing suffixes');
is( $name,       'css_string', 'recognized CSS string format');
is( $vals->[0],             1, 'first value');
is( $vals->[1],             2, 'second value');
is( $vals->[2],             3, 'third value');


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



my (@list) = $obj->format( [0,2.2,-3], 'list');
is( @list,                   3, 'got a list with right lengths');
is( $list[0],                0, 'first value');
is( $list[1],              2.2, 'second value');
is( $list[2],               -3, 'third value');

my $hash = $obj->format( [0,2.2,-3], 'hash');
is( ref $hash,          'HASH', 'could format into HASH');
is( int keys %$hash,         3, 'right amount of keys');
is( $hash->{'alpha'},        0, 'first value');
is( $hash->{'beta'},       2.2, 'second value');
is( $hash->{'gamma'},       -3, 'third value');

$hash = $obj->format( [0,2.2,-3], 'char_hash');
is( ref $hash,          'HASH', 'could format into HASH with character keys');
is( int keys %$hash,         3, 'right amount of keys');
is( $hash->{'a'},            0, 'first value');
is( $hash->{'b'},          2.2, 'second value');
is( $hash->{'g'},           -3, 'third value');

my $array = $obj->format( [0,2.2,-3], 'array');
is( ref $array,          'ARRAY', 'could format into HASH with character keys');
is( int@$array,                4, 'right amount of elements');
is( $array->[0],           'ABG', 'first value is color space name');
is( $array->[1],               0, 'first numerical value');
is( $array->[2],             2.2, 'second numerical value');
is( $array->[3],              -3, 'third numerical value');

my $string = $obj->format( [0,2.2,-3], 'string');
is( ref $string,              '', 'could format into string');
is( $string,       'abg: 0, 2.2, -3', 'string syntax ist correct');

$string = $obj->format( [0,2.2,-3], 'css_string');
is( ref $string,                '', 'could format into CSS string');
is( $string,       'abg(0,2.2,-3)', 'string syntax ist correct');

$string = $pobj->format( [0,2.2,-3], 'css_string');
is( ref $string,                '', 'could format into CSS string with suffixes');
is( $string,       'abg(0%,2.2%,-3%)', 'string syntax ist correct');

exit 0;

__END__

$obj->add_formatter()
$obj->add_deformatter()

   $rgb_def->add_formatter(   'hex',   \&hex_from_rgb );
   $rgb_def->add_deformatter( 'hex',   sub { rgb_from_hex(@_) if is_hex(@_) } );
   $rgb_def->add_deformatter( 'array', sub { $_[1] if $rgb_def->is_value_tuple( $_[1] ) } );


sub hex_from_rgb {  return unless @_ == $rgb_def->dimensions;  sprintf "#%02x%02x%02x", @_ }

sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my $hex = shift;
    return carp "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
    unless defined $hex and (length($hex) == 4 or length($hex) == 7) and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    (length $hex == 3) ? (map { CORE::hex($_.$_) } unpack( "a1 a1 a1", $hex))
                       : (map { CORE::hex($_   ) } unpack( "a2 a2 a2", $hex));
}

sub is_hex { defined $_[0] and ($_[0] =~ /^#[[:xdigit:]]{3}$/ or $_[0] =~ /^#[[:xdigit:]]{6}$/)}
