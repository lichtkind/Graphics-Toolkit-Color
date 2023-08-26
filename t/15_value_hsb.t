#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 4;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value::HSB';

my $def = eval "require $module";
is( not($@), 1, 'could load the module');
is( ref $def, 'Graphics::Toolkit::Color::Space', 'got tight return value by loading module');
is( $def->name,       'HSB',                     'color space has right name');
is( $def->dimensions,     3,                     'color space has 3 dimensions');


exit 0;
