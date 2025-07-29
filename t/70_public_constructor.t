#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 130;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color';
eval "use $module qw/color/";
is( not( $@), 1, 'could load the module');

is( ref Graphics::Toolkit::Color->new(),        '', 'constructor need arguments');
is( ref Graphics::Toolkit::Color->new('red'), $module, 'constructor accepts color name');
is( ref Graphics::Toolkit::Color->new( 'red', 'green'), '', 'constructor needs only one color name');
is( ref Graphics::Toolkit::Color->new('SVG::red'), $module, 'constructor accepts color name from a scheme');
is( ref Graphics::Toolkit::Color->new('SVG::red'), $module, 'constructor accepts color name from a scheme');
is( ref Graphics::Toolkit::Color->new('#ABC'),     $module, 'short hex string');
is( ref Graphics::Toolkit::Color->new('#AABBCC'),  $module, 'long hex string');
is( ref Graphics::Toolkit::Color->new('#AABBGG'),       '', 'long hex string has typo');
is( ref Graphics::Toolkit::Color->new('#AABBF'),        '', 'long hex string is too short');
is( ref Graphics::Toolkit::Color->new('rgb(0, 0, 0)'),          $module, 'CSS string format');
is( ref Graphics::Toolkit::Color->new('lab( 12.3, 5.4, 1.2)'),  $module, 'CSS string in LAB space');
is( ref Graphics::Toolkit::Color->new('lab( 12.3, 5.4, 1.2%)'),      '', 'CSS string with bad suffix');
is( ref Graphics::Toolkit::Color->new('YIQ:5.22,   0, -10  '), $module, 'named string in YIQ space and additional spacing');
is( ref Graphics::Toolkit::Color->new( 4),      '', 'constructor needs more than one number');
is( ref Graphics::Toolkit::Color->new( 4,5),    '', 'constructor needs more than two numbers');
is( ref Graphics::Toolkit::Color->new( 4,5,6,7), '', 'constructor needs less than four numbers');
is( ref Graphics::Toolkit::Color->new( 1,2,3), $module, 'constructor got three RGB numbers');
is( ref Graphics::Toolkit::Color->new( 1,2,'e4'), '', 'all three RGB values have to be numbers');
is( ref Graphics::Toolkit::Color->new( [4,5]),    '', 'constructor needs more than two numbers in an ARRAY');
is( ref Graphics::Toolkit::Color->new( [4,5,6,7]), '', 'constructor needs less than four numbers in an ARRAY');
is( ref Graphics::Toolkit::Color->new( [1,2,3]), $module, 'constructor got three RGB numbers in an ARRAY');
is( ref Graphics::Toolkit::Color->new( ['YUV',1,2,3]), $module, 'named ARRAY in YUV space');
is( ref Graphics::Toolkit::Color->new( ['YUV',1,2]),        '', 'named ARRAY in YUV space got not enough values');
is( ref Graphics::Toolkit::Color->new( ['YUV',1,2,3,4]),    '', 'named ARRAY in YUV space got too many values');
is( ref Graphics::Toolkit::Color->new( ['cmyk',1,0,0,0]), $module, 'named ARRAY in CMYK space');
is( ref Graphics::Toolkit::Color->new( ['cmyk',1,0,0]),        '', 'CMYK ARRAY got not enough values');
is( ref Graphics::Toolkit::Color->new( ['cmyk',1,0,0,0,0]),    '', 'CMYK ARRAY got too much values');

exit 0;

__END__

