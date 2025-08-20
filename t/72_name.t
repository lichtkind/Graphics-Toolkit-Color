#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 70;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Name';
use_ok( $module, 'could load the module');

my $get_values          = \&Graphics::Toolkit::Color::Name::get_values;
my $from_values         = \&Graphics::Toolkit::Color::Name::from_values;
my $closest_from_values = \&Graphics::Toolkit::Color::Name::closest_from_values;
my $all                 = \&Graphics::Toolkit::Color::Name::all;
my $try_get_scheme      = \&Graphics::Toolkit::Color::Name::try_get_scheme;
my $add_scheme          = \&Graphics::Toolkit::Color::Name::add_scheme;
my $scheme_ref          = 'Graphics::Toolkit::Color::Name::Scheme';
my $default_scheme      = $try_get_scheme->('default');
my (@names, $names, $scheme, $values);

is( ref $try_get_scheme->(),          $scheme_ref, 'get default scheme when leaving out argument');
is( ref $default_scheme,              $scheme_ref, 'get default scheme when requesting it');
is( $default_scheme,          $try_get_scheme->(), 'both are the same');
is( $default_scheme->is_name_taken('red'),      1, '"red" is a known constant' );
is( $default_scheme->is_name_taken('RED'),      1, 'color constants are case insensitive' );
is( $default_scheme->is_name_taken("r_e'd"),    1, 'some special characters are also ignored' );
is( $default_scheme->is_name_taken('blue'),     1, '"blue" is a known constant' );
is( $default_scheme->is_name_taken('coconut'),  0, '"coconut" is not a known constant' );

@names = Graphics::Toolkit::Color::Name::all();
is( int @names,               716,       'all default consants are there' );
#$values = Graphics::Toolkit::Color::Name::get_values('SVG:red');
$values = Graphics::Toolkit::Color::Name::get_values('red');
is( ref $values,         'ARRAY',       'got value tuple of color red' );
is( int @$values,              3,       'it has three values' );
is( $values->[0],            255,       'red value is correct' );
is( $values->[1],              0,       'green value is correct' );
is( $values->[2],              0,       'blue value is correct' );

@names = Graphics::Toolkit::Color::Name::from_values([255,0,0]);
is( int @names,                1,       'no second arg, get only one name "from_values"');
is( $names[0],             'red',       'and its name is "red"');
@names = Graphics::Toolkit::Color::Name::from_values([255,0,0], undef, 'all');
is( int @names,                2,       'all names were requested "from_values"' );
is( $names[0],             'red',       'it is also "red" on first position' );
is( $names[1],            'red1',       'it is "red1" on second position' );
@names = Graphics::Toolkit::Color::Name::closest_from_values([255,0,0] );
is( int @names,                2,       'got names and distance from "closest_from_values"');
is( $names[0],             'red',       'and its name is "red"' );
is( $names[1],                 0,       'has no distance' );
@names = Graphics::Toolkit::Color::Name::closest_from_values([255,0,0], undef, 'all' );
is( int @names,                2,       'got all names and distance from "closest_from_values"');
is( ref $names[0],       'ARRAY',       'names ARRAY on first position');
is( @{$names[0]},              2,       'it two names');
is( $names[0][0],          'red',       'first is "red"');
is( $names[0][1],         'red1',       'second is is "red1"');
is( $names[1],                 0,       'has no distance');
@names = Graphics::Toolkit::Color::Name::closest_from_values([255,1,0] );
is( int @names,                2,       'this time there is a distance to red');
is( $names[0],             'red',       'and its name is "red"' );
is( $names[1],                 1,       'has distance of one' );


1;
__END__

my $values = Graphics::Toolkit::Color::Name::rgb_from_name('red');
is( ref $values,      'ARRAY',       'got tuple with RGB values of "red"' );
$values = Graphics::Toolkit::Color::Name::rgb_from_name('coconut');
is( ref $values,           '',       'got no tuple for unknown color constant' );

$values = Graphics::Toolkit::Color::Name::hsl_from_name('red');
is( ref $values,      'ARRAY',       'got tuple with HSL values of "red"' );
is( int @$values,           3,       'tuple contains three values' );
is( $values->[0],           0,       'hue value is correct' );
is( $values->[1],         100,       'saturation value is correct' );
is( $values->[2],          50,       'lightness value is correct' );
$values = Graphics::Toolkit::Color::Name::hsl_from_name('coconut');
is( ref $values,           '',       'got no tuple for unknown color constant' );

is( $name_from_rgb->([255,0,0]),             'red',       'found red constant by RGB values' );
my $color_name = $name_from_rgb->([0,0,255]);
is( $color_name,                            'blue',       'found blue constant by RGB values in scalar context' );
my @color_name = $name_from_rgb->([0,0,255]);
is( int @color_name,                             2,       'in ARRAY context you get two blue names in RGB' );
is( $color_name[0],                         'blue',       'first one is "blue"' );
is( $color_name[1],                        'blue1',       'second one is "blue1"' );
is( $name_from_rgb->([1,1,255]),                '',       'no color with values 1, 1, 255' );
is( length $add_rgb->('blue', [1, 0, 255]),     61,       'name blue is already in store' );
is( $add_rgb->('blue_top',  [0, 0, 255]),        0,       'added third name for blue on top' );
@color_name = $name_from_rgb->([0,0,255]);
is( int @color_name,                             3,       'in ARRAY context you get several blue names' );
is( $color_name[2],                      'bluetop',       'new blue name is last in list' );
is( $add_rgb->('bluuu',  [1, 1, 255]),           0,       'could add my custom blue' );
is( $name_from_rgb->([1,1,255]),           'bluuu',       'can retrieve newly stored constant' );
is( $name_from_hsl->([0,100,50]),            'red',       'found red constant by HSL values' );
is( $name_from_hsl->([240,100,50]),         'blue',       'found blue constant by HSL values' );
$color_name = $name_from_hsl->([240,100,50]);
is( $color_name,                            'blue',       'found blue constant by HSL values in scalar context' );
@color_name = $name_from_hsl->([240,100,50]);
is( int @color_name,                             4,       'in ARRAY context you get 4 blue names now in HSL' );
is( $color_name[0],                         'blue',       'first one is "blue"' );
is( $color_name[1],                        'blue1',       'second one is "blue1"' );
is( $color_name[2],                      'bluetop',       'third one is "bluetop"' );
is( $color_name[3],                        'bluuu',       'fourth one is "bluuu"' );
is( $name_from_hsl->([241,100,50]),             '',       'custom blue is not in store yet' );
is( ref $add_hsl->('blue', [240,100,50]),       '',       'name blue is already in store, also under HSL' );
is( $add_hsl->('blauu',  [241,100,50]),          0,       'could add my custom blue' );
is( $name_from_hsl->([241,100,50]),        'blauu',       'can retrieve newly stored blue as HSL constant' );

my ($names, $d) = $names_in_hsl_range->([240,100,50], 3);
@color_name = sort @$names[0..3];
is( ref $names,         'ARRAY',       'got near color names in an ARRAY' );
is( ref $d,             'ARRAY',       'got near color distances in an ARRAY' );
is( int @$names,              6,       'its six colors' );
is( int @$d,                  6,       'has to be also six distances' );
is( $names->[5],        'blue2',       'far away is "blue2"' );
is( $d->[5],                  3,       '"blue2" has the greatest distance' );
is( $names->[4],        'blauu',       'closer is "blauu"' );
is( $d->[4],                  1,       '"blauu" has very little distance' );
is( $color_name[0],      'blue',       '"blue" is the wanted color' );
is( $d->[0],                  0,       '"blue" has no distance' );
is( $color_name[1],     'blue1',       '"blue1" is the wanted color' );
is( $d->[1],                  0,       '"blue1" has no distance' );
is( $color_name[2],   'bluetop',       '"bluetop" is the wanted color' );
is( $d->[2],                  0,       '"bluetop" has no distance' );
is( $color_name[3],     'bluuu',       '"bluuu" is the wanted color' );
is( $d->[3],                  0,       '"bluuu" has no distance' );

exit 0;
