#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 60;

my $module = 'Graphics::Toolkit::Color::Space::Instance::OKHSL';
my $space = eval "require $module";
is( not($@), 1, 'could load the module'); #say $@; exit 0;
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                         'OKHSL', 'color space name is OKHSL');
is( $space->name('alias'),                     '', 'color space has no alias name');
is( $space->is_name('okHSL'),                   1, 'color space name OKHSL is correct, lc chars at will!');
is( $space->is_name('HSL'),                     0, 'color space name HSL is given to HSL');
is( $space->family,                         'HSL', 'OKHSL space is in the HSL family');
is( $space->is_axis_name('okHSL'),              0, 'space name is not axis name');
is( $space->is_axis_name('hue'),                1, '"hue" is an axis name');
is( $space->is_axis_name('saturation'),         1, '"saturation" is an axis name');
is( $space->is_axis_name('lightness'),          1, '"lightness" is an axis name');
is( $space->is_axis_name('hu'),                 0, 'can not miss a lettter of axis name');
is( $space->is_axis_name('h'),                  1, '"h" is an axis name');
is( $space->is_axis_name('s'),                  1, '"a" is an axis name');
is( $space->is_axis_name('l'),                  1, '"l" is an axis name');
is( $space->is_axis_name('m'),                  0, '"m" is not an axis name');
is( $space->is_axis_role('hue'),                1, '"hue" is an axis role');
is( $space->is_axis_role('saturation'),         1, '"saturation" is an axis role');
is( $space->is_axis_role('lightness'),          1, '"lightness" is an axis role');
is( $space->is_axis_role('hu'),                 0, 'can not miss a lettter of axis role');
is( $space->is_axis_role('h'),                  1, '"h" is an axis role');
is( $space->is_axis_role('s'),                  1, '"s" is an axis role');
is( $space->is_axis_role('l'),                  1, '"l" is an axis role');
is( $space->is_axis_role('m'),                  0, '"m" is not an axis role');
is( $space->pos_from_axis_name('hue'),          0, '"hue" is name of first axis');
is( $space->pos_from_axis_name('saturation'),   1, '"saturation" is name of second axis');
is( $space->pos_from_axis_name('lightness'),    2, '"lightness" is name of third axis');
is( $space->pos_from_axis_name('h'),            0, '"h" is name of first axis');
is( $space->pos_from_axis_name('s'),            1, '"s" is name of second axis');
is( $space->pos_from_axis_name('l'),            2, '"l" is name of third axis');
is( $space->pos_from_axis_name('m'),        undef, '"m" is not an axis name');
is( $space->pos_from_axis_role('hue'),          0, '"hue" is role of first axis');
is( $space->pos_from_axis_role('saturation'),   1, '"saturation" is role of second axis');
is( $space->pos_from_axis_role('lightness'),    2, '"lightness" is role of third axis');
is( $space->pos_from_axis_role('h'),            0, '"h" is role of first axis');
is( $space->pos_from_axis_role('s'),            1, '"s" is role of second axis');
is( $space->pos_from_axis_role('l'),            2, '"l" is role of third axis');
is( $space->pos_from_axis_role('m'),        undef, '"m" is not an axis role');
is( $space->axis_count,                         3, 'OKHSL has 3 dimensions');
is( $space->is_euclidean,                       0, 'OKHSL is not euclidean');
is( $space->is_cylindrical,                     1, 'OKHSL is cylindrical');
is( $space->shape->has_constraints,             0, 'OKHSL is a full cylinder');


is( ref $space->check_value_shape([0,0]),              '',   "OKHSL got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),       '',   "OKHSL got too many values");
is( ref $space->check_value_shape([0, 0, 0]),     'ARRAY',   'check minimal OKHSL values are in bounds');
is( ref $space->check_value_shape([360, 1, 1]),   'ARRAY',   'check maximal OKHSL values are in bounds');
is( ref $space->check_value_shape([-0.1, 0, 0]),       '',   "H value is too small");
is( ref $space->check_value_shape([360.01, 0, 0]),     '',   'H value is too big');
is( ref $space->check_value_shape([0, -0.01, 0]),      '',   "S value is too small");
is( ref $space->check_value_shape([0, 1.01, 0]),       '',   'S value is too big');
is( ref $space->check_value_shape([0, 0, -0.1]),       '',   'L value is too small');
is( ref $space->check_value_shape([0, 0, 1.2] ),       '',   "L value is too big");

is( $space->is_value_tuple([0,0,0]),                      1, 'tuple has 3 elements');
is( $space->is_partial_hash({h => 1, l => 0}),            1, 'found hash with some axis names');
is( $space->is_partial_hash({l => 1, s => 0, h => 0}),    1, 'found hash with all short axis names');
is( $space->is_partial_hash({luminance => 1, chroma => 0, hue => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({c => 1, 'h*' => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert( 'LinearRGB'),                    1, 'do only convert from and to LinearRGB');
is( $space->can_convert( 'XYZ'),                          0, 'XYZ ist not converter arent');
is( $space->can_convert( 'OKHSL'),                        0, 'can not convert to itself');
is( $space->format([1.23,0,.41], 'css_string'), 'okhsl(1.23, 0, .41)', 'can format css string');

my $val = $space->deformat(['OKHSL', 0, -1, -0.1]);
is_tuple( $val, [0, -1, -0.1], [qw/hue saturation lightness/], 'deformated named ARRAY into tuple');
$val = $space->deformat(['OKHSL', 0, -1, -0.1]);
is( ref $val,  'ARRAY', 'space name (short) was recognized in named ARRAY format');
is( $space->format([0,11,350], 'css_string'), 'okhsl(0, 11, 350)', 'can format css string');

# black
$val = $space->denormalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue saturation lightness/], 'denormalize black');
$val = $space->normalize( [0, 0, 0] );
is_tuple( $space->round( $val, 9), [0, 0, 0], [qw/hue saturation lightness/], 'normalize black');
my $lch = $space->convert_from( 'LinearRGB',  [ 0, 0.5, 0.5]);
is_tuple( $space->round( $lch, 9), [0, 0, 0], [qw/hue saturation lightness/], 'convert black from LinearRGB');
my $lab = $space->convert_to( 'LinearRGB',  [ 0, 0, 0 ]);
is_tuple( $space->round( $lab, 9), [0, 0.5, 0.5], [qw/r g b/], 'convert black to LinearRGB');

# white
$lch = $space->convert_from( 'LinearRGB',  [ 1, 0.5, 0.5]);
is_tuple( $space->round( $lch, 9), [1, 0, 0], [qw/hue saturation lightness/], 'convert white from LinearRGB');
$lab = $space->convert_to( 'LinearRGB',  [ 1, 0, 0 ]);
is_tuple( $space->round( $lab, 9), [1, 0.5, 0.5], [qw/r g b/], 'convert white to LinearRGB');

# gray
$lch = $space->convert_from( 'LinearRGB',  [ 0.59987, .5, .5]);
is_tuple( $space->round( $lch, 5), [0.59987, 0, 0], [qw/hue saturation lightness/], 'convert gray from LinearRGB');
$lab = $space->convert_to( 'LinearRGB',  [ .53389, 0, 0 ]);
is_tuple( $space->round( $lab, 5), [.53389, 0.5, 0.5], [qw/r g b/], 'convert gray to LinearRGB');

# red
$lch = $space->convert_from( 'LinearRGB',  [ 0.6279553639214311, 0.7248630684262744, 0.625846277330585]);
is_tuple( $space->round( $lch, 5), [0.62796, .51537, .08121], [qw/hue saturation lightness/], 'convert red from LinearRGB');
$lab = $space->convert_to( 'LinearRGB',  [ .627955364, 0.515366608, .081205223]);
is_tuple( $space->round( $lab, 5), [.62796, 0.72486, 0.62585], [qw/r g b/], 'convert red to LinearRGB');

# blue
$lch = $space->convert_from( 'LinearRGB',  [ 0.45201371817442365, 0.467543025, 0.188471834]);
is_tuple( $space->round( $lch, 5), [0.45201, .62643, .73348], [qw/hue saturation lightness/], 'convert blue from LinearRGB');
$lab = $space->convert_to( 'LinearRGB',  [ .45201371817442365, 0.626428778, .733477841 ]);
is_tuple( $space->round( $lab, 5), [.45201, 0.46754, 0.18847], [qw/r g b/], 'convert blue to LinearRGB');

# green
$lch = $space->convert_from( 'LinearRGB',  [ 0.5197518313867289, 0.359697668398572, 0.60767587690661445]);
is_tuple( $space->round( $lch, 5), [0.51975, .35372, .39582], [qw/hue saturation lightness/], 'convert green from LinearRGB');
$lab = $space->convert_to( 'LinearRGB',  [ .5197518313867289, 0.353716489, .395820403 ]);
is_tuple( $space->round( $lab, 5), [.51975, 0.3597, 0.60768], [qw/r g b/], 'convert blue to LinearRGB');

exit 0;
