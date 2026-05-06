#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::More tests => 1;

my $module = 'Graphics::Toolkit::Color::Error';
my $space = eval "require $module";
is( not($@), 1, 'could load the module');
say $@;

exit 0;
