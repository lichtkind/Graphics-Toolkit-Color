
# store all clolor space objects, to convert check, convert and measure color values

package Graphics::Toolkit::Color::Space::Hub;
use v5.12;
use warnings;
use Carp;

#### internal API ######################################################

our $default_space_name = 'RGB';
my %space_obj;
add_space( require "Graphics/Toolkit/Color/Space/Instance/$_.pm" ) for $default_space_name,
                       qw/CMY CMYK HSL HSV HSB HWB NCol YIQ YUV/,   # missing: CubeHelix OKLAB
                       qw/CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/; # search order

sub default_space { $space_obj{ $default_space_name } }
sub get_space  { $space_obj{ uc $_[0] } if exists $space_obj{ uc $_[0] } }
sub is_space   { (defined $_[0] and ref get_space($_[0])) ? 1 : 0 }
sub space_names{ sort keys %space_obj }

#### space API #########################################################

sub add_space {
    my $space = shift;
    return 'got no Graphics::Toolkit::Color::Space object' unless ref $space eq 'Graphics::Toolkit::Color::Space';
    my $name = $space->name;
    return "space objct has no name" unless $name;
    return "color space name $name is already taken" if ref get_space( $name );
    my @converter_target = $space->converter_names;
    return "can not add clor space $name, it has no converter" unless @converter_target;
    for my $converter_target (@converter_target){
        return "space object $name does convert into $converter_target, which is no known color space"
            unless is_space( $converter_target );
    }
    $space_obj{ $name } = $space;
    $space_obj{ $space->alias } = $space if $space->alias and not ref get_space( $space->alias );
}

sub remove_space {
    my $name = shift;
    return "got no name as argument" unless defined $name and $name;
    my $space = get_space( $name );
    return "no known color space with name $name" unless ref $space;
    delete $space_obj{ $space->name };
    delete $space_obj{ $space->alias } if $space->alias;
}

sub check_space_name {
    return unless defined $_[0];
    my $error = "called with unknown color space name '$_[0]', please try one of: " . join (', ', space_names());
    is_space( $_[0] ) ? 0 : carp $error;
}
sub check_space_and_values {
    my ($space_name, $values, $sub_name) = @_;
    $space_name //= $default_space_name;
    check_space_name( $space_name ) and return;
    my $space = get_space($space_name);
    $space->is_value_tuple( $values ) ? $space
                                : 'need an ARRAY ref with '.$space->axis." $space_name values as first argument of $sub_name";
}

#### value API #########################################################

sub convert_to_default_form { # formatted color def --> normalized RGB values -- normalized original named value array
    my ($color_def) = @_;
    return 'got no dolor definition' unless defined $color_def;
    my ($values, $original_space_name) = deformat( $color_def );
    return 'could not deformat color definition: "$color_def"' unless ref $values;
    my $color_space = get_space( $original_space_name );
    $values = $color_space->normalize( $values );
    $values = $color_space->clamp( $values, 'normal');
    return $values if $original_space_name eq $default_space_name;
    my $original_values = [ $original_space_name, @$values ];
    my $current_space = $color_space;
    my $value_is_normal = 1;
    while (uc $current_space->name ne $default_space_name ){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        $values = $current_space->convert( $values, $next_space_name);
        $current_space = get_space( $next_space_name );
    }
    return $values, $original_values;
}

sub convert { # normalized RGB tuple, ~space_name -- normalized named original tuple
    my ($values, $space_name, $want_result_normalized, $source_values) = @_;
    return "need a value ARRAY and a space name to convert to" unless defined $space_name;
    my $target_space = get_space( $space_name );
    return "$space_name is an unknown color space, try: ".(join ', ', space_names()) unless ref $target_space;
    return "need an ARRAY ref with 3 RGB values as first argument in order to convert them"
        unless ref $values eq 'ARRAY' and @$values == 3;
    return $values if $space_name eq $default_space_name;
    $want_result_normalized //= 0;
    # $values = $origin_space->clamp( $values );
    # $values = $origin_space->normalize( $values );
    my $value_is_normal = 1;
    my $current_space = $target_space;
    my @convertchain = ($target_space->name);
    while ($current_space->name ne $default_space_name ){
        my ($next_space_name, @next_options) = $current_space->converter_names;
        $next_space_name = shift @next_options while @next_options and $next_space_name ne $default_space_name;
        push @convertchain, $next_space_name;
        $current_space = get_space( $next_space_name );
    }
    for my $next_space_name (@convertchain){
        if (ref $source_values eq 'ARRAY' and $source_values->[0] eq $current_space){
            $values = [@{$source_values}[1 .. $#$source_values]];
            $source_values = 0;
            $value_is_normal = 1;
        } else {
            $values = $current_space->deconvert( $values, $next_space_name);
        }
        $current_space = get_space( $next_space_name );
    }
    $values = $target_space->normalize( $values ) if not $value_is_normal and $want_result_normalized;
    $values = $target_space->denormalize( $values ) if $value_is_normal and not $want_result_normalized;
    return $values;
}

sub deformat { # convert from any format into list of values of any space
    my ($formated_values) = @_;
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my @val = $color_space->deformat( $formated_values );
        return \@val, $space_name if defined $val[0];
    }
}

sub partial_hash_deformat { # convert partial hash into
    my ($value_hash) = @_;
    return unless ref $value_hash eq 'HASH';
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my $pos_hash = $color_space->basis->deformat_partial_hash( $value_hash );
        next unless ref $pos_hash eq 'HASH';
        return wantarray ? ($pos_hash, $color_space->name) : $pos_hash;
    }
    return undef;
}

1;

__END__


sub read { # formatted color values --> tuple
    my ($color, $range, $precision, $suffix) = @_;
    for my $space_name (space_names()) {
        my $color_space = get_space( $space_name );
        my @res = $color_space->read( $color, $range, $precision, $suffix );
        next unless @res;
        return wantarray ? ($res[0], $color_space->name, $res[1]) : $res[0];
    }
    return undef;
}

sub write { # tuple --> formatted color values
    my ($color, $space_name, $format_name, $range, $precision, $suffix) = @_;
    my $color_space = get_space( $space_name );
    return unless ref $color_space;
    $color_space->write( $color, $format_name, $range, $precision, $suffix );
}

sub format { # @tuple --> % | % |~ ...
    my ($values, $space_name, $format_name) = @_;

    my $space = check_space_and_values(  $space_name, $values, 'format' );
    return unless ref $space;
    my @values = $space->format( $values, $format_name // 'list' );
    return @values, carp "got unknown format name: '$format_name'" unless defined $values[0];
    return @values == 1 ? $values[0] : @values;
}

sub denormalize { # result clamped, alway in space
    my ($values, $space_name, $range) = @_;
    my $space = check_space_and_values( $space_name, $values,'denormalize' );
    return unless ref $space;
    $values = $space->clamp($values, 'normal');
    $space->denormalize( $values, $range);
}

sub normalize {
    my ($values, $space_name, $range) = @_;
    my $space = check_space_and_values( $space_name, $values, 'normalize' );
    return unless ref $space;
    $values = $space->clamp($values, $range);
    return $values unless ref $values;
    $space->normalize( $values, $range);
}
