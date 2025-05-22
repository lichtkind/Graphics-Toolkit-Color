#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 128;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Basis';

use_ok( $module, 'could load the module');

my $obj = Graphics::Toolkit::Color::Space::Basis->new();
like( $obj,   qr/first argument/,      'constructor needs arguments');

$obj = Graphics::Toolkit::Color::Space::Basis->new([1]);
is( ref $obj, $module,  'one constructor argument is enough');

my $bad = Graphics::Toolkit::Color::Space::Basis->new(qw/Aleph beth gimel daleth he/);
my $odd = Graphics::Toolkit::Color::Space::Basis->new([qw/Aleph beth gimel daleth he/], [qw/m n p q/]);
my $s3d = Graphics::Toolkit::Color::Space::Basis->new([qw/Alpha beta gamma/]);
my $s5d = Graphics::Toolkit::Color::Space::Basis->new([qw/Aleph beth gimel daleth he/], [qw/m n o p q/]);

like( $bad,   qr/first argument/,   'need axis name array as first argument');
like( $odd,  qr/shortcut names/,   'need same amount axis names and shortcuts');
is( ref $s3d,  $module,   'created 3d space');
is( ref $s5d,  $module,   'created 5d space');

is( $s3d->count,               3,     'did count three args');
is( $s5d->count,               5,     'did count five args');
is( int($s3d->long_names)  == $s3d->count,     1,     'right amount of long names in 3d color space');
is( int($s3d->short_names) == $s3d->count,     1,     'right amount of short names in 3d color space');
is( int($s5d->long_names)  == $s5d->count,     1,     'right amount of long names for 5d');
is( int($s5d->short_names) == $s5d->count,     1,     'right amount of short names for 5d');
is( ($s3d->long_names)[0],     'alpha',     'repeat first 3d key back');
is( ($s3d->long_names)[-1],    'gamma',     'repeat last 5d key back');
is( ($s5d->long_names)[0],     'aleph',     'repeat first 3d key back');
is( ($s5d->long_names)[-1],       'he',     'repeat last 5d key shortcut back');
is( ($s3d->short_names)[0],        'a',     'repeat first 3d key shortcut back');
is( ($s3d->short_names)[-1],       'g',     'repeat last 5d key shortcut back');
is( ($s5d->short_names)[0],        'm',     'repeat first 3d key shortcut back');
is( ($s5d->short_names)[-1],       'q',     'repeat last 5d key shortcut back');
is( $s3d->space_name,            'ABG',     'correct name from 3 initials');
is( $s5d->space_name,          'MNOPQ',     'correct name from 5 initials');
is( ($s3d->iterator)[-1],      2,     'correct last value of 0..2 iterator');
is( ($s5d->iterator)[-1],      4,     'correct last value of 0..4 iterator');

is( $s3d->is_long_name('Alpha'),     1,     'found key alpha');
is( $s3d->is_long_name('zeta'),      0,     'not found made up key zeta');
is( $s5d->is_long_name('gimel'),     1,     'found key gimel');
is( $s5d->is_long_name('lamed'),     0,     'not found made up key lamed');

is( $s3d->is_short_name('G'),    1,     'found key shortcut g');
is( $s3d->is_short_name('e'),    0,     'not found made up key shortcut e');
is( $s5d->is_short_name('P'),    1,     'found key shortcut H');
is( $s5d->is_short_name('l'),    0,     'not found made up key shortcut l');

is( $s3d->is_name('Alpha'),  1, 'alpha is a key');
is( $s3d->is_name('A'),      1, 'a is a shortcut');
is( $s3d->is_name('Cen'),    0, 'Cen is not a key');
is( $s3d->is_name('C'),      0, 'c is not a shortcut');

is( $s3d->is_value_tuple({}),                 0, 'HASH is not an ARRAY');
is( $s3d->is_value_tuple([]),                 0, 'empty ARRAY has not enogh content');
is( $s3d->is_value_tuple([2,2]),              0, 'too small ARRAY');
is( $s3d->is_value_tuple([1,2,3,4]),          0, 'too large ARRAY');
is( $s3d->is_value_tuple([1,2,3]),            1, 'correctly sized value ARRAY');

is( $s3d->pos_from_long('alpha'),  0,         'alpha name of first axis');
is( $s3d->pos_from_long('beta'),   1,         'beta is name of second axis');
is( $s3d->pos_from_long('emma'),   undef,     'emma is not an axis name');
is( $s5d->pos_from_long('aleph'),  0,         'aleph is the first name');
is( $s5d->pos_from_long('he'),     4,         'he is the fourth nam');
is( $s5d->pos_from_long('emma'),   undef,     'emma is not an axis name');

is( $s3d->short_from_long_name('alpha'),  'a',    'a is short for alpha');
is( $s3d->short_from_long_name('BETA'),   'b',    'upper case axis name recognized');
is( $s3d->short_from_long_name('emma'),  undef,   'emma is not a an axis name and there fore has no shortcut');
is( $s5d->short_from_long_name('He'),     'q',    'custom shortcut provided');
is( $s3d->long_from_short_name('a'),  'alpha',    'alpha is long axis name for shortcut a');
is( $s3d->long_from_short_name('B'),   'beta',    'upper case shortcut recognized');
is( $s3d->long_from_short_name('e'),    undef,    'e is not a a shortcut axis name: there is no full name');
is( $s5d->long_from_short_name('q'),     'he',    'long axis name from custom shortcut');

is( $s3d->is_hash([]),                  0, 'array is not a hash');
is( $s3d->is_hash({alpha => 1, beta => 20, gamma => 3}), 1, 'valid hash with right keys');
is( $s3d->is_hash({ALPHA => 1, Beta => 20, gamma => 3}), 1, 'key casing gets ignored');
is( $s3d->is_hash({a => 1, b => 1, g => 3}),             1, 'valid shortcut hash');
is( $s3d->is_hash({a => 1, B => 1, g => 3}),             1, 'shortcut casing gets ignored');
is( $s3d->is_hash({a => 1, b => 1, g => 3, h => 4}),     0, 'too many hash key shortcut ');
is( $s3d->is_hash({alph => 1, beth => 1, gimel => 4, daleth => 2, he => 4}), 0, 'one wrong hash key');

is( $s5d->is_partial_hash(''),             0,      'string is not a partial hash');
is( $s5d->is_partial_hash([]),             0,      'array is not a partial hash');
is( $s5d->is_partial_hash({}),             0,      'empty hash is not a partial hash');
is( $s5d->is_partial_hash({gamma => 1}),   0,      'wrong key for partial hash');
is( $s5d->is_partial_hash({aleph => 1, beth => 2, gimel => 3, daleth => 4, he => 5}), 1, 'valid hash with right keys is also correct partial hash');
is( $s5d->is_partial_hash({aleph => 1, beth => 20, gimel => 3, daleth => 4, he => 5, o => 6}), 0, 'partial hash can not have more keys than full hash definition');
is( $s5d->is_partial_hash({aleph => 1 }),              1, 'valid partial hash to have only one korrect key');
is( $s5d->is_partial_hash({ALEPH => 1 }),              1, 'ignore casing');
is( $s5d->is_partial_hash({aleph => 1, bet => 2, }),  0, 'one bad key makes partial invalid');

is( ref $s3d->short_name_hash_from_tuple([1,2,3]),   'HASH',    'HASH with given values and shortcut keys created');
is( ref $s3d->short_name_hash_from_tuple([1,2,3,4]),     '',    'HASH not created because too many arguments');
is( ref $s3d->short_name_hash_from_tuple([1,2]),         '',    'HASH not created because not enough arguments');
is( $s3d->short_name_hash_from_tuple([1,2,3])->{'a'},     1,    'right value under "a" key in the converted hash');
is( $s3d->short_name_hash_from_tuple([1,2,3])->{'b'},     2,    'right value under "b" key in the converted hash');
is( $s3d->short_name_hash_from_tuple([1,2,3])->{'g'},     3,    'right value under "g" key in the converted hash');
is( int keys %{$s3d->short_name_hash_from_tuple([1,2,3])},3,    'right amount of shortcut keys');

is( ref $s5d->long_name_hash_from_tuple([1,2,3,4,5]),'HASH',    'HASH with given values and full name keys created');
is( ref $s5d->long_name_hash_from_tuple([1,2,3,4,5,6]),  '',    'HASH not created because too many arguments');
is( ref $s5d->long_name_hash_from_tuple([1,2,3,4]),      '',    'HASH not created because not enough arguments');
is( $s5d->long_name_hash_from_tuple([1,2,3,4,5])->{'aleph'},   1,    'right value under "aleph" key in the converted hash');
is( $s5d->long_name_hash_from_tuple([1,2,3,4,5])->{'beth'},    2,    'right value under "beta" key in the converted hash');
is( $s5d->long_name_hash_from_tuple([1,2,3,4,5])->{'gimel'},   3,    'right value under "gimel" key in the converted hash');
is( $s5d->long_name_hash_from_tuple([1,2,3,4,5])->{'daleth'},  4,    'right value under "daleth" key in the converted hash');
is( $s5d->long_name_hash_from_tuple([1,2,3,4,5])->{'he'},      5,    'right value under "he" key in the converted hash');
is( int keys %{$s5d->long_name_hash_from_tuple([1,2,3,4,5])},  5,    'right amount of shortcut keys');

my $tuple = $s5d->tuple_from_hash( {aleph => 1, beth => 2, gimel => 3, daleth => 4, he => 5} );
is( ref $tuple,  'ARRAY', 'got ARRAY ref from method tuple_from_hash');
is( int @$tuple,  5, 'right of values extracted keys');
is( $tuple->[0],   1, 'first extracted value is correct');
is( $tuple->[1],   2, 'second extracted value is correct');
is( $tuple->[2],   3, 'third extracted value is correct');
is( $tuple->[3],   4, 'fourth extracted value is correct');
is( $tuple->[4],   5, 'fifth extracted value is correct');
$tuple = $s5d->tuple_from_hash( {aleph => 1, beth => 2, O => 3, daleth => 4, y => 5} );
is( ref $tuple,  '', 'no values extraced because one key was wrong');

is( $s3d->select_tuple_value_from_name('alpha', [1,2,3]), 1,   'got correct first value from list by key');
is( $s3d->select_tuple_value_from_name('beta',  [1,2,3]), 2,   'got correct second value from list by key');
is( $s3d->select_tuple_value_from_name('gamma', [1,2,3]), 3,   'got correct third value from list by key');
is( $s3d->select_tuple_value_from_name('he',    [1,2,3]), undef, 'get undef when asking with unknown key');
is( $s3d->select_tuple_value_from_name('alpha', [1,2  ]), undef, 'get undef when giving not enough values');

is( $s3d->select_tuple_value_from_name('a', [1,2,3]), 1,       'got correct first value from list by shortcut');
is( $s3d->select_tuple_value_from_name('b', [1,2,3]), 2,       'got correct second value from list by shortcut');
is( $s3d->select_tuple_value_from_name('g', [1,2,3]), 3,       'got correct third value from list by shortcut');
is( $s3d->select_tuple_value_from_name('h', [1,2,3]), undef,   'get undef when asking with unknown key');
is( $s3d->select_tuple_value_from_name('a ',[1,2  ]), undef,         'get undef when giving not enough values');


is( ref $s3d->pos_hash_from_partial_hash(),   '',       'partial deformat needs an HASH');
is( $s3d->pos_hash_from_partial_hash({}),  undef,       'partial deformat needs an not empty HASH');
is( $s3d->pos_hash_from_partial_hash({a=>1,b=>1,g=>1,k=>1}), undef,       'partial HASH is too long');
is( ref $s3d->pos_hash_from_partial_hash({a=>1,b=>2,g=>3}), 'HASH',       'partial HASH has all the keys');
my $ph = $s3d->pos_hash_from_partial_hash({Alpha=>1,b=>2,g=>3});
is( ref $ph, 'HASH',   'deparse all keys with mixed case and shortcut');
is( $ph->{0}, 1,       'first key has right value');
is( $ph->{1}, 2,       'second key has right value');
is( $ph->{2}, 3,       'third key has right value');
is( int keys %$ph, 3,  'right amount of keys in deparsed hash');

$ph = $s3d->pos_hash_from_partial_hash({gamma => 3});
is( ref $ph, 'HASH',   'deparse just one key with mixed case and shortcut');
is( $ph->{2}, 3,       'third and only key has right value');
is( int keys %$ph, 1,  'right amount of keys in deparsed hash');
$ph = $s3d->pos_hash_from_partial_hash({alda => 3});
is( ref $ph, '',       'wrong keys to be partial hash');


$ph = $s5d->pos_hash_from_partial_hash({Aleph => 6, q => 5});
is( ref $ph, 'HASH',   'deparse just two keys with mixed case and shortcut');
is( $ph->{0}, 6,       'first key aleph has right value');
is( $ph->{4}, 5,       'second key He has right value');
is( int keys %$ph, 2,  'right amount of keys in deparsed hash');

my $p5d = Graphics::Toolkit::Color::Space::Basis->new([qw/Aleph beth gimel daleth he/], [qw/m n o p q/], undef, 'name');
is( ref $p5d,  $module,  'created space with none rule based name');
is( $p5d->space_name, 'name',  'got correct specially set name');

my $p5p = Graphics::Toolkit::Color::Space::Basis->new([qw/Aleph beth gimel daleth he/], [qw/m n o p q/], 'pre');
is( ref $p5p,  $module,  'created space with name prefix');
is( $p5p->space_name, 'preMNOPQ',  'got correct name with prefix');

my $p5pn = Graphics::Toolkit::Color::Space::Basis->new([qw/Aleph beth gimel daleth he/], [qw/m n o p q/], 'PRE', 'name');
is( $p5pn->space_name, 'PREname',  'got correct name with prefix');

exit 0;
