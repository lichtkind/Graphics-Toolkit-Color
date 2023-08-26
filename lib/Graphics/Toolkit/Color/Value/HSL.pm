use v5.12;
use warnings;

# check, convert and measure color values in HSL space

package Graphics::Toolkit::Color::Value::HSL;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hsl_def = Graphics::Toolkit::Color::Space->new( axis => [qw/hue saturation lightness/],
                                                   range => [ 359, 100, 100 ],
                                                    type => [qw/angle linear linear/]);
   $hsl_def->add_converter('RGB', \&to_rgb, \&from_rgb );



sub _from_rgb { # float conversion
    my (@rgb) = @_;
    my ($maxi, $mini) = (0 , 1);   # index of max and min value in @rgb
    if    ($rgb[1] > $rgb[0])      { ($maxi, $mini ) = ($mini, $maxi ) }
    if    ($rgb[2] > $rgb[$maxi])  {  $maxi = 2 }
    elsif ($rgb[2] < $rgb[$mini])  {  $mini = 2 }
    my $delta = $rgb[$maxi] - $rgb[$mini];
    my $avg = ($rgb[$maxi] + $rgb[$mini]) / 2;
    my $H = !$delta ? 0 : (2 * $maxi + (($rgb[($maxi+1) % 3] - $rgb[($maxi+2) % 3]) / $delta)) * 60;
    $H += 360 if $H < 0;
    my $S = ($avg == 0) ? 0 : ($avg == 255) ? 0 : $delta / (255 - abs((2 * $avg) - 255));
    ($H, $S * 100, $avg * 0.390625 );
}
sub from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    my (@rgb) = @_;
    my $real = '';
    if (ref $rgb[0] eq 'ARRAY'){
        @rgb = @{$rgb[0]};
        $real = $rgb[1] // $real;
    }
    my @hsl = _from_rgb( @rgb );
    return @hsl if $real;
    ( round( $hsl[0] ), round( $hsl[1] ), round( $hsl[2] ) );
}

sub _to_rgb { # float conversion  255 ?
    my ($H, $S, $L) = clamp(@_);
    $H /= 60;
    $S /= 100;
    $L /= 100;
    my $C = $S * (1 - abs($L * 2 - 1));
    my $X = $C * (1 - abs( rmod($H, 2) - 1) );
    my $m = $L - ($C / 2);
    ($C, $X, $m) = map { $_ * 255 } $C, $X, $m;
    return ($H < 1) ? ($C + $m, $X + $m,      $m)
         : ($H < 2) ? ($X + $m, $C + $m,      $m)
         : ($H < 3) ? (     $m, $C + $m, $X + $m)
         : ($H < 4) ? (     $m, $X + $m, $C + $m)
         : ($H < 5) ? ($X + $m,      $m, $C + $m)
         :            ($C + $m,      $m, $X + $m);
}
sub to_rgb { # convert color value triplet (int > int), (real > real) if $real
    my (@hsl) = @_;
    my $real = '';
    if (ref $hsl[0] eq 'ARRAY'){
        @hsl = @{$hsl[0]};
        $real = $hsl[1] // $real;
    }
    my @rgb = _to_rgb( @hsl );
    return @rgb if $real;
    ( int( $rgb[0] ), int( $rgb[1] ), int( $rgb[2] ) );
}

$hsl_def;
