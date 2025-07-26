#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 80;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Values';
use_ok( $module, 'could load the module');

is( ref Graphics::Toolkit::Color::Values->new_from_normal_tuple(),  '',  'new need at least one argument');
my $norm_rgb = Graphics::Toolkit::Color::Values->new_from_normal_tuple([1,0,1]);
is( ref $norm_rgb,               $module,  'created values object from normalized RGB values');
is( $norm_rgb->{'source_values'},     '',  'object source are RGB values');
is( $norm_rgb->{'source_space_name'}, '',  'not from any other space');
is( $norm_rgb->name,           'fuchsia',  'color has name "fuchsia"');
is( ref $norm_rgb->{'rgb'},      'ARRAY',  'RGB tuple is an ARRAY');
is( @{$norm_rgb->{'rgb'}},             3,  'RGB tuple has three values');
is( $norm_rgb->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $norm_rgb->{'rgb'}[1],             0,  'violet has a no green color');
is( $norm_rgb->{'rgb'}[2],             1,  'violet has a maximal blue color');
my $values = $norm_rgb->normalized();
is( ref $values,                 'ARRAY',  'normalized value tuple is an ARRAY');
is( @$values,                          3,  'and has three values');
is( $values->[0],                      1,  'red value is as expected');
is( $values->[1],                      0,  'green value is as expected');
is( $values->[2],                      1,  'blue value is as expected');
is( $norm_rgb->formatted('', 'named_string'),  'rgb: 255, 0, 255',  'got color formatted into named string');

my $norm_cmy = Graphics::Toolkit::Color::Values->new_from_normal_tuple([0,1,0], 'CMY');
is( ref $norm_cmy,                  $module,  'value object from CMY values');
is( ref $norm_cmy->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$norm_cmy->{'source_values'}},    3,  'CMY has 3 axis');
is( $norm_cmy->{'source_values'}[0],        0,  'cyan calue is right');
is( $norm_cmy->{'source_values'}[1],        1,  'magenta value is right');
is( $norm_cmy->{'source_values'}[2],        0,  'yellow value is right');
is( $norm_cmy->{'source_space_name'},   'CMY',  'cource space is correct');
is( $norm_cmy->name,                'fuchsia',  'color has name "fuchsia"');
is( $norm_cmy->{'rgb'}[0],                  1,  'violet(fuchsia) has a maximal red color');
is( $norm_cmy->{'rgb'}[1],                  0,  'violet(fuchsia) has a no green color');
is( $norm_cmy->{'rgb'}[2],                  1,  'violet(fuchsia) has a maximal blue color');

my $rgb_values = Graphics::Toolkit::Color::Values->new_from_any_input([255, 0, 256]);
is( ref $rgb_values,               $module,  'object from regular RGB tuple');
is( $rgb_values->{'source_values'},     '',  'object source are RGB values');
is( $rgb_values->{'source_space_name'}, '',  'not from any other space');
is( $rgb_values->name,           'fuchsia',  'color has name "fuchsia"');
is( $rgb_values->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $rgb_values->{'rgb'}[1],             0,  'violet has a no green color');
is( $rgb_values->{'rgb'}[2],             1,  'violet has a maximal blue color, because it was clamped');

my $hsl_blue = Graphics::Toolkit::Color::Values->new_from_any_input({hue => 240, s => 100, l => 50});
is( ref $hsl_blue,                    $module,  'value object from HSL HASH');
is( ref $hsl_blue->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$hsl_blue->{'source_values'}},    3,  'HSL has 3 axis');
is( $hsl_blue->{'source_values'}[0],      2/3,  'hue calue is right');
is( $hsl_blue->{'source_values'}[1],        1,  'sat value is right');
is( $hsl_blue->{'source_values'}[2],      0.5,  'light value is right');
is( $hsl_blue->{'source_space_name'},   'HSL',  'cource space is correct');
is( $hsl_blue->name,                   'blue',  'color has name "blue"');
is( $hsl_blue->{'rgb'}[0],                  0,  'blue has a no red vlaue');
is( $hsl_blue->{'rgb'}[1],                  0,  'blue has a no green value');
is( $hsl_blue->{'rgb'}[2],                  1,  'blue has a maximal blue value');

my $hwb_blue = Graphics::Toolkit::Color::Values->new_from_any_input('hwb( 240, 0%, 0% )');
is( ref   $hwb_blue,                    $module,  'value object from HWB named string');
is( ref   $hwb_blue->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$hwb_blue->{'source_values'}},    3,  'HSL has 3 axis');
is( $hwb_blue->{'source_values'}[0],      2/3,  'hue calue is right');
is( $hwb_blue->{'source_values'}[1],        0,  'white value is right');
is( $hwb_blue->{'source_values'}[2],        0,  'black value is right');
is( $hwb_blue->{'source_space_name'},   'HWB',  'cource space is correct');
is( $hwb_blue->name,                   'blue',  'color has name "blue"');
is( $hwb_blue->{'rgb'}[0],                  0,  'blue has a no red vlaue');
is( $hwb_blue->{'rgb'}[1],                  0,  'blue has a no green value');
is( $hwb_blue->{'rgb'}[2],                  1,  'blue has a maximal blue value');

my ($hname, $hd) = $hwb_blue->closest_name(2);
is( $hname,                 'blue',  'closest name to "blue" is the same as name');
is( $hd,                         0,  'no distance to closest name');
my ($cname, $cd) = $norm_cmy->closest_name(2);
is( $cname,                 'fuchsia',  'closest name to "fuchsia" is same as name');
is( $cd,                            0,  'no distance to closest name');


exit 0;


__END__

get_normal_tuple
get_custom_form { # get a value tuple in any color space, range and format
set { # %val --> _
add { # %val --> _
mix { #  @%(+percent _values)  -- ~space_name --> _values
distance { # _c1 _c2 -- ~space ~select @range --> +

