use v5.12;
use warnings;

# check, convert and measure color values in HWB space

package Graphics::Toolkit::Color::Value::HWB;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hwb_def = Graphics::Toolkit::Color::Space->new( axis => [qw/hue whiteness blackness/],
                                                   range => [359, 100, 100],
                                                    type => [qw/angle linear linear/]);
   $hwb_def->add_converter('RGB', \&to_rgb, \&from_rgb );


sub _from_rgb { # float conversion
    my (@rgb) = @_;
    my ($maxi, $mini) = (0 , 1);   # index of max and min value in @rgb
    if    ($rgb[1] > $rgb[0])      { ($maxi, $mini ) = ($mini, $maxi ) }
    if    ($rgb[2] > $rgb[$maxi])  {  $maxi = 2 }
    elsif ($rgb[2] < $rgb[$mini])  {  $mini = 2 }
    my $delta = $rgb[$maxi] - $rgb[$mini];
    my $H = $delta ==           0  ?  0                                        :
                      ($maxi == 0) ? 60 * rmod( ($rgb[1]-$rgb[2]) / $delta, 6) :
                      ($maxi == 1) ? 60 * ( (($rgb[2]-$rgb[0]) / $delta ) + 2)
                                   : 60 * ( (($rgb[0]-$rgb[1]) / $delta ) + 4) ;

     my $S = ($rgb[$maxi] == 0) ? 0 : ($delta / $rgb[$maxi]);
    ($H, $S * 100, $rgb[$maxi] * 0.390625);
}
sub from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    my (@rgb) = @_;
    my $real = '';
    if (ref $rgb[0] eq 'ARRAY'){
        @rgb = @{$rgb[0]};
        $real = $rgb[1] // $real;
    }
    #check_rgb( @rgb ) and return unless $real;
    my @hsl = _from_rgb( @rgb );
    return @hsl if $real;
    ( round( $hsl[0] ), round( $hsl[1] ), round( $hsl[2] ) );
}

sub _to_rgb { # float conversion
    my (@hsv) = clamp(@_);
    my $H = $hsv[0] / 60;
    my $C = $hsv[1]* $hsv[2] / 100 / 100;
    my $X = $C * (1 - abs(rmod($H, 2) - 1));
    my $m = ($hsv[2] / 100) - $C;
    my @rgb = ($H < 1) ? ($C + $m, $X + $m,      $m)
            : ($H < 2) ? ($X + $m, $C + $m,      $m)
            : ($H < 3) ? (     $m, $C + $m, $X + $m)
            : ($H < 4) ? (     $m, $X + $m, $C + $m)
            : ($H < 5) ? ($X + $m,      $m, $C + $m)
            :            ($C + $m,      $m, $X + $m);
    map { 256 * $_ } @rgb;
}
sub to_rgb { # convert color value triplet (int > int), (real > real) if $real
    my (@hsv) = @_;
    my $real = '';
    if (ref $hsv[0] eq 'ARRAY'){
        @hsv = @{$hsv[0]};
        $real = $hsv[1] // $real;
    }
    #check( @hsv ) and return unless $real;
    my @rgb = _to_rgb( @hsv );
    return @rgb if $real;
    ( int( $rgb[0] ), int( $rgb[1] ), int( $rgb[2] ) );
}

$hwb_def;
