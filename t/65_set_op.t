#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 130;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Values::Set';
use_ok( $module, 'could load the module');



exit 0;


__END__

gradient
complement
cluster
