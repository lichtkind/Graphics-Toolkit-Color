
# self made test functions

package Test::Color;
use v5.12;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_tuple);

use Test::Builder;
my $tb = Test::Builder->new;

sub is_tuple {
    my ($got, $expected, $axis, $name) = @_;
    my $pass = 0;
    my $diag = '';

    if   ( @_ < 4 ) { $diag = "'is_tuple' got not enough arguments" } 
    else {
		$diag = "failed test: $name -";
		if    (ref $got ne 'ARRAY')     { $diag .= " got values that are not a tuple (ARRAY ref)" } 
	    elsif (ref $expected ne 'ARRAY'){ $diag .= " expected values are not a tuple (ARRAY ref)" } 
	    elsif (ref $axis ne 'ARRAY')    { $diag .= " axis names are not in a tuple (ARRAY ref)" } 
	    else {
			my $tuple_length = @$axis;
			if    ( @$got > $tuple_length)     { $diag .= " got more values than axis names ($tuple_length)" }
			elsif ( @$got < $tuple_length)     { $diag .= " got less values than axis names ($tuple_length)" }
			elsif ( @$expected > $tuple_length){ $diag .= " expected value tuple has more values than axis names ($tuple_length)" }
			elsif ( @$expected < $tuple_length){ $diag .= " expected value tuple has less values than axis names ($tuple_length)" }
			else {
				$pass = 1;
				for my $axis_number (0 .. $#$axis){
					my $axis_name = $axis->[$axis_number];
					if (not is_nr($got->[$axis_number])) {
						$pass = 0;
						$diag .= " $axis_name value I got is not a number,";
						next;
					}
					if ($got->[$axis_number] != $expected->[$axis_number] and $got->[$axis_number] ne $expected->[$axis_number]) {
						$pass = 0;
						$diag .= " expected $axis_name value of $expected->[$axis_number] but got $got->[$axis_number],";
					}
				}
				chop $diag;
			}
		}
	}
    $tb->diag( $diag ) unless $pass;
    $tb->ok($pass, $name);
}


sub is_nr { $_[0] =~ /^\-?\d+(\.\d+)?$/ }

1;
