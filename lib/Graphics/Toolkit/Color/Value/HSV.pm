use v5.12;
use warnings;

# check, convert and measure color values in HSV space

package Graphics::Toolkit::Color::Value::HSV;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $hsv_def = Graphics::Toolkit::Color::Space->new(qw/hue saturation value/);
   $hsv_def->add_converter('RGB', \&to_rgb, \&from_rgb );

########################################################################

sub check {
    my (@hsv) = @_;
    my $help = 'has to be an integer between 0 and';
    return carp "need exactly 3 positive integer between 0 and 359 or 100 for hsv input" unless $hsv_def->is_array( \@hsv );
    return carp "hue value $hsv[0] $help 359"        unless int $hsv[0] == $hsv[0] and $hsv[0] >= 0 and $hsv[0] < 360;
    return carp "saturation value $hsv[1] $help 100" unless int $hsv[1] == $hsv[1] and $hsv[1] >= 0 and $hsv[1] < 101;
    return carp "value value $hsv[2] $help 100"      unless int $hsv[2] == $hsv[2] and $hsv[2] >= 0 and $hsv[2] < 101;
    0;
}

sub trim { # cut values into 0 ..359, 0 .. 100, 0 .. 100
    my (@hsv) = @_;
    return (0,0,0) if @hsv < 1;
    pop @hsv while @hsv > 3;

    $hsv[0] += 360 while $hsv[0] <    0;
    $hsv[0] -= 360 while $hsv[0] >= 360;
    for (1 .. 2){
        $hsv[$_] =   0 unless exists $hsv[$_];
        $hsv[$_] =   0 if $hsv[$_] <   0;
        $hsv[$_] = 100 if $hsv[$_] > 100;
    }
    map {round($_)} @hsv;
}

sub delta { # \@hsv, \@hsv --> @delty
    my ($hsv1, $hsv2) = @_;
    return carp  "need two triplets of hsl values in 2 arrays to compute hsl differences"
        unless $hsv_def->is_array( $hsv1 ) and $hsv_def->is_array( $hsv2 );
    check(@$hsv1) and return;
    check(@$hsv2) and return;
    my $delta_h = abs($hsv1->[0] - $hsv2->[0]);
    $delta_h = 360 - $delta_h if $delta_h > 180;
    ($delta_h, abs($hsv1->[1] - $hsv2->[1]), abs($hsv1->[2] - $hsv2->[2]) );
}

sub distance { # \@hsv, \@hsv --> $d
    return carp  "need two triplets of hsl values in 2 arrays to compute hsl distance " if @_ != 2;
    my @delta_hsl = delta( $_[0], $_[1] );
    return unless @delta_hsl == 3;
    sqrt($delta_hsl[0] ** 2 + $delta_hsl[1] ** 2 + $delta_hsl[2] ** 2);
}

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
    my $S = ($rgb[$maxi] == 0) ? 0 : ($delta / $rgb[$maxi]);
    ($H, $S * 100, $rgb[$maxi] * 0.392156863 );
}

sub from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    my (@rgb) = @_;
    my $real = '';
    if (ref $rgb[0] eq 'ARRAY'){
        @rgb = @{$rgb[0]};
        $real = $rgb[1] // $real;
    }
    check_rgb( @rgb ) and return unless $real;
    my @hsl = _from_rgb( @rgb );
    return @hsl if $real;
    ( round( $hsl[0] ), round( $hsl[1] ), round( $hsl[2] ) );
}

sub _to_rgb { # float conversion
    my (@hsv) = @_;
    $hsv[0] /= 60;

    my $C = $hsv[1] / 100 * $hsv[2] / 100;
    my $X = $C * (1 - abs($hsv[0] % 2 - 1));
    my $m = ($hsv[2] / 100) - $C;

    my @rgb = ($hsv[0] < 1) ? ($C + $m, $X + $m,      $m)
            : ($hsv[0] < 2) ? ($X + $m, $C + $m,      $m)
            : ($hsv[0] < 3) ? (     $m, $C + $m, $X + $m)
            : ($hsv[0] < 4) ? (     $m, $X + $m, $C + $m)
            : ($hsv[0] < 5) ? ($X + $m,      $m, $C + $m)
            :                 ($C + $m,      $m, $X + $m);
    map { 255 * $_ } @rgb;
}

sub to_rgb { # convert color value triplet (int > int), (real > real) if $real
    my (@hsv) = @_;
    my $real = '';
    if (ref $hsv[0] eq 'ARRAY'){
        @hsv = @{$hsv[0]};
        $real = $hsv[1] // $real;
    }
    check( @hsv ) and return unless $real;
    my @rgb = _to_rgb( @hsv );
    return @rgb if $real;
    ( round( $rgb[0] ), round( $rgb[1] ), round( $rgb[2] ) );
}

$hsv_def;
