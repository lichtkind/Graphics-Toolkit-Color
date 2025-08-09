#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 90;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $module = 'Graphics::Toolkit::Color';
my $red   = color('#FF0000');
my $blue  = color('#0000FF');
my $white = color('white');
my $black = color('black');

#### complement ########################################################

#### gradient ##########################################################

#### cluster ###########################################################


exit 0;
