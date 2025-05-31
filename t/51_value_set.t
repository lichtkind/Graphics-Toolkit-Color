#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 57;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Set';

__END__
