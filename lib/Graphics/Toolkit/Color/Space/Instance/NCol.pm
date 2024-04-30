use v5.12;
use warnings;

# NCol color space specific code (HWB with human readable hus values)

package Graphics::Toolkit::Color::Space::Instance::NCol;
use Graphics::Toolkit::Color::Space::Util qw/min max/;
use Graphics::Toolkit::Color::Space;

my $hsl_def = Graphics::Toolkit::Color::Space->new( name => 'NCol',
                                                    axis => [qw/hue whiteness blackness/],
                                                   range => [360, 100, 100],  precision => 0,
                                                  suffix => ['', '%', '%'],
                                                    type => [qw/no linear linear/],
                                                    );

   $hsl_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub from_rgb {
    my ($r, $g, $b) = @_;
    my $vmax = max($r, $g, $b),
    my $vmin = min($r, $g, $b);
    my $l = ($vmax + $vmin) / 2;
    return (0, 0, $l) if $vmax == $vmin;
    my $d = $vmax - $vmin;
    my $s = ($l > 0.5) ? ($d / (2 - $vmax - $vmin)) : ($d / ($vmax + $vmin));
    my $h = ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ($h/6, $s, $l);
}

sub to_rgb {
    my ($h, $s, $l) = @_;
    $h *= 6;
    my $C = $s * (1 - abs($l * 2 - 1));
    my $X = $C * (1 - abs( rmod($h, 2) - 1) );
    my $m = $l - ($C / 2);
    return ($h < 1) ? ($C + $m, $X + $m,      $m)
         : ($h < 2) ? ($X + $m, $C + $m,      $m)
         : ($h < 3) ? (     $m, $C + $m, $X + $m)
         : ($h < 4) ? (     $m, $X + $m, $C + $m)
         : ($h < 5) ? ($X + $m,      $m, $C + $m)
         :            ($C + $m,      $m, $X + $m);
}

$hsl_def;

__END__

sub from_rgb {
    my ($r, $g, $b) = @_;
    my $vmax = max($r, $g, $b);
    my $white = my $vmin = min($r, $g, $b);
    my $black = 1 - ($vmax);

    my $d = $vmax - $vmin;
    my $s = $d / $vmax;
    my $h =     ($d == 0) ? 0 :
            ($vmax == $r) ? (($g - $b) / $d + ($g < $b ? 6 : 0)) :
            ($vmax == $g) ? (($b - $r) / $d + 2)
                          : (($r - $g) / $d + 4);
    return ($h/6, $white, $black);
}


sub to_rgb {
    my ($h, $w, $b) = @_;
    return (0, 0, 0) if $b == 1;
    return (1, 1, 1) if $w == 1;
    my $v = 1 - $b;
    my $s = 1 - ($w / $v);
    $s = 0 if $s < 0;
    return ($v, $v, $v) if $s == 0;

    my $hi = int( $h * 6 );
    my $f = ( $h * 6 ) - $hi;
    my $p = $v * (1 -  $s );
    my $q = $v * (1 - ($s * $f));
    my $t = $v * (1 - ($s * (1 - $f)));
    my @rgb = ($hi == 1) ? ($q, $v, $p)
            : ($hi == 2) ? ($p, $v, $t)
            : ($hi == 3) ? ($p, $q, $v)
            : ($hi == 4) ? ($t, $p, $v)
            : ($hi == 5) ? ($v, $p, $q)
            :              ($v, $t, $p);
}
