#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 60;

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKHWB';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKHWB', 'color space name is OKHWB');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('okHWB'),                   1, 'color space name okHWB is correct, lc chars at will!');
is( $space->is_name('HWB'),                     0, 'color space name HWB is given to OKHWB');
is( $space->family,                         'HWB', 'OKHWB space is in the HWB family');
is( $space->is_axis_name('OKHWB'),              0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                1, '"hue" is an axis name');
is( $space->is_axis_name('whiteness'),          1, '"whiteness" is an axis name');
is( $space->is_axis_name('blackness'),          1, '"blackness" is an axis name');
is( $space->is_axis_name('hu'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('h'),                  1, '"h" is an axis name');
is( $space->is_axis_name('w'),                  1, '"w" is an axis name');
is( $space->is_axis_name('b'),                  1, '"b" is an axis name');
is( $space->is_axis_role('hue'),                1, '"hue" is an axis role');
is( $space->is_axis_role('whiteness'),          1, '"whiteness" is an axis role');
is( $space->is_axis_role('blackness'),          1, '"blackness" is an axis role');
is( $space->is_axis_role('hu'),                 0, 'can not miss a lettter of axis role');
is( $space->is_axis_role('h'),                  1, '"h" is an axis role');
is( $space->is_axis_role('w'),                  1, '"w" is an axis role');
is( $space->is_axis_role('b'),                  1, '"b" is an axis role');
is( $space->is_axis_role('m'),                  0, '"m" is not an axis role');
is( $space->pos_from_axis_name('hue'),          0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('whiteness'),    1, '"whiteness" is name of second axis');
is( $space->pos_from_axis_name('blackness'),    2, '"blackness" is name of third axis');
is( $space->pos_from_axis_name('h'),            0, '"h" is name of first axis');
is( $space->pos_from_axis_name('w'),            1, '"w" is name of second axis');
is( $space->pos_from_axis_name('b'),            2, '"b" is name of third axis');
is( $space->pos_from_axis_name('*'),        undef, '"*" is not an axis name');
is( $space->pos_from_axis_role('hue'),          0, '"hue" is role of first axis');
is( $space->pos_from_axis_role('whiteness'),    1, '"whiteness" is role of second axis');
is( $space->pos_from_axis_role('blackness'),    2, '"blackness" is role of third axis');
is( $space->pos_from_axis_role('h'),            0, '"h" is role of first axis');
is( $space->pos_from_axis_role('w'),            1, '"w" is role of second axis');
is( $space->pos_from_axis_role('b'),            2, '"b" is role of third axis');
is( $space->pos_from_axis_role('m'),        undef, '"m" is not an axis role');
is( $space->axis_count,                         3, 'OKHWB has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKHWB is not euclidean');
is( $space->is_cylindrical,                     1, 'OKHWB is cylindrical');

is( ref $space->check_value_shape([0,0]),              '',   "OKLCH got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKLCH got too many values");
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY',   'check minimal OKLCH values are in bounds');
is( ref $space->check_value_shape([1, 0.5, 360]), 'ARRAY',   'check maximal OKLCH values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->check_value_shape([1.01, 0, 0]),       '',   'L value is too big');
is( ref $space->check_value_shape([0, -0.51, 0]),      '',   "c value is too small");
is( ref $space->check_value_shape([0, 0.51, 0]),       '',   'c value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'h value is too small');
is( ref $space->check_value_shape([0, 0, 360.2] ),     '',   "h value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({c => 1, h => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({l => 1, c => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, 'h*' => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'OKHSV'),                        1, 'do only convert from and to OKHSV');
is( $space->can_convert( 'Lab'),                          0, 'namespace can be written lower case');
is( $space->can_convert( 'OKHWB'),                        0, 'can not convert to itself');
is( $space->format([1.23,0,41], 'css_string'), 'okhwb(1.23, 0, 41)', 'can format css string');

my $val = $space->deformat(['OKHWB', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/hue whiteness blackness/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['OKHWB', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,1,1], 'css_string'), 'okhwb(0, 1, 1)', 'can format css string');

# black
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue whiteness blackness/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue whiteness blackness/], 'normalize black');
my $lch = $space->convert_from( 'OKHSV',  [ 0, 0.5, 0.5]);
is_tuple( $space->round( $lch, 9), [0, 0, 0], [qw/hue whiteness blackness/], 'convert black from OKHSV');
my $lab = $space->convert_to( 'OKHSV',  [ 0, 0, 0 ]);
is_tuple( $space->round( $lab, 9), [0, 0.5, 0.5], [qw/hue saturation value/], 'convert black to OKHSV');

# white
$lch = $space->convert_from( 'OKHSV',  [ 1, 0.5, 0.5]);
is_tuple( $space->round( $lch, 9), [1, 0, 0], [qw/hue whiteness blackness/], 'convert white from OKHSV');
$lab = $space->convert_to( 'OKHSV',  [ 1, 0, 0 ]);
is_tuple( $space->round( $lab, 9), [1, 0.5, 0.5], [qw/hue saturation value/], 'convert white to OKHSV');

# gray
$lch = $space->convert_from( 'OKHSV',  [ 0.59987, .5, .5]);
is_tuple( $space->round( $lch, 5), [0.59987, 0, 0], [qw/hue whiteness blackness/], 'convert gray from OKHSV');
$lab = $space->convert_to( 'OKHSV',  [ .53389, 0, 0 ]);
is_tuple( $space->round( $lab, 5), [.53389, 0.5, 0.5], [qw/hue saturation value/], 'convert gray to OKHSV');

# red
$lch = $space->convert_from( 'OKHSV',  [ 0.6279553639214311, 0.7248630684262744, 0.625846277330585]);
is_tuple( $space->round( $lch, 5), [0.62796, .51537, .08121], [qw/hue whiteness blackness/], 'convert red from OKHSV');
$lab = $space->convert_to( 'OKHSV',  [ .627955364, 0.515366608, .081205223]);
is_tuple( $space->round( $lab, 5), [.62796, 0.72486, 0.62585], [qw/hue saturation value/], 'convert red to OKHSV');

# blue
$lch = $space->convert_from( 'OKHSV',  [ 0.45201371817442365, 0.467543025, 0.188471834]);
is_tuple( $space->round( $lch, 5), [0.45201, .62643, .73348], [qw/hue whiteness blackness/], 'convert blue from OKHSV');
$lab = $space->convert_to( 'OKHSV',  [ .45201371817442365, 0.626428778, .733477841 ]);
is_tuple( $space->round( $lab, 5), [.45201, 0.46754, 0.18847], [qw/hue saturation value/], 'convert blue to OKHSV');

# green
$lch = $space->convert_from( 'OKHSV',  [ 0.5197518313867289, 0.359697668398572, 0.60767587690661445]);
is_tuple( $space->round( $lch, 5), [0.51975, .35372, .39582], [qw/hue whiteness blackness/], 'convert green from OKHSV');
$lab = $space->convert_to( 'OKHSV',  [ .5197518313867289, 0.353716489, .395820403 ]);
is_tuple( $space->round( $lab, 5), [.51975, 0.3597, 0.60768], [qw/hue saturation value/], 'convert blue to OKHSV');

exit 0;
