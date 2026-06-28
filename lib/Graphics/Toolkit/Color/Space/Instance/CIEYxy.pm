
#  CIEYxy color space, alias CIExyY

package Graphics::Toolkit::Color::Space::Instance::Yxy;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

sub from_Yxy {
    my ($Yxy) = @_;
    my $xyY = [@$Yxy];
    push @$xyY, shift(@$xyY);
    return $xyY;
}
sub to_Yxy {
    my ($xyY) = @_;
    my $Yxy = [@$xyY];
    unshift @$Yxy, pop(@$Yxy);
    return $Yxy;
}

Graphics::Toolkit::Color::Space->new (
      alias_name => 'CIEYxy', 
            axis => [qw/Y x y/],
       precision => 5,
         convert => {xyY => [\&from_Yxy, \&to_Yxy]},
);
