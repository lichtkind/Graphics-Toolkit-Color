#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 170;
BEGIN { unshift @INC, 'lib', '../lib'}

my $module = 'Graphics::Toolkit::Color::Space::Hub';
my $space_ref = 'Graphics::Toolkit::Color::Space';
use_ok( $module, 'could load the module');

my $convert       = \&Graphics::Toolkit::Color::Space::Hub::convert;
my $deconvert     = \&Graphics::Toolkit::Color::Space::Hub::deconvert;
my $deformat      = \&Graphics::Toolkit::Color::Space::Hub::deformat;
my $dehash        = \&Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash;
my $distance      = \&Graphics::Toolkit::Color::Space::Hub::distance;


is( ref Graphics::Toolkit::Color::Space::Hub::get_space('RGB'),  $space_ref, 'RGB is a color space');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($_),   1, "found $_ color space")
    for qw /RGB CMY CMYK HSL HSv HSB HWB NCol YIQ YUV CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/;
my @names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  20, 'intalled 20 space names');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($_),      1, "$_ is a space name") for @names;


my $Tspace = Graphics::Toolkit::Color::Space->new( axis => [qw/one two three/], range => 10 );
   $Tspace->add_converter(          'RGB', \&p, \&p );
   sub p { @{$_[0]} }

my $ret = Graphics::Toolkit::Color::Space::Hub::add_space( $Tspace );
is( $ret, 1, "could add test color space");
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          1, 'test space was installed');
is( Graphics::Toolkit::Color::Space::Hub::get_space('OTT'),   $Tspace, 'got access to test space');
@names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  21, 'intalled 21st space name');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('TTT'), '', 'try to delete unknown space');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('OTT'), $space_ref, 'removed test space');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          0, 'test space is gone');
is( Graphics::Toolkit::Color::Space::Hub::get_space('OTT'),        '', 'no access to test space');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('OTT'), '', 'test space was already removed');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          0, 'test space is still gone');
@names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  20, 'intalled again only 20 space names');

my $rgb_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($rgb_name),             1, 'default space name is valid');
is( ref Graphics::Toolkit::Color::Space::Hub::get_space($rgb_name),    $space_ref, 'can get default space');
is( ref Graphics::Toolkit::Color::Space::Hub::default_space(),    $space_ref, 'default space is a space');
my %sn = map {$_ => 1} @names;
is( $sn{$rgb_name},  1  , 'default space is among color spaces');

is( ref $convert->(),                       '', 'convert needs at least one argument');
is( ref $convert->({r => 1,g => 1,b => 1}), '', 'convert tule as ARRAY');
is( ref $convert->([0,0,0]),                '', 'convert also needs target name space');
is( ref $convert->([0,0,0], 'YO'),          '', 'convert needs a valid target name space');

my $tuple = $convert->([0,1/255,1], 'RGB');
is( ref $tuple,      'ARRAY', 'did minimal none conversion');
is( int @$tuple,           3, 'RGB has 3 axis');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],           1, 'green value is right');
is( $tuple->[2],         255, 'blue value is right');

$tuple = $convert->([0,1/255,1], 'RGB', 'normal');
is( int @$tuple,           3, 'wanted  normalized result');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],       1/255, 'green value is right');
is( $tuple->[2],           1, 'blue value is right');

$tuple = $convert->([.1, .2, .3], 'YUV', 1, 'YUV', [1, .1, 0]);
is( int @$tuple,           3, 'take source values instead of convert RGB');
is( $tuple->[0],           1, 'Red value is right');
is( $tuple->[1],          .1, 'green value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $convert->([.1, .2, .3], 'YUV', undef, 'YUV', [1, 0.1, 0]);
is( int @$tuple,           3, 'get normalized source values');
is( $tuple->[0],           1, 'Red value is right');
is( $tuple->[1],         -.4, 'green value is right');
is( $tuple->[2],         -.5, 'blue value is right');

$tuple = $convert->([0, 0.1, 1], 'CMY');
is( int @$tuple,           3, 'invert values');
is( $tuple->[0],           1, 'cyan value is right');
is( $tuple->[1],         0.9, 'magenta value is right');
is( $tuple->[2],           0, 'yellow value is right');



exit 0;
__END__

deconvert deformat deformat_partial_hash distance
