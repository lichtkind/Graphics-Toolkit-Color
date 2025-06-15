#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 148;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Space::Instance::CIELCHuv';


my $space = eval "require $module";

is( not($@), 1, 'could load the module');
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $space->name,       'CIELCHuv',                  'color space name is CIELCHuv');
is( $space->alias,              '',                  'color space has no alias');
is( $space->axis,                3,                  'color space has 3 dimensions');

is( ref $space->range_check([0, 0, 0]),          'ARRAY',   'check minimal CIELUV values are in bounds');
is( ref $space->range_check([0.950, 1, 1.088]),  'ARRAY',   'check maximal CIELUV values');
is( ref $space->range_check([0,0]),              '',   "CIELUV got too few values");
is( ref $space->range_check([0, 0, 0, 0]),       '',   "CIELUV got too many values");
is( ref $space->range_check([-0.1, 0, 0]),       '',   "L value is too small");
is( ref $space->range_check([100, 0, 0]),   'ARRAY',   'L value is maximal');
is( ref $space->range_check([101, 0, 0]),        '',   "L value is too big");
is( ref $space->range_check([0, -134, 0]),  'ARRAY',   'u value is minimal');
is( ref $space->range_check([0, -134.1, 0]),     '',   "u value is too small");
is( ref $space->range_check([0, 220, 0]),   'ARRAY',   'u value is maximal');
is( ref $space->range_check([0, 220.1, 0]),      '',   "u value is too big");
is( ref $space->range_check([0, 0, -140]),  'ARRAY',   'v value is minimal');
is( ref $space->range_check([0, 0, -140.1 ] ),   '',   "v value is too small");
is( ref $space->range_check([0, 0, 122]),   'ARRAY',   'v value is maximal');
is( ref $space->range_check([0, 0, 122.2] ),     '',   "v value is too big");

is( $space->is_value_tuple([0,0,0]), 1,            'tuple has 3 elements');
is( $space->is_partial_hash({u => 1, v => 0}), 1,  'found hash with some axis names');
is( $space->is_partial_hash({u => 1, v => 0, l => 0}), 1, 'found hash with all axis names');
is( $space->is_partial_hash({'L*' => 1, 'u*' => 0, 'v*' => 0}), 1, 'found hash with all long axis names');
is( $space->is_partial_hash({a => 1, v => 0, l => 0}), 0, 'found hash with one wrong axis name');
is( $space->can_convert('CIEXYZ'), 1,                 'do only convert from and to rgb');
is( $space->can_convert('ciexyz'), 1,                 'namespace can be written lower case');
is( $space->can_convert('CIEluv'), 0,                 'can not convert to itself');
is( $space->can_convert('luv'), 0,                    'can not convert to itself (alias)');
is( $space->format([0,0,0], 'css_string'), 'cieluv(0, 0, 0)', 'can format css string');


exit 0;
