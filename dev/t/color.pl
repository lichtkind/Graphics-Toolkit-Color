
use v5.12;
use Graphics::Toolkit::Color;

open my $FH, '>', 'color.txt';

my $cc = 0;
my $col = 0;
for my $name (Graphics::Toolkit::Color::Constant::all_names()){
    my @rgb = Graphics::Toolkit::Color::Constant::rgb_from_name( $name );
    my @hsl = Graphics::Toolkit::Color::Constant::hsl_from_name( $name );
    next if $hsl[2] < 65;
    next if $hsl[1] < 20 or $hsl[1] > 90;
    my $hex = Graphics::Toolkit::Color::Value::hex_from_rgb( @rgb );
    $cc++;
    print $FH qq/{"name": "$name", "color": "$hex"}, /;
    if ($col++ > 1){
        say $FH '';
        $col = 0;
    }
}
say "insert $cc colors";
