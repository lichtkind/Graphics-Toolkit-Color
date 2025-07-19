#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 72;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Instance::NCol';

my $space = eval "require $module";
use Graphics::Toolkit::Color::Space::Util ':all';

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,         'NCol',                  'color space has use set name');
is( $space->alias,            '',                  'color space has no alias name');

is( $space->axis,              3,                  'color space has 3 axis');
is( $space->is_value_tuple([0,0,0]), 1,            'value tuple has 3 elements');
is( $space->is_partial_hash({whiteness => 1, blackness => 0}), 1, 'found hash with some axis name');
is( $space->is_partial_hash({what => 1, blackness => 0}), 0, 'found hash with a bad axis name');
is( $space->can_convert('rgb'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('ncol'), 0,                'can not convert to itself');

is( ref $space->check_range([0, 0, 0]),     'ARRAY',   'check HWB values works on lower bound values');
is( ref $space->check_range([600,100,100]), 'ARRAY',   'check HWB values works on upper bound values');
is( ref $space->check_range([0,0]),              '',   "HWB got too few values");
is( ref $space->check_range([0, 0, 0, 0]),       '',   "HWB got too many values");
is( ref $space->check_range([-1, 0, 0]),         '',   "hue value is too small");
is( ref $space->check_range([1.1, 0, 0]),        '',   "hue is not integer");
is( ref $space->check_range([601, 0, 0]),        '',   "hue value is too big");
is( ref $space->check_range([0, -1, 0]),         '',   "whiteness value is too small");
is( ref $space->check_range([0, 1.1, 0]),        '',   "whiteness value is not integer");
is( ref $space->check_range([0, 101, 0]),        '',   "whiteness value is too big");
is( ref $space->check_range([0, 0, -1 ] ),       '',   "blackness value is too small");
is( ref $space->check_range([0, 0, 1.1] ),       '',   "blackness value is not integer");
is( ref $space->check_range([0, 0, 101] ),       '',   "blackness value is too big");


is( $space->format([0,0,0], 'css_string'), 'ncol(R00, 0%, 0%)', 'can format css string');
is( $space->format([212,34,56], 'css_string'), 'ncol(G12, 34%, 56%)', 'can format css string');

my $val = $space->deformat('ncol(R00, 0%, 0%)');
is( ref $val, 'ARRAY', 'deformated CSS string into tuple (ARRAY)');
is( int @$val, 3,      'deformated value triplet (tuple)');
is( $val->[0], 0,      'first value good');
is( $val->[1], 0,      'second value good');
is( $val->[2], 0,      'third value good');
$val = $space->deformat('ncol(R0, 0%, 0%)');
is( int @$val, 3,      'one digit color values work too');
$val = $space->deformat('ncol(G12, 34%, 56%)');
is( ref $val, 'ARRAY', 'deformated CSS string into tuple (ARRAY)');
is( int @$val, 3,      'deformated value triplet (tuple)');
is( $val->[0], 212,    'first value good');
is( $val->[1], 34,     'second value good');
is( $val->[2], 56,     'third value good');
$val = $space->deformat('ncol(G12, 34%, 56.1%)');
is( ref $val, '', 'can not deformat with CSS string with ill formatted values');
$val = $space->deformat(['NCol', 'B20', '31%', '15']);
is( ref $val, 'ARRAY', 'deformated named ARRAY into tuple (ARRAY)');
is( int @$val, 3,      'deformated into value triplet (tuple)');
is( $val->[0], 420,    'first value good');
is( $val->[1], 31,     'second value good');
is( $val->[2], 15,     'third value good');

$val = $space->clamp([700,1.1,-2]);
is( ref $val,                'ARRAY', 'clampd value tuple into tuple');
is( int @$val,                     3, 'right amount of values');
is( $val->[0],                   100, 'first value rotated in');
is( $val->[1],                   1.1, 'second value rounded');
is( $val->[2],                     0, 'third value clamped up');

$val = $space->round([1,22.5, 11.111111]);
is( ref $val,                'ARRAY', 'rounded value tuple into tuple');
is( int @$val,                     3, 'right amount of values');
is( $val->[0],                     1, 'first value kept');
is( $val->[1],                    23, 'second value rounded up');
is( $val->[2],                    11, 'third value rounded down');

my $hwb = $space->convert_from( 'RGB', [ .5, .5, .5]);
is( int @$hwb,   3,     'converted color grey has three hwb values');
is( $hwb->[0],   0,     'converted color grey has computed right hue value');
is( $hwb->[1],  .5,     'converted color grey has computed right whiteness');
is( $hwb->[2],  .5,     'converted color grey has computed right blackness');

my $rgb = $space->convert_to( 'RGB', [0, 0.5, .5]);
is( int @$rgb,     3,   'converted back color grey has three rgb values');
is( $rgb->[0],   0.5,   'converted back color grey has right red value');
is( $rgb->[1],   0.5,   'converted back color grey has right green value');
is( $rgb->[2],   0.5,   'converted back color grey has right blue value');

$hwb = $space->convert_from( 'RGB', [210/255, 20/255, 70/255]);
is( int @$hwb,                          3,     'converted nice magents has three hwb values');
is( close_enough( $hwb->[0], 0.95555),  1,  'converted nice magenta has computed right hue value');
is( close_enough( $hwb->[1], 0.08,   ), 1,  'converted nice magenta has computed right whiteness');
is( close_enough( $hwb->[2], 0.18,   ), 1,  'converted nice magenta has computed right blackness');

$rgb = $space->convert_to( 'RGB', [0.95555, 0.08, 0.18]);
is( int @$rgb,                         3,   'converted back nice magenta');
is( close_enough( $rgb->[0], 210/255), 1,   'right red value');
is( close_enough( $rgb->[1], 20/255) , 1,   'right green value');
is( close_enough( $rgb->[2], 70/255) , 1,   'right blue value');

$rgb = $space->convert_to( 'RGB', [0.83333, 0, 1]); # should become black despite color value
is( int @$rgb,   3,    'converted black');
is( $rgb->[0],   0,    'right red value');
is( $rgb->[1],   0,    'right green value');
is( $rgb->[2],   0,    'right blue value');


exit 0;

__END__

