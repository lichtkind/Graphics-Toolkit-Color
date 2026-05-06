
# central hub of error handling

package Error;

use v5.12;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT;
use Carp;

my $mode ;

sub import {
    my ($class, @args) = @_;
    my @export_symbols;
    push @EXPORT, shift @args while lc $args[0] ne 'mode';
    $mode = (exists $args[1]) ? $args[1] : 'carp';
    $mode = lc $mode;
    if ($mode ne 'carp' and $mode ne 'croak' and $mode ne 'say' and $mode ne 'die'){
		say "called for illegal error mode, setting it to carp";
		$mode = 'carp';
	}
    $class->Exporter::export_to_level(1, $class);
}

sub error {
    my ($message) = @_;
	my ($package, $filename, $line, $sub) = caller(1);
	my $report = "$sub: $message";
	if    ($mode eq 'say') {  say   $report }
	if    ($mode eq 'die') {  die   $report }
	elsif ($mode eq 'carp'){  carp  $report }
	elsif ($mode eq 'croak'){ croak $report }
}

sub call { error(@_) }

1;

