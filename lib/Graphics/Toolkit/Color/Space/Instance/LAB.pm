use v5.12;
use warnings;

# LAB color space specific code based on XYZ

package Graphics::Toolkit::Color::Space::Instance::LAB;
use Graphics::Toolkit::Color::Space;
 se Graphics::Toolkit::Color::Space::Util qw/mult_matrix apply_d65 remove_d65/;

my  $lab_def = Graphics::Toolkit::Color::Space->new( axis => [qw/L* a* b*/], # 
                                                   prefix => 'CIE',
                                                    range => [100, 500, 200] );

    $lab_def->add_converter('RGB', \&to_rgb, \&from_rgb );

sub from_rgb {
    my ($r, $g, $b) = @_;
    my ($x, $y, $z) = mult_matrix([[0.4124564, 0.2126729, 0.0193339],
                                   [0.3575761, 0.7151522, 0.1191920],
                                   [0.1804375, 0.0721750, 0.9503041]], 
                                   apply_d65( $r ), apply_d65( $g ), apply_d65( $b ));
    $x /= 0.95047;
    $z /= 0.108883;
    
    $x = ($x > 0.008856) ? ($x ** (1/3)) : (7.7870689 * $x + 0.137931034);
    $y = ($y > 0.008856) ? ($y ** (1/3)) : (7.7870689 * $y + 0.137931034);
    $z = ($z > 0.008856) ? ($z ** (1/3)) : (7.7870689 * $z + 0.137931034);

    my $l = (116 * $y) - 16;
    my $a = 500 * ($x - $y);
    my $b = 200 * ($y - $z);
    return ($l, $a, $b);
}


sub to_rgb {
    my ($l, $a, $b) = @_;
    $i = ($i * $i_size) - $i_max;
    $q = ($q * $q_size) - $q_max;
    my $r = $y + ( 0.956 * $i) + ( 0.619 * $q);
    my $g = $y + (-0.272 * $i) + (-0.647 * $q);
    my $b = $y + (-1.106 * $i) + ( 1.703 * $q);
    return ($r, $g, $b);
}

$lab_def;

__END__

