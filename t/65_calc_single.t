#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 50;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color::Values;


my $module = 'Graphics::Toolkit::Color::Values';
my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');
########################################################################
my $aqua = $blue->set( {green => 255} );
is( ref $aqua,                   $module,  'aqua (set green value to max) value object');
is( $aqua->name,                  'aqua',  'color has the name "aqua"');
my $values = $aqua->normalized();
is( ref $values,                 'ARRAY',  'RGB value ARRAY');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');
is( ref $blue->set( {green => 256}, 'CMY' ),  '',  'green is in RGB, not CMY');
is( ref $blue->set( {green => 256, yellow => 0},  ),  '',  'green and yellow axis are from different spaces');
$aqua = $blue->set( {green => 256}, 'RGB' );
$values = $aqua->normalized();
is( ref $aqua,                   $module,  'green is in RGB, and set green over max, got clamped');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');

########################################################################
$aqua = $blue->add( {green => 255} );
is( ref $aqua,                   $module,  'aqua (add green value to max) value object');
is( $aqua->name,                  'aqua',  'color has the name "aqua"');
$values = $aqua->normalized();
is( ref $values,                 'ARRAY',  'RGB value ARRAY');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');
is( ref $blue->add( {green => 256}, 'CMY' ),  '',  'green is in RGB, not CMY');
is( ref $blue->add( {green => 256, yellow => 0},  ),  '',  'green and yellow axis are from different spaces');
$aqua = $blue->add( {green => 256}, 'RGB' );
$values = $aqua->normalized();
is( ref $aqua,                   $module,  'green is in RGB, and set green over max, got clamped');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');

########################################################################
my $grey = $white->mix([{color => $black, percent => 50}]);
is( ref $grey,                   $module,  'created gray by mixing black and white');
$values = $grey->in_shape();
is( @$values,                          3,  'get RGB values of grey');
is( $values->[0],                    128,  'red value of gray');
is( $values->[1],                    128,  'green value of gray');
is( $values->[2],                    128,  'blue value of gray');
is( $grey->name(),                'gray',  'created gray by mixing black and white');

my $lgrey = $white->mix([{color => $black, percent => 5}]);
is( ref $lgrey,                   $module,  'created light gray');
$values = $lgrey->in_shape();
is( @$values,                          3,  'get RGB values of grey');
is( $values->[0],                    242,  'red value of gray');
is( $values->[1],                    242,  'green value of gray');
is( $values->[2],                    242,  'blue value of gray');
is( $lgrey->name(),             'gray95',  'created gray by mixing black and white');

my $darkblue = $white->mix([{color => $blue, percent => 60},{color => $black, percent => 60},], 'HSL');
is( ref $darkblue,               $module,  'mixed black and blue in HSL, recalculated percentages from sum of 120%');
$values = $darkblue->in_shape('HSL');
is( @$values,                          3,  'get 3 HSL values');
is( $values->[0],                    120,  'hue value is right');
is( $values->[1],                     50,  'sat value is right');
is( $values->[2],                     25,  'light value is right');

########################################################################
is( $white->invert->name,             'black',  'black is white inverted');
is( $black->invert->name,             'white',  'white is black inverted');
is( $blue->invert->name,             'yellow',  'yellow is blue inverted');



exit 0;

__END__
########################################################################
is( $distance->( ) =~ /value/,                  1, 'missing arguments');
is( $distance->([0,0,0] ) =~ /value/,           1, 'need two tuples');
is( $distance->([0,0], [0,0,0]) =~ /value/,     1, 'first tuple is too short');
is( $distance->([0,0,0,0], [0,0,0])=~ /value/,  1, 'first tuple is too long');
is( $distance->([0,0,0], [0,0]) =~ /value/,     1, 'second tuple is too short');
is( $distance->([0,0,0], [0,0,0,0]) =~ /value/, 1, 'second tuple is too long');
is( $distance->([0,0,0], [0,0,0], ),       0, 'no distance');
is( $distance->([1,0,0], [0,0,0], ),     255, 'full red distance');
my $d = $distance->( [1,0,1], [0,0,0],  undef, undef, 'normal' );
is( round_decimals( $d, 5), round_decimals( sqrt(2), 5), 'full red and blue distance, normalized');
$d = $distance->( [1,0,0], [0,0,0],  'CMYK'  );
is(  $d, sqrt(3),              'distance in 4D space');
$d = $distance->( [1,0,0], [0,0,0],  undef, [qw/red red/], 1  );
is(  $d, sqrt(2),              'count red difference twice');
$d = $distance->( [1,1,1], [0,0,0],  undef, [qw/blue/], 1  );
is(  $d,       1,              'count only blue difference');
