
# central hub of error handling

package Graphics::Toolkit::Color::Error;

use v5.12;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/error/;
use Carp;

my $mode = 'carp';

sub import {
    my ($class, @args) = @_;
    my @export_symbols;
    push @EXPORT, shift @args while exists $args[0] and lc $args[0] ne 'mode';
    $mode = (exists $args[1]) ? $args[1] : 'carp';
    say "called for illegal error mode, setting it to carp" unless defined change_mode( $mode );
    $class->Exporter::export_to_level(1, $class);
}

sub change_mode {
    my ($new_mode) = @_;
    return unless defined $new_mode;
    $new_mode = lc $new_mode;
    return unless $new_mode eq 'carp' or $new_mode eq 'croak'
               or $new_mode eq 'say'  or $new_mode eq 'die';
	$mode = $new_mode;    
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

1;
