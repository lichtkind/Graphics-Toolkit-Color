#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 150;
BEGIN { unshift @INC, 'lib', '../lib'}

my $module = 'Graphics::Toolkit::Color::Values';
use_ok( $module, 'could load the module');
my (@values, $values);
#### new_from_tuple ####################################################
is( ref Graphics::Toolkit::Color::Values->new_from_tuple(),  '',  'new need at least one argument');
my $fuchsia_rgb = Graphics::Toolkit::Color::Values->new_from_tuple([255,0,256], 'RGB');
is( ref $fuchsia_rgb,               $module,  'created values object from normalized RGB values');
is( $fuchsia_rgb->{'source_values'},     '',  'object source are RGB values');
is( $fuchsia_rgb->{'source_space_name'}, '',  'not from any other space');
is( $fuchsia_rgb->name,           'fuchsia',  'color has name "fuchsia"');
is( ref $fuchsia_rgb->{'rgb'},      'ARRAY',  'RGB tuple is an ARRAY');
is( @{$fuchsia_rgb->{'rgb'}},             3,  'RGB tuple has three values');
is( $fuchsia_rgb->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $fuchsia_rgb->{'rgb'}[1],             0,  'violet has a no green color');
is( $fuchsia_rgb->{'rgb'}[2],             1,  'violet has a maximal blue color, got clamped');
$values = $fuchsia_rgb->normalized();
is( ref $values,                 'ARRAY',  'normalized value tuple is an ARRAY');
is( @$values,                          3,  'and has three values');
is( $values->[0],                      1,  'red value is as expected');
is( $values->[1],                      0,  'green value is as expected');
is( $values->[2],                      1,  'blue value is as expected');
is( $fuchsia_rgb->formatted('', 'named_string'),  'rgb: 255, 0, 255',  'got color formatted into named RGB string');
is( $fuchsia_rgb->formatted('CMY', 'CSS_string', undef, 10),  'cmy(0, 10, 0)',  'got color formatted into CMY CSS string');
$values = $fuchsia_rgb->formatted( '', 'ARRAY', undef, [20,30,40]);
is( ref $values,                 'ARRAY',  'RGB value ARRAY');
is( @$values,                          3,  'has three values');
is( $values->[0],                     20,  'red value is in hand crafted range');
is( $values->[1],                      0,  'green value is as expected');
is( $values->[2],                     40,  'blue value is in hand crafted range');
$values = $fuchsia_rgb->formatted( 'CMY', 'ARRAY', [20,30,40]);
is( ref $values,                   '',  'ARRAY format is only for RGB');

my $fuchsia_cmy = Graphics::Toolkit::Color::Values->new_from_tuple([0,1,0], 'CMY');
is( ref $fuchsia_cmy,                  $module,  'value object from CMY values');
is( ref $fuchsia_cmy->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$fuchsia_cmy->{'source_values'}},    3,  'CMY has 3 axis');
is( $fuchsia_cmy->{'source_values'}[0],        0,  'cyan value is right');
is( $fuchsia_cmy->{'source_values'}[1],        1,  'magenta value is right');
is( $fuchsia_cmy->{'source_values'}[2],        0,  'yellow value is right');
is( $fuchsia_cmy->{'source_space_name'},   'CMY',  'cource space is correct');
is( $fuchsia_cmy->name,                'fuchsia',  'color has name "fuchsia"');
is( $fuchsia_cmy->{'rgb'}[0],                  1,  'violet(fuchsia) has a maximal red color');
is( $fuchsia_cmy->{'rgb'}[1],                  0,  'violet(fuchsia) has a no green color');
is( $fuchsia_cmy->{'rgb'}[2],                  1,  'violet(fuchsia) has a maximal blue color');
is( $fuchsia_cmy->formatted('RGB', 'hex_string'),  '#FF00FF',  'got color formatted into RGB hex string');
is( $fuchsia_cmy->formatted('XYZ', 'hex_string'),         '',  'HEX string is RGB only');

#### new_from_any_input ################################################
my $fuchsia_array = Graphics::Toolkit::Color::Values->new_from_any_input([255, 0, 256]);
is( ref $fuchsia_array,               $module,  'object from regular RGB tuple');
is( $fuchsia_array->{'source_values'},     '',  'object source are RGB values');
is( $fuchsia_array->{'source_space_name'}, '',  'not from any other space');
is( $fuchsia_array->name,           'fuchsia',  'color has name "fuchsia"');
is( $fuchsia_array->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $fuchsia_array->{'rgb'}[1],             0,  'violet has a no green color');
is( $fuchsia_array->{'rgb'}[2],             1,  'violet has a maximal blue color, because it was clamped');

my $blue_hsl = Graphics::Toolkit::Color::Values->new_from_any_input({hue => 240, s => 100, l => 50});
is( ref $blue_hsl,                    $module,  'value object from HSL HASH');
is( ref $blue_hsl->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$blue_hsl->{'source_values'}},    3,  'HSL has 3 axis');
is( $blue_hsl->{'source_values'}[0],      2/3,  'hue value is right');
is( $blue_hsl->{'source_values'}[1],        1,  'sat value is right');
is( $blue_hsl->{'source_values'}[2],      0.5,  'light value is right');
is( $blue_hsl->{'source_space_name'},   'HSL',  'cource space is correct');
is( $blue_hsl->name,                   'blue',  'color has name "blue"');
is( @{$blue_hsl->{'rgb'}},                  3,  'RGB tuple has three values');
is( $blue_hsl->{'rgb'}[0],                  0,  'blue has a no red vlaue');
is( $blue_hsl->{'rgb'}[1],                  0,  'blue has a no green value');
is( $blue_hsl->{'rgb'}[2],                  1,  'blue has a maximal blue value');

my $blue_hwb = Graphics::Toolkit::Color::Values->new_from_any_input('hwb( 240, 0%, 0% )');
is( ref   $blue_hwb,                    $module,  'value object from HWB named string');
is( ref   $blue_hwb->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$blue_hwb->{'source_values'}},    3,  'HSL has 3 axis');
is( $blue_hwb->{'source_values'}[0],      2/3,  'hue value is right');
is( $blue_hwb->{'source_values'}[1],        0,  'white value is right');
is( $blue_hwb->{'source_values'}[2],        0,  'black value is right');
is( $blue_hwb->{'source_space_name'},   'HWB',  'cource space is correct');
is( $blue_hwb->name,                   'blue',  'color has name "blue"');
is( @{$blue_hwb->{'rgb'}},                  3,  'RGB tuple has three values');
is( $blue_hwb->{'rgb'}[0],                  0,  'blue has a no red vlaue');
is( $blue_hwb->{'rgb'}[1],                  0,  'blue has a no green value');
is( $blue_hwb->{'rgb'}[2],                  1,  'blue has a maximal blue value');

#### name and closest name #############################################
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('ciexyz( 0, 0, 0)');
is( $black->name,                   'black',  'created black from CSS string in XYZ');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input(['hsv', 0, 0, 100 ]);
is( $white->name,                   'white',  'created white from named ARRAY in HSV');

my ($hname, $hd) = $blue_hwb->closest_name_and_distance(2);
is( $hname,                 'blue',  'closest name to "blue" is the same as name');
is( $hd,                         0,  'no distance to closest name');
my ($cname, $cd) = $fuchsia_cmy->closest_name_and_distance(2);
is( $cname,                 'fuchsia',  'closest name to "fuchsia" is same as name');
is( $cd,                            0,  'no distance to closest name');

#### normalized ########################################################
$values = $fuchsia_rgb->normalized();
is( ref $values, 'ARRAY',  'get fuchsia value tuple');
is( @$values,          3,  'has 3 values');
is( $values->[0],      1,  'red value is right');
is( $values->[1],      0,  'green value is right');
is( $values->[2],      1,  'blue value is right');
$values = $fuchsia_rgb->normalized('RGB');
is( ref $values, 'ARRAY',  'RGB is default color, get same values');
is( @$values,          3,  'same 3 values');
is( $values->[0],      1,  'red value is right');
is( $values->[1],      0,  'green value is right');
is( $values->[2],      1,  'blue value is right');
$values = $fuchsia_rgb->normalized('CMYK');
is( ref $values, 'ARRAY',  'get CMYK values');
is( @$values,          4,  'all 4 values');
is( $values->[0],      0,  'cyan value is right');
is( $values->[1],      1,  'magenta value is right');
is( $values->[2],      0,  'yellow value is right');
is( $values->[3],      0,  'key value is right');

#### in_shape ##########################################################
$values = $fuchsia_rgb->in_shape();
is( ref $values, 'ARRAY',  'get fuchsia RGB (default) values in ragular range');
is( @$values,          3,  'all 3 values');
is( $values->[0],    255,  'red value is right');
is( $values->[1],      0,  'green value is right');
is( $values->[2],    255,  'blue value is right');
$values = $fuchsia_rgb->in_shape('CMYK', [[-10,5],10, [-1,5], 20]);
is( ref $values, 'ARRAY',  'get CMYK values with custom ranges');
is( @$values,          4,  '4 values');
is( $values->[0],    -10,  'cyan value is right');
is( $values->[1],     10,  'magenta value is right');
is( $values->[2],     -1,  'yellow value is right');
is( $values->[3],      0,  'key value is right');
$values = $fuchsia_rgb->in_shape('XYZ', undef, [0, 1,2]);
is( ref $values, 'ARRAY',  'get XYZ values with custom precision');
is( @$values,          3,  '3 values');
is( $values->[0],     59,  'X value is right');
is( $values->[1],   28.5,  'Y value is right');
is( $values->[2],   96.96, 'Z value is right');

#### formatted #########################################################
#~space, @~|~format, @~|~range, @~|~suffix
is( ref $fuchsia_rgb->formatted(), '',  'formatted needs arguments');
is( $fuchsia_rgb->formatted(undef, 'named_string'), 'rgb: 255, 0, 255',       'just format name is enough');
is( $fuchsia_rgb->formatted('CMY', 'named_string'), 'cmy: 0, 1, 0',           'understand color spaces');
is( $fuchsia_rgb->formatted('CMY', 'css_string', '+'), 'cmy(0+, 1+, 0+)',     'and value suffix');
is( $fuchsia_rgb->formatted('CMY', 'css_string', '+', [[-2,10]]), 'cmy(-2+, 10+, -2+)','and ranges');
is( $fuchsia_rgb->formatted('XYZ', 'css_string', undef, undef, [2,1,0]), 'xyz(59.29, 28.5, 97)','and precision');
is( $blue_hsl->formatted('HSL', 'css_string', '', 1, [2,0,1]), 'hsl(0.67, 1, 0.5)' ,'all arguments at once');
is( ref $fuchsia_rgb->formatted('CMY', 'array'),      '',  'array format is RGB only');
is( ref $fuchsia_rgb->formatted('CMY', 'hex_string'), '',  'hex_string formatis RGB only');
is( $fuchsia_rgb->formatted('RGB', 'hex_string'), '#FF00FF', 'but works under RGB');
$values = $fuchsia_rgb->formatted('RGB', 'array');
is( ref $values,  'ARRAY',  'get fuchsia RGB values in array format');
is( @$values,           3,  'all 3 values');
is( $values->[0],     255,  'red value is right');
is( $values->[1],       0,  'green value is right');
is( $values->[2],     255,  'blue value is right');
$values = $fuchsia_rgb->formatted( undef, 'named_array');
is( ref $values,  'ARRAY',  'get fuchsia RGB values in named array format');
is( @$values,           4,  'all 4 values');
is( $values->[0],    'RGB', 'first value is space name');
is( $values->[1],     255,  'red value is right');
is( $values->[2],       0,  'green value is right');
is( $values->[3],     255,  'blue value is right');
$values = $fuchsia_rgb->formatted( 'CMYK', 'named_array',['','','-','+'], 10);
is( ref $values,  'ARRAY',  'fuchsia CMYK values as named array with custom suffix and special range');
is( @$values,           5,  'all 5 values');
is( $values->[0],  'CMYK', 'first value is space name');
is( $values->[1],       0,  'red value is right');
is( $values->[2],      10,  'magenta value is right');
is( $values->[3],    '0-',  'yellow value is right');
is( $values->[4],    '0+',  'key value is right');
@values = $fuchsia_rgb->formatted('RGB', 'list');
is( @values,            3,  'got RGB tuple in list format');
is( $values[0],       255,  'red value is right');
is( $values[1],         0,  'green value is right');
is( $values[2],       255,  'blue value is right');
$values = $fuchsia_rgb->formatted( 'CMYK', 'hash');
is( ref $values,    'HASH',  'fuchsia CMYK values as hash');
is( int keys %$values,   4,  'has 4 keys');
is( $values->{'cyan'},   0, 'cyan value is right');
is( $values->{'magenta'},1, 'magenta value is right');
is( $values->{'yellow'}, 0, 'yellow value is right');
is( $values->{'key'},    0, 'key value is right');
$values = $fuchsia_rgb->formatted( 'CMYK', 'char_hash');
is( ref $values,    'HASH',  'fuchsia CMYK values as hash with character long keys');
is( int keys %$values,   4,  'has 4 keys');
is( $values->{'c'},      0, 'cyan value is right');
is( $values->{'m'},      1, 'magenta value is right');
is( $values->{'y'},      0, 'yellow value is right');
is( $values->{'k'},      0, 'key value is right');

exit 0;
