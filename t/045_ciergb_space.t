#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 58;
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::CIERGB';

my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,           'CIERGB',              'color space has right name');
is( $space->alias,                '',              'color space has no alias name');
is( $space->is_name('CIE_RGB'),    1,              'one way to write the space name');
is( $space->is_name('RGB'),        0,              'CIERGB is not RGB');
is( $space->axis_count,            3,              'CMY color space has 3 axis');
is( $space->is_euclidean,          1,              'CMY is euclidean');
is( $space->is_cylindrical,        0,              'CMY is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('xyz'),                        1,  'do only convert from and to CIEXYZ');
is( $space->can_convert('XYZ'),                        1,  'color space name can be written upper case');
is( $space->can_convert('RGB'),                        0,  'does not convert directly to RGB');
is( $space->is_partial_hash({r => 1, b => 0, g=>0}),   1,  'found hash with some short axis names as keys');
is( $space->is_partial_hash({green => 1, blue => 0}),  1,  'found hash with some other long axis names as keys');
is( $space->is_partial_hash({green => 1, cyan => 0}),  0,  'some axis name match some do not');

is( ref $space->check_value_shape( [0,0,0]),    'ARRAY', 'check LRGB values works on lower bound values');
is( ref $space->check_value_shape( [1, 1, 1]),  'ARRAY', 'check LRGB values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),           '', "LRGB got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),    '', "LRGB got too many values");
is( ref $space->check_value_shape( [-0.1, 0, 0]),    '', "red value is too small");
is( ref $space->check_value_shape( [1.1, 0, 0]),     '', "reg value is too big");
is( ref $space->check_value_shape( [0, -0.001, 0]),  '', "green value is too small");
is( ref $space->check_value_shape( [0, 1.1, 0]),     '', "green value is too big");
is( ref $space->check_value_shape( [0, 0, -0.1 ] ),  '', "blue value is too small");
is( ref $space->check_value_shape( [0, 0, 1.1] ),    '', "blue value is too big");

my $rgb = $space->clamp([]);
is( int @$rgb,   3,     'default color is set by clamp');
is( $rgb->[0],   0,     'default color is black (R) no args');
is( $rgb->[1],   0,     'default color is black (G) no args');
is( $rgb->[2],   0,     'default color is black (B) no args');

$rgb = $space->clamp([0, 1]);
is( int @$rgb,   3,     'clamp added missing argument in vector');
is( $rgb->[0],   0,     'passed (R) value');
is( $rgb->[1],   1,     'passed (G) value');
is( $rgb->[2],   0,     'added (B) value when too few args');

$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is( ref $rgb,   'ARRAY',  'clamped tuple and got tuple back');
is( int @$rgb,   3,     'removed missing argument in value vector by clamp');
is( $rgb->[0],   0,     'clamped up  (R) value to minimum');
is( $rgb->[1],   1,     'clamped down (G) value to maximum');
is( $rgb->[2],  0.5,    'passed (B) value');

$rgb = $space->convert_from( 'RGB', [0, 0.01, 1]);
is( ref $rgb,   'ARRAY', 'converted RGB values tuple into CMY tuple');
is( int @$rgb,   3,      'converted RGB values to CMY');
is( $rgb->[0],   0,      'converted to minimal red value');
is( round_decimals($rgb->[1],9), 0.000773994, 'converted to mid magenta value');
is( $rgb->[2],   1,      'converted to maximal blue value');

($rgb, my $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

$rgb = $space->convert_to( 'RGB', [1, 0.9, 0 ]);
is( ref $rgb,  'ARRAY',  'converted CMY values tuple into RGB tuple');
is( int @$rgb,   3,      'converted CMY to RGB triplets');
is( $rgb->[0],   1,      'converted max red value');
is( round_decimals($rgb->[1],9),   0.954687172,    'converted green value');
is( $rgb->[2],   0,      'converted minimal blue value');

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is( int @$d,    3,      'zero delta vector has right length');
is( $d->[0],    0,      'no delta in R component');
is( $d->[1],    0,      'no delta in G component');
is( $d->[2],    0,      'no delta in B component');

$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is( int @$d,   3,      'delta vector has right length');
is( $d->[0],  -0.1,    'R delta');
is( $d->[1],   0.3,    'G delta');
is( $d->[2],   0.6,    'B delta');

exit 0;

__END__
#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 73;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';


my $module = 'Graphics::Toolkit::Color::Space::Instance::CIEXYZ';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                           'XYZ', 'color space name is XYZ');
is( $space->alias,                       'CIEXYZ', 'color space alias name is CIEXYZ');
is( $space->is_name('xyz'),                     1, 'color space name NCol is correct');
is( $space->is_name('CIExyZ'),                  1, 'axis initials do not equal space name this time');
is( $space->is_name('lab'),                     0, 'axis initials do not equal space name this time');
is( $space->axis_count,                         3, 'color space has 3 axis');
is( $space->is_euclidean,                       1, 'CIEXYZ is euclidean');
is( $space->is_cylindrical,                     0, 'CIEXYZ is not cylindrical');

is( ref $space->check_value_shape([0, 0, 0]),          'ARRAY',  'check minimal XYZ values are in bounds');
is( ref $space->check_value_shape([95.0, 100, 108.8]), 'ARRAY',  'check maximal XYZ values');
is( ref $space->check_value_shape([0,0]),                   '',   "XYZ got too few values");
is( ref $space->check_value_shape([0, 0, 0, 0]),            '',   "XYZ got too many values");
is( ref $space->check_value_shape([-0.1, 0, 0]),            '',   "X value is too small");
is( ref $space->check_value_shape([96, 0, 0]),              '',   "X value is too big");
is( ref $space->check_value_shape([0, -0.1, 0]),            '',   "Y value is too small");
is( ref $space->check_value_shape([0, 100.1, 0]),           '',   "Y value is too big");
is( ref $space->check_value_shape([0, 0, -.1 ] ),           '',   "Z value is too small");
is( ref $space->check_value_shape([0, 0, 108.9] ),          '',   "Z value is too big");

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('linearrgb'),                  1,  'do only convert from and to rgb');
is( $space->can_convert('Linear_RGB'),                 1,  'namespace can be written upper case');
is( $space->can_convert('RGB'),                        0,  'does not convert directly to SRGB');
is( $space->is_partial_hash({x => 1, y => 0}),         1,  'found hash with some keys');
is( $space->is_partial_hash({x => 1, z => 0}),         1,  'found hash with some other keys');
is( $space->can_convert('yiq'),                        0,  'can not convert to yiq');

my $val = $space->deformat(['CIEXYZ', 1, 0, -0.1]);
is( int @$val,    3,       'deformated value triplet (vector)');
is( $val->[0],    1,       'first value good');
is( $val->[1],    0,       'second value good');
is( $val->[2], -0.1,       'third value good');
is( $space->format([0,1,0], 'css_string'), 'xyz(0, 1, 0)', 'can format css string');

# black
my $xyz = $space->convert_from( 'LinearRGB', [ 0, 0, 0]);
is( int @$xyz,   3,   'converted black from RGB to XYZ');
is( $xyz->[0],   0,   'black has right X value');
is( $xyz->[1],   0,   'black has right Y value');
is( $xyz->[2],   0,   'black has right Z value');

my $rgb = $space->convert_to( 'LinearRGB', [0, 0, 0]);
is( int @$rgb,                     3,   'convert back from XYZ to RGB');
is( round_decimals($rgb->[0],  5), 0,   'black has right red value');
is( round_decimals($rgb->[1],  5), 0,   'black has right green value');
is( round_decimals($rgb->[2],  5), 0,   'black has right blue value');

# grey
$xyz = $space->convert_from( 'LinearRGB', [ 0.5, 0.5, 0.5]);
is( ref $xyz,                     'ARRAY',  'converted grey from RGB to XYZ');
is( int @$xyz,                          3,  'got three values');
is( round_decimals($xyz->[0],8), 0.475235,  'grey has right X value');
is( round_decimals($xyz->[1],8), 0.50000005,'grey has right Y value');
is( round_decimals($xyz->[2],8), 0.544415,  'grey has right Z value');

$rgb = $space->convert_to( 'LinearRGB', [0.475235, 0.50000005, 0.544415]);
is( int @$rgb,                       3,   'converted gray from XYZ to RGB');
is( round_decimals($rgb->[0], 6),  0.5,   'grey has right red value');
is( round_decimals($rgb->[1], 6),  0.5,   'grey has right green value');
is( round_decimals($rgb->[2], 6),  0.5,   'grey has right blue value');

# white
$xyz = $space->convert_from( 'LinearRGB', [1, 1, 1]);
is( int @$xyz,                            3, 'converted white from RGB to XYZ');
is( round_decimals($xyz->[0],   5), 0.95047, 'white has right X value');
is( round_decimals($xyz->[1],   5), 1,       'white has right Y value');
is( round_decimals($xyz->[2],   5), 1.08883, 'white has right Z value');

$rgb = $space->convert_to( 'LinearRGB', [0.95047, 1, 1.08883]);
is( int @$rgb,                      3,  'converted back gray with 3 values');
is( round_decimals($rgb->[0],  5),  1,  'white has right red value');
is( round_decimals($rgb->[1],  5),  1,  'white has right green value');
is( round_decimals($rgb->[2],  5),  1,  'white has right blue value');

# pink
$xyz = $space->convert_from( 'LinearRGB', [1, 0, 0.5]);
is( int @$xyz,                          3, 'converted pink from RGB to XYZ');
is( round_decimals($xyz->[0], 9), 0.502675181, 'pink has right X value');
is( round_decimals($xyz->[1], 9), 0.248760383, 'pink has right Y value');
is( round_decimals($xyz->[2], 9), 0.494485935, 'pink has right Z value');

$rgb = $space->convert_to( 'LinearRGB', [0.502675181, 0.248760383, 0.494485935]);
is( int @$rgb,                      3,   'converted gray from XYZ to RGB');
is( round_decimals($rgb->[0], 5),   1,   'pink has right red value');
is(        $rgb->[1] < 0.0000001,   1,   'pink has right green value');
is( round_decimals($rgb->[2], 5), 0.5,   'pink has right blue value');

# mid blue
$xyz = $space->convert_from( 'LinearRGB', [.2, .2, .6]);
is( int @$xyz,                           3,  'convert mid blue from RGB to XYZ');
is( round_decimals($xyz->[0], 9), 0.262268993,  'mid blue has right X value');
is( round_decimals($xyz->[1], 9), 0.228870045,  'mid blue has right Y value');
is( round_decimals($xyz->[2], 9), 0.597887631,  'mid blue has right Z value');

$rgb = $space->convert_to( 'LinearRGB', [0.262268993, 0.228870045, 0.597887631]);
is( int @$rgb,                      3,   'convert mid blue from XYZ to RGB');
is( round_decimals($rgb->[0], 5), .2  ,  'mid blue has right red value');
is( round_decimals($rgb->[1], 5), .2  ,  'mid blue has right green value');
is( round_decimals($rgb->[2], 5), .6  ,  'mid blue has right blue value');

exit 0;
