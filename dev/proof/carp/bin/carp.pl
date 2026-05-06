use v5.12;
use warnings;
use lib 'lib';
use Error qw/call error/, mode => 'carp';

call('I call something that goes wrong');
