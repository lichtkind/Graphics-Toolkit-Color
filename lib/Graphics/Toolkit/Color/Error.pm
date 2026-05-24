
# central hub of error handling

package Graphics::Toolkit::Color::Error;

use v5.12;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/error/;
use Carp;

my $mode = 'carp';


sub change_mode {
    my ($new_mode) = @_;
    return unless defined $new_mode;
    $new_mode = lc $new_mode;
    return unless $new_mode eq 'carp' or $new_mode eq 'croak' or $new_mode eq 'quit'
               or $new_mode eq 'say'  or $new_mode eq 'die';
	$mode = $new_mode;    
}

sub error {
    my ($message) = @_;
	my ($package, $filename, $line, $sub) = caller(1);
	my $report = "$sub: $message";
	if    ($mode eq 'say') {  say   $report }
	elsif ($mode eq 'die') {  die   $report }
	elsif ($mode eq 'carp'){  carp  $report }
	elsif ($mode eq 'croak'){ croak $report }
}

1;
