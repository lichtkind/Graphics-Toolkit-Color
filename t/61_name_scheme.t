#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 60;
use Benchmark;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Name::Scheme';
my $space_ref = 'Graphics::Toolkit::Color::Space';

use_ok( $module, 'could load the module');

my $t0 = Benchmark->new;
my $all_values = require Graphics::Toolkit::Color::Name::Constant;

    my $gdistance = 0;
    my $name1 = '';
    my $name2 = '';
    for my $outer_name_index (keys %$all_values){
        my $ldistance = 1_000_000;
        my $ovalues = $all_values->{ $outer_name_index };
        for my $inner_name_index (keys %$all_values){
            next unless $outer_name_index ne $inner_name_index;
            my $ivalues = $all_values->{ $inner_name_index };
            my $d = ($ovalues->[0] - $ivalues->[0]) ** 2;
            next if $d > $ldistance;
            $d += ($ovalues->[1] - $ivalues->[1]) ** 2 ;
            next if $d > $ldistance;
            $d += ($ovalues->[2] - $ivalues->[2]) ** 2 ;
            next if $d > $ldistance;
            $ldistance = $d;
        }
        $ldistance = sqrt $ldistance;
        $gdistance = $ldistance if $ldistance > $gdistance;
    }

print "code took:",timestr( timediff( Benchmark->new, $t0 ) ),"\n";
say "max min distance is $gdistance";

exit 0;

# max 0.14
