
# DCI-P3

package Graphics::Toolkit::Color::Space::Instance::DCIP3Linear;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space qw/gamma_correct/;

my $gamma = 2.6;

sub from_dcip3l {
    my ($lrgb) = shift;
    return [ map { ($_ > 0.0031308) ? ( (gamma_correct($_, 1/$gamma) *  1.055) - 0.055) 
		                            :         ($_            * 12.92)          } @$lrgb ];
}
sub to_dcip3l {
	my ($rgb) = shift;
	return [  map {  ($_ > 0.04045)  ? gamma_correct((($_ + 0.055) /  1.055 ), $gamma) 
                                     :        ($_          / 12.92)           } @$rgb ];
}
 
Graphics::Toolkit::Color::Space->new(
        name => 'DCI-P3',
        axis => [qw/red green blue/],
   precision => 6,
     convert => {'Display-P3-Linear' => [\&to_dp3l, \&from_dp3l]},
);

__END__

DCI-P3 Linear > XYZ:

[ 0.4451698156   0.2771344092   0.1722826698 ]
[ 0.2094916779   0.7215952542   0.0689130679 ]
[ 0.0000000000   0.0470605601   0.9073553944 ]

Inverse (XYZ > DCI-P3 Linear):

[  2.7253940305  -1.0180030062  -0.4401631952 ]
[ -0.7951680258   1.6897320548   0.0226471906 ]
[  0.0412418914  -0.0876390192   1.1009293786 ]

