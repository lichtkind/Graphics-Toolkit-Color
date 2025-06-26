
# stor of valus from a single color in RGB, original and name

package Graphics::Toolkit::Color::Values;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Name;
use Graphics::Toolkit::Color::Space::Hub;

my $RGB = Graphics::Toolkit::Color::Space::Hub::default_space();

sub new_from_any_input { #  values => %space_name => tuple ,   ~origin_space, ~color_name
    my ($pkg, $color_def) = @_;
    if (not ref $color_def){
        my $rgb = Graphics::Toolkit::Color::Name::rgb_from_name( $color_def );
        return bless { name => $color_def, rgb => $RGB->normalize( $rgb ), source => '', source_space => ''} if ref $rgb;
    }
    my ($values, $source_space, $source) = Graphics::Toolkit::Color::Space::Hub::convert_to_default_form( $color_def );
    return "could not recognize color value format or color name: $color_def" unless ref $values;
    my $name = Graphics::Toolkit::Color::Name::name_from_rgb( $RGB->denormalize( $values ) );
    bless { name => $name, rgb => $values, source => $source, source_space => $source_space};
}
sub new_from_normal_tuple {
    my ($pkg, $values) = @_;
    #return 'need a normalized (0..1) RGB tuple' unless $RGB->range_check( $values, 'normal' );
    $values = $RGB->clamp( $values, 'normal' );
    my $name = Graphics::Toolkit::Color::Name::name_from_rgb( $RGB->denormalize( $values ) );
    bless { name => $name, rgb => $values, source => '', source_space => ''};   
}

########################################################################
sub get_name { $_[0]->{'name'} }
sub get_normal_tuple {
    my ($self, $space_name) = @_;
    Graphics::Toolkit::Color::Space::Hub::convert(
        $self->{'rgb'}, $space_name, 1, $self->{'source_space'}, $self->{'source'},
    );
}
sub get_formatted { # get a value tuple in any color space, range and format
    my ($self, $space_name, $format_name, $range_def) = @_;
    $space_name //= Graphics::Toolkit::Color::Space::Hub::default_space_name();
    my $color_space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    return "can not format values in unknown space name: $space_name" unless ref $color_space;
    my $values = Graphics::Toolkit::Color::Space::Hub::convert (
        $self->{'rgb'}, $space_name, defined $range_def, $self->{'source_space'}, $self->{'source'},
    );
    return $values unless ref $values;
    $values = $color_space->denormalize( $values, $range_def );
    $values = $color_space->format( $values, $format_name ) if defined $format_name;
    return $values;
}

########################################################################

sub set { # %val --> _
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $val_hash );
    return 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my $values = $self->get_formatted( $space_name );
    for my $pos (keys %$pos_hash){
        $values->[$pos] = $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @$values]);
}

sub add { # %val --> _
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash( $val_hash );
    return 'key names: '.join(', ', keys %$val_hash). ' do not correlate to any supported color space' unless defined $space_name;
    my $values = $self->get_formatted( $space_name );
    for my $pos (keys %$pos_hash){
        $values->[$pos] += $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @$values]);
}

sub blend { # cv2 -- +percent, ~space --> _
    my ($self, $c2, $percent, $space_name ) = @_;
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $percent //= 50;
    $space_name //= 'RGB';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my @values1 = $self->get( $space_name );
    my @values2 = $c2->get( $space_name );
    my @rvalues = map { ((100 - $percent) * $values1[$_]) + ($percent * $values2[$_]) } 0 .. $#values1;
    __PACKAGE__->new([$space_name, @rvalues]);
}

sub distance { # _c1 _c2 -- ~space ~select @range --> +
    my ($self, $cv2, $space_name, $select, $range) = @_;
    return "need value object as second argument" unless ref $cv2 eq __PACKAGE__;
    return "$space_name is not a color space name" if defined $space_name and not Graphics::Toolkit::Color::Space::is_space($space_name);
    Graphics::Toolkit::Color::Space::Hub::distance( $self->{'rgb'}, $cv2->{'rgb'}, $space_name, $select, $range);
}

1;

