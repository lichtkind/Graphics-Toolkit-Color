BEGIN { unshift @INC, '../../../lib'}

use v5.12;
use warnings;
use GD;
use Graphics::Toolkit::Color qw/color/;;

my $file_name_stem = 'colors';
my $blue = color('blue');
my $orange = color('orange');
my $morange = $orange->add_value(red => -36, green => -10);
my $lightblue = $blue->lighten(0.2);
my $font  = gdMediumBoldFont;
my ($rows, $cols, @colors, $black, $white) = (1, 10);

paint_row( '1_okhsl_complement', $blue->complement( steps => $cols) );
paint_row( '2_lchuv_complement', $blue->complement( steps => $cols, in => 'LCHuv') );# 2
paint_row( '3_hsl_complement', $blue->complement( steps => $cols, in => 'HSL') );  # 3

paint_row( '4_okhsl_light_compl', $lightblue->complement( steps => $cols) );
paint_row( '5_lchuv_light_compl', $lightblue->complement( steps => $cols, in => 'LCHuv') );
paint_row( '6_hsl_light_compl', $lightblue->complement( steps => $cols, in => 'HSL') );

paint_row( '7_okhsl_light_compl_zero_tilt', $lightblue->complement( steps => $cols) );         
paint_row( '8_okhsl_light_compl_half_tilt', $lightblue->complement( steps => $cols, tilt => .5	) );
paint_row( '9_okhsl_light_compl_full_tilt', $lightblue->complement( steps => $cols, tilt => 1) );

paint_row( '10_okhsl_light_compl_zero_skew', $lightblue->complement( steps => $cols) );              # 10
paint_row( '11_okhsl_light_compl_half_skew', $lightblue->complement( steps => $cols, skew => 0.2) ); # 11
paint_row( '12_okhsl_light_compl_full_skew',$lightblue->complement( steps => $cols, skew => 0.3) ); # 12

paint_row( '13_okhsl_light_compl_no_target', $lightblue->complement( steps => $cols) );                       # 13
paint_row( '14_okhsl_light_compl_hue_target', $lightblue->complement( steps => $cols, target => {hue => 60}) ); # 14
paint_row( '15_okhsl_light_compl_-sat_target', $lightblue->complement( steps => $cols, target => {saturation => -.60}) ); # 15
paint_row( '16_okhsl_compl_no_target', $blue->complement( steps => $cols) );                               
paint_row( '17_okhsl_compl_lightness_target', $blue->complement( steps => $cols, target => {lightness => .40}) );

paint_row( '20_okhsl_analogous', $orange->analogous( steps => $cols, to => $morange) ); 
paint_row( '21_rgb_analogous',   $orange->analogous( steps => $cols, to => $morange, in => 'RGB') ); 
paint_row( '22_okhsl_analogous_tilt', $orange->analogous( steps => $cols, to => $morange, tilt => -0.1) ); 

paint_row( '30_oklab_gradient', $blue->gradient( to => 'white', steps => $cols) );
paint_row( '31_okhsl_gradient', $blue->gradient( to => 'white', steps => $cols, in => 'OKHSL') );
paint_row( '32_okhsv_gradient', $blue->gradient( to => 'white', steps => $cols, in => 'OKHSV') );
paint_row( '33_okhwb_gradient', $blue->gradient( to => 'white', steps => $cols, in => 'OKHWB') );
paint_row( '34_lab_gradient', $blue->gradient( to => 'white', steps => $cols, in => 'LAB') );
paint_row( '35_hsl_gradient', $blue->gradient( to => 'white', steps => $cols, in => 'HSL') );
paint_row( '36_oklab_gradient_tilt_neg', $blue->gradient( to => 'white', steps => $cols, tilt => -1.5) );
paint_row( '37_oklab_gradient_tilt_pos', $blue->gradient( to => 'white', steps => $cols, tilt => 1.5) );
paint_row( '38_oklab_gradient_2colors', $blue->gradient( to => ['white', 'green'], steps => $cols) );
paint_row( '39_oklab_gradient_3colors	', $blue->gradient( to => ['white', 'green', 'lime'], steps => $cols) );

paint_row( '40_oklab_cluster', $blue->cluster( r => .3, min_d => 0.25) );
paint_row( '41_rgb_cluster', $blue->cluster( r => 99, min_d => 55, in =>'RGB') );
say int $blue->cluster( r => 99, min_d => 55, in =>'RGB');

# cluster: r min_d in , ball cube

sub paint_row {
	state $image_nr = 1;
	my ($name, @colors) = @_;
	if (ref $name){
		unshift @colors, $name;
		$name = $image_nr++;
	}
    my $im = new_image();

	for my $color_nr (0 .. $#colors){
		my $color = $im->colorAllocate( $colors[$color_nr]->values );
        my $x = 25 + 75 * $color_nr;
        my $y = 25 + 75 * 0;
        $im->filledRectangle($x, $y, $x+50, $y + 50, $color);
        $im->rectangle(      $x, $y, $x+50, $y + 50, $black);
	}
	save_image( $im, $name);
}

sub new_image {
    my $im = GD::Image->new(775, 100);
    $white = $im->colorAllocate(255,255,255); 
    $black = $im->colorAllocate(  0,  0,  0); 
    $im;
}

sub save_image {
    my ($im, $name) = @_;
    open my $FH, '>', $file_name_stem.'_'.$name.'.png';
    binmode STDOUT;
    print $FH $im->png;
}
#    #$im->string( $font,  $x+30, $y, $name, $black );
