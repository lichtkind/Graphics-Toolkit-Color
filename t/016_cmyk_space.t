#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 37;

my $module = 'Graphics::Toolkit::Color::Space::Instance::CMYK';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,                  'CMYK',         'color space has right name');
is( $space->name('alias'),             '',         'CMYK has no alias name');
is( $space->is_name('CMYK'),            1,         'asked for right space name');
is( $space->is_name('CMY'),             0,         'CMY is not CMYK');
is( $space->is_axis_name('CMYK'),       0,         'space name is not axis name');
is( $space->is_axis_name('Cyan'),       1,         'cyan is an axis name');
is( $space->is_axis_name('magenta'),    1,         'magenta is an axis name');
is( $space->is_axis_name('yellow'),     1,         'yellow is an axis name');
is( $space->is_axis_name('key'),        1,         'key is an axis name');
is( $space->is_axis_name('ey'),         0,         'can not miss  lettter of axis name');
is( $space->axis_count,                 4,         'CMYK has 4 axis');
is( $space->is_euclidean,               1,         'CMYK is euclidean');
is( $space->is_cylindrical,             0,         'CMYK is not cylindrical');

is( ref $space->check_value_shape( [0,0,0, 0]),    'ARRAY',   'check CMYK values works on lower bound values');
is( ref $space->check_value_shape( [1, 1, 1, 1]),  'ARRAY',   'check CMYK values works on upper bound values');
is( ref $space->check_value_shape( [0,0,0]),            '',   "CMYK got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0, 0]),    '',   "CMYK got too many values");

is( ref $space->check_value_shape( [-1, 0, 0, 0]),      '',   "cyan value is too small");
is( ref $space->check_value_shape( [2, 0, 0, 0]),       '',   "cyan value is too big");
is( ref $space->check_value_shape( [0, -1, 0, 0]),      '',   "magenta value is too small");
is( ref $space->check_value_shape( [0, 2, 0, 0]),       '',   "magenta value is too big");
is( ref $space->check_value_shape( [0, 0, -1, 0 ] ),    '',   "yellow value is too small");
is( ref $space->check_value_shape( [0, 0, 2, 0] ),      '',   "yellow value is too big");
is( ref $space->check_value_shape( [0, 0, 0, -1] ),     '',   "key value is too small");
is( ref $space->check_value_shape( [0, 0, 0, 2] ),      '',   "key value is too big");

my $cmyk = $space->clamp([]);
is_tuple( $cmyk, [0, 0, 0, 0], [qw/cyan magenta yellow key/], 'clamped empty tuple into default color (white)');

$cmyk = $space->clamp([0.1, 0.2, 0.3]);
is_tuple( $cmyk, [0.1, 0.2, 0.3, 0], [qw/cyan magenta yellow key/], 'clamp inserted zero for missing value');

$cmyk = $space->clamp([-0.1, 1.2, 0.3, 0.4, 0.5]);
is_tuple( $cmyk, [0, 1, 0.3, .4], [qw/cyan magenta yellow key/], 'clamp changes values to min, max and removes superfluous values');

$cmyk = $space->convert_from( 'RGB', [0.5, 0.5, 0.5]);
is_tuple( $cmyk, [0, 0, 0, .5], [qw/cyan magenta yellow key/], 'convert grey from RGB');

my $rgb = $space->convert_to( 'RGB', [0, 0, 0, 0.5]);
is_tuple( $rgb, [.5, .5, .5], [qw/red green blue/], 'convert grey back to RGB');

$cmyk = $space->convert_from( 'RGB', [0.3, 0.4, 0.5]);
is_tuple( $cmyk, [.4, .2, 0, .5], [qw/cyan magenta yellow key/], 'convert bluish grey from RGB');

$rgb = $space->convert_to( 'RGB', [0.4, 0.2, 0, 0.5]);
is_tuple( $rgb, [.3, .4, .5], [qw/red green blue/], 'convert bluish grey back to RGB');

$cmyk = $space->deformat([cmyk => 11, 22, 256, -1]);
is_tuple( $cmyk, [11, 22, 256, -1], [qw/cyan magenta yellow key/], 'deformat named_array, no clamping');

$cmyk = $space->deformat(['CMYK', 11, 22, 33]);
is( $cmyk,  undef,  'OO deformat reacts only to right amount of values');

$cmyk = $space->deformat('cmyk: -1, 256, 3.3, 4 ');
is_tuple( $cmyk, [-1, 256, 3.3, 4], [qw/cyan magenta yellow key/], 'deformat named_string, no clamping');

exit 0;
