
# HSB color space specific code , alias for HSV

package Graphics::Toolkit::Color::Space::Instance::HSB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

sub pass {
    my ($values) = @_;
    return ([@$values]);
}

Graphics::Toolkit::Color::Space->new (
          family => 'HSV',
            axis => [qw/hue saturation brightness/],
            role => [qw/hue saturation value/],
           range => [360, 100, 100],
       precision => 0,
            type => [qw/angular linear linear/],
          suffix => ['', '%', '%'],
      constraint => {cone => {checker => '$_[0][1] <= $_[0][2]',
                             error    => 'Saturation can not be greater than Value',
		                     remedy   => '[$_[0][0], $_[0][2], $_[0][2]]', }},
         convert => {HSV => [\&pass, \&pass]},
);
