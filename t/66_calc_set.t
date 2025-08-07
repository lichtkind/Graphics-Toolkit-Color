#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 130;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::SetCalculator';
use_ok( $module, 'could load the module');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');

#### gradient ##########################################################
# @:colors, +steps, +tilt, :space --> @:values
my $gradient = \&Graphics::Toolkit::Color::SetCalculator::gradient;


#### complement ########################################################
my $complement = \&Graphics::Toolkit::Color::SetCalculator::complement;

#### cluster ###########################################################
my $cluster = \&Graphics::Toolkit::Color::SetCalculator::cluster;

exit 0;
