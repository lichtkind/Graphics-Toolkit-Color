#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 60;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Name::Scheme';
my $space_ref = 'Graphics::Toolkit::Color::Space';

use_ok( $module, 'could load the module');


exit 0;
