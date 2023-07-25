#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 66;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::SpaceKeys';

eval "use $module";
is( not($@), 1, 'could load the module');

my $obj = Graphics::Toolkit::Color::SpaceKeys->new();
is( $obj,  undef,       'constructor needs arguments');
$obj = Graphics::Toolkit::Color::SpaceKeys->new(1);
is( ref $obj, $module,  'one constructor argument is enough');

my $s3d = Graphics::Toolkit::Color::SpaceKeys->new(qw/Alpha beta gamma/);
my $s5d = Graphics::Toolkit::Color::SpaceKeys->new(qw/Aleph beth gimel daleth he/);
is( $s3d->count,         3,     'did count three args');
is( $s5d->count,         5,     'did count five args');
is( ($s3d->keys)[0],    'alpha',     'repeat first 3d key back');
is( ($s3d->keys)[-1],   'gamma',     'repeat last 5d key back');
is( ($s5d->keys)[0],    'aleph',     'repeat first 3d key back');
is( ($s5d->keys)[-1],   'he',        'repeat last 5d key shortcut back');
is( ($s3d->shortcuts)[0],    'a',    'repeat first 3d key shortcut back');
is( ($s3d->shortcuts)[-1],   'g',    'repeat last 5d key shortcut back');
is( ($s5d->shortcuts)[0],    'a',    'repeat first 3d key shortcut back');
is( ($s5d->shortcuts)[-1],   'h',    'repeat last 5d key shortcut back');
is( $s3d->name,         'abg',       'correct name from 3 initials');
is( $s5d->name,         'abgdh',     'correct name from 5 initials');
is( ($s3d->iterator)[-1],   2,       'correct last value of 0..2 iterator');
is( ($s5d->iterator)[-1],   4,       'correct last value of 0..4 iterator');

is( $s3d->is_key('Alpha'),  1,       'found key alpha');
is( $s3d->is_key('zeta'),   0,       'not found made up key zeta');
is( $s5d->is_key('gimel'),  1,       'found key gimel');
is( $s5d->is_key('lamed'),  0,       'not found made up key lamed');

is( $s3d->is_shortcut('G'),   1,      'found key shortcut g');
is( $s3d->is_shortcut('e'),   0,      'not found made up key shortcut e');
is( $s5d->is_shortcut('H'),   1,      'found key shortcut H');
is( $s5d->is_shortcut('l'),   0,      'not found made up key shortcut l');

is( $s3d->is_hash([]),        0,      'array is not a hash');
is( $s3d->is_hash({aleph => 1, beta => 20, gamma => 3}), 1, 'valid hash with right keys');
is( $s3d->is_hash({Aleph => 1, beta => 20, gamma => 3}), 1, 'key casing gets ignored');
is( $s3d->is_hash({a => 1, b => 1, g => 3}),             1, 'valid shortcut hash');
is( $s3d->is_hash({a => 1, B => 1, g => 3}),             1, 'shortcut casing gets ignored');
is( $s3d->is_hash({a => 1, b => 1, g => 3, h => 4}),     0, 'too many hash key shortcut ');
is( $s3d->is_hash({alph => 1, beth => 1, gimel => 4, daleth => 2, he => 4}), 0, 'one wrong hash key');


is( ref $s3d->shortcut_hash_from_list(1,2,3),  'HASH',      'HASH with given values and shortcut keys created');
is( ref $s3d->shortcut_hash_from_list(1,2,3,4),    '',      'HASH not created because too many arguments');
is( ref $s3d->shortcut_hash_from_list(1,2),        '',      'HASH not created because not enough arguments');
is( $s3d->shortcut_hash_from_list(1,2,3)->{'a'},  1,        'right value under "a" key in the converted hash');
is( $s3d->shortcut_hash_from_list(1,2,3)->{'b'},  2,        'right value under "b" key in the converted hash');
is( $s3d->shortcut_hash_from_list(1,2,3)->{'g'},  3,        'right value under "g" key in the converted hash');
is( int keys %{$s3d->shortcut_hash_from_list(1,2,3)},  3,   'right amount of shortcut keys');

is( ref $s5d->key_hash_from_list(1,2,3,4,5),  'HASH',      'HASH with given values and full name keys created');
is( ref $s5d->key_hash_from_list(1,2,3,4,5,6),    '',      'HASH not created because too many arguments');
is( ref $s5d->key_hash_from_list(1,2,3,4),        '',      'HASH not created because not enough arguments');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'aleph'},  1,    'right value under "aleph" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'beth'},   2,    'right value under "beta" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'gimel'},  3,    'right value under "gimel" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'daleth'}, 4,    'right value under "daleth" key in the converted hash');
is( $s5d->key_hash_from_list(1,2,3,4,5)->{'he'},     5,    'right value under "he" key in the converted hash');
is( int keys %{$s5d->key_hash_from_list(1,2,3,4,5)},  5, 'right amount of shortcut keys');

my $list = $s5d->list_from_hash( {alph => 1, beth => 2, G => 3, daleth => 4, h => 5} );
is( ref $list,  'ARRAY', 'values extraced');
is( int @$list,  5, 'right of values extracted keys');
is( $list->[0],  1, 'first extracted value is correct');
is( $list->[1],  2, 'second extracted value is correct');
is( $list->[2],  3, 'third extracted value is correct');
is( $list->[3],  4, 'fourth extracted value is correct');
is( $list->[4],  5, 'fifth extracted value is correct');
$list = $s5d->list_from_hash( {alph => 1, beth => 2, G => 3, daleth => 4, y => 5} );
is( ref $list,  '', 'no values extraced because one key was wrong');

is( $s3d->list_value_from_key('alpha', 1,2,3), 1,   'got correct first value from list by key');
is( $s3d->list_value_from_key('beta', 1,2,3),  2,   'got correct second value from list by key');
is( $s3d->list_value_from_key('gamma', 1,2,3), 3,   'got correct third value from list by key');
is( $s3d->list_value_from_key('he', 1,2,3), undef,  'get undef when asking with unknown key');
is( $s3d->list_value_from_key('alpha', 1,2), undef, 'get undef when giving not enough values');

is( $s3d->list_value_from_shortcut('a', 1,2,3), 1,       'got correct first value from list by shortcut');
is( $s3d->list_value_from_shortcut('b', 1,2,3), 2,       'got correct second value from list by shortcut');
is( $s3d->list_value_from_shortcut('g', 1,2,3), 3,       'got correct third value from list by shortcut');
is( $s3d->list_value_from_shortcut('h', 1,2,3), undef,   'get undef when asking with unknown key');
is( $s3d->list_value_from_key('a ', 1,2), undef,         'get undef when giving not enough values');

exit 0;
