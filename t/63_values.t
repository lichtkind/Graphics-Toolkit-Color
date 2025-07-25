#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 80;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Values';
use_ok( $module, 'could load the module');

is( ref Graphics::Toolkit::Color::Values->new_from_normal_tuple(),  '',  'new need at least one argument');
my $val_obj = Graphics::Toolkit::Color::Values->new_from_normal_tuple([1,0,1]);
is( ref $val_obj,             $module,  'created values object with minimal effort');
is( $val_obj->{'source_values'},     '',  'object source are RGB values');
is( $val_obj->{'source_space_name'}, '',  'not from any other space');
is( $val_obj->name,           'fuchsia',  'color has name "fuchsia"');
is( $val_obj->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $val_obj->{'rgb'}[1],             0,  'violet has a no green color');
is( $val_obj->{'rgb'}[2],             1,  'violet has a maximal blue color');

my $cval_obj = Graphics::Toolkit::Color::Values->new_from_normal_tuple([0,1,0], 'CMY');
is( ref $cval_obj,                  $module,  'value object from CMY values');
is( ref $cval_obj->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$cval_obj->{'source_values'}},    3,  'CMY has 3 axis');
is( $cval_obj->{'source_values'}[0],        0,  'cyan calue is right');
is( $cval_obj->{'source_values'}[1],        1,  'magenta value is right');
is( $cval_obj->{'source_values'}[2],        0,  'yellow value is right');
is( $cval_obj->{'source_space_name'},   'CMY',  'cource space is correct');
is( $cval_obj->name,                'fuchsia',  'color has name "fuchsia"');
is( $cval_obj->{'rgb'}[0],                  1,  'violet(fuchsia) has a maximal red color');
is( $cval_obj->{'rgb'}[1],                  0,  'violet(fuchsia) has a no green color');
is( $cval_obj->{'rgb'}[2],                  1,  'violet(fuchsia) has a maximal blue color');

# my ($cname, $cd) = $val_obj->closest_name(2);
# is( $cname,                         'fuchsia',  'closest name is same as name');
# is( $cval_obj->closest_name,    'fuchsia',  'closest name is same as name');

exit 0;


__END__

new_from_any_input { #  values => %space_name => tuple ,   ~origin_space, ~color_name
rgb_from_external_module {
new_from_normal_tuple {
get_name { $_[0]->{'name'} }
get_closest_name
get_normal_tuple
get_custom_form { # get a value tuple in any color space, range and format
set { # %val --> _
add { # %val --> _
mix { #  @%(+percent _values)  -- ~space_name --> _values
distance { # _c1 _c2 -- ~space ~select @range --> +

