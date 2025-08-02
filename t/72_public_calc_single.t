#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 90;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';
use Graphics::Toolkit::Color qw/color/;

my $red   = color('#FF0000');
my $blue  = color('#0000FF');
my $white = color('white');
my $black = color('black');

exit 0;

__END__

set add mix

 add( hue => 100 , in => 'HWB' )

 mix    to => ['HSL', 240, 100, 50]    # scalar color definition or ARRAY ref thereof
        amount => 20                   # percentage value or ARRAY ref thereof, default is 50
        in => 'HSL'                    # color space name, defaults to "RGB"
