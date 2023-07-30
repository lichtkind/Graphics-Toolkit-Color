use v5.12;
use warnings;

# check, convert and measure color values in CMY space

package Graphics::Toolkit::Color::Value::CMY;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::SpaceKeys;
use Graphics::Toolkit::Color::Value::RGB  ':all';

use Carp;
use Exporter 'import';
our @EXPORT_OK = qw/check_cmyk trim_cmyk delta_cmyk distance_cmyk cmyk_from_rgb rgb_from_cmyk/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

our $def = Graphics::Toolkit::Color::SpaceKeys->new(qw/cyan magenta yellow/);


sub check_cmyk { &check }
sub check {
    my (@cmyk) = @_;
    my $help = 'has to be a real value between 0 and 1';
    return carp "need exactly 4 positive integer between 0 and 100 for hsl input" unless @cmyk == 4;
    return carp "cyan value $cmyk[0] $help"    unless $cmyk[0] >= 0 and $cmyk[0] <= 1;
    return carp "magenty value $cmyk[1] $help" unless $cmyk[1] >= 0 and $cmyk[1] <= 1;
    return carp "yellow value $cmyk[2] $help"  unless $cmyk[2] >= 0 and $cmyk[2] <= 1;
    return carp "key value $cmyk[3] $help"     unless $cmyk[2] >= 0 and $cmyk[2] <= 1;
    0;
}

sub trim_cmyk { &trim }
sub trim { # cut values into 0 .. 100, 0 .. 100, 0 .. 100
    my (@cmyk) = @_;
    #~ return (0,0,0) unless @hsl == 3;
    #~ $hsl[0] += 360 while $hsl[0] <    0;
    #~ $hsl[0] -= 360 while $hsl[0] >= 360;
    #~ for (1..2){
        #~ $hsl[$_] =   0 if $hsl[$_] <   0;
        #~ $hsl[$_] = 100 if $hsl[$_] > 100;
    #~ }
    #~ $hsl[$_] = round($hsl[$_]) for 0..2;
    #~ @hsl;
}

sub delta_cmyk { &delta }
sub delta {  # \@cmyk, \@cmyk --> $d
    my ($cmyk, $cmyk2) = @_;
    #~ return carp  "need two triplets of hsl values in 2 arrays to compute hsl differences"
        #~ unless ref $hsl eq 'ARRAY' and @$hsl == 3 and ref $hsl2 eq 'ARRAY' and @$hsl2 == 3;
    #~ check(@$hsl) and return;
    #~ check(@$hsl2) and return;
    #~ my $delta_h = abs($hsl->[0] - $hsl2->[0]);
    #~ $delta_h = 360 - $delta_h if $delta_h > 180;
    #~ ($delta_h, abs($hsl->[1] - $hsl2->[1]), abs($hsl->[2] - $hsl2->[2]) );
}

sub distance_cmyk { &distance }
sub distance { # \@hsl, \@hsl --> $d
    #~ return carp  "need two triplets of hsl values in 2 arrays to compute hsl distance " if @_ != 2;
    #~ my @delta_hsl = delta( $_[0], $_[1] );
    #~ return unless @delta_hsl == 3;
    #~ sqrt($delta_hsl[0] ** 2 + $delta_hsl[1] ** 2 + $delta_hsl[2] ** 2);
}

sub _from_rgb { # float conversion
    #~ my (@rgb) = @_;
    #~ my ($maxi, $mini) = (0 , 1);   # index of max and min value in @rgb
    #~ if    ($rgb[1] > $rgb[0])      { ($maxi, $mini ) = ($mini, $maxi ) }
    #~ if    ($rgb[2] > $rgb[$maxi])  {  $maxi = 2 }
    #~ elsif ($rgb[2] < $rgb[$mini])  {  $mini = 2 }
    #~ my $delta = $rgb[$maxi] - $rgb[$mini];
    #~ my $avg = ($rgb[$maxi] + $rgb[$mini]) / 2;
    #~ my $H = !$delta ? 0 : (2 * $maxi + (($rgb[($maxi+1) % 3] - $rgb[($maxi+2) % 3]) / $delta)) * 60;
    #~ $H += 360 if $H < 0;
    #~ my $S = ($avg == 0) ? 0 : ($avg == 255) ? 0 : $delta / (255 - abs((2 * $avg) - 255));
    #~ ($H, $S * 100, $avg * 0.392156863 );
}

sub cmyk_from_rgb { &from_rgb }
sub from_rgb { # convert color value triplet (int --> int), (real --> real) if $real
    #~ my (@rgb) = @_;
    #~ my $real = '';
    #~ if (ref $rgb[0] eq 'ARRAY'){
        #~ @rgb = @{$rgb[0]};
        #~ $real = $rgb[1] // $real;
    #~ }
    #~ check_rgb( @rgb ) and return unless $real;
    #~ my @hsl = _from_rgb( @rgb );
    #~ return @hsl if $real;
    #~ ( round( $hsl[0] ), round( $hsl[1] ), round( $hsl[2] ) );
}

sub _to_rgb { # float conversion
    #~ my (@hsl) = @_;
    #~ $hsl[0] /= 60;
    #~ my $C = $hsl[1] * (100 - abs($hsl[2] * 2 - 100)) * 0.0255;
    #~ my $X = $C * (1 - abs($hsl[0] % 2 - 1 + ($hsl[0] - int $hsl[0])));
    #~ my $m = ($hsl[2] * 2.55) - ($C / 2);
    #~ return ($hsl[0] < 1) ? ($C + $m, $X + $m,      $m)
         #~ : ($hsl[0] < 2) ? ($X + $m, $C + $m,      $m)
         #~ : ($hsl[0] < 3) ? (     $m, $C + $m, $X + $m)
         #~ : ($hsl[0] < 4) ? (     $m, $X + $m, $C + $m)
         #~ : ($hsl[0] < 5) ? ($X + $m,      $m, $C + $m)
         #~ :                 ($C + $m,      $m, $X + $m);
}

sub rgb_from_cmyk { &to_rgb }
sub to_rgb { # convert color value triplet (int > int), (real > real) if $real
    #~ my (@hsl) = @_;
    #~ my $real = '';
    #~ if (ref $hsl[0] eq 'ARRAY'){
        #~ @hsl = @{$hsl[0]};
        #~ $real = $hsl[1] // $real;
    #~ }
    #~ check( @hsl ) and return unless $real;
    #~ my @rgb = _to_rgb( @hsl );
    #~ return @rgb if $real;
    #~ ( round( $rgb[0] ), round( $rgb[1] ), round( $rgb[2] ) );
}

sub as_hash {
    my (@cmyk) = @_;
    check(@cmyk) and return;
    return {'cyan' => $cmyk[0], 'magenta' => $cmyk[1], 'yellow' => $cmyk[2], 'key' => $cmyk[3], };
}

1;
