
package Test::Color;

use Test::Builder;
my $tb = Test::Builder->new;

sub color_ok {
    my ($got, $expected, $name) = @_;
    my $pass = # deine Vergleichslogik
    $tb->ok($pass, $name);
    unless ($pass) {
        $tb->diag("got:      " . join(', ', @$got));
        $tb->diag("expected: " . join(', ', @$expected));
    }
}
