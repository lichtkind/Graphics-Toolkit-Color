use v5.12;
use warnings;

# value objects with cache of original values

package Graphics::Toolkit::Color::Values;
use Graphics::Toolkit::Color::Space::Hub;
use Carp;

sub new {
    my ($pkg, $color_val) = @_;
    my ($values, $space_name) = Graphics::Toolkit::Color::Space::Hub::deformat( $color_val );
    return carp "could not recognize color values" unless ref $values;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my $std_space = Graphics::Toolkit::Color::Space::Hub::base_space();
    my $self = {};
    $self->{'origin'} = $space->name;
    $values = [$space->clamp( $values )];
    $values = [$space->normalize( $values )];
    $self->{$space->name} = $values;
    $self->{$std_space->name} = [$space->convert($values, $std_space->name)] if $space ne $std_space;
    bless $self;
}

sub get { # get a value tuple in any color space, range and format
    my ($self, $space_name, $format_name, $range_def) = @_;
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my $std_space_name = $Graphics::Toolkit::Color::Space::Hub::base_package;
    $space_name //= $std_space_name;
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my $values = (exists $self->{$space->name})
               ? $self->{$space->name}
               : [$space->deconvert( $self->{$std_space_name}, $std_space_name)];
    $values = [ $space->denormalize( $values, $range_def) ];
    Graphics::Toolkit::Color::Space::Hub::format( $values, $space_name, $format_name);
}
sub string { $_[0]->get( $_[0]->{'origin'}, 'string' ) }

########################################################################

sub set {
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $val_hash );
    return carp 'key names: '.join(', ', keys %$val_hash). 'no not correlate to any supported color space' unless defined $space_name;
    my @values = $self->get( $space_name );
    for my $pos (keys %$pos_hash){
        $values[$pos] = $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @values]);
}

sub add {
    my ($self, $val_hash) = @_;
    my ($pos_hash, $space_name) = Graphics::Toolkit::Color::Space::Hub::partial_hash_deformat( $val_hash );
    return carp 'key names: '.join(', ', keys %$val_hash). 'no not correlate to any supported color space' unless defined $space_name;
    my @values = $self->get( $space_name );
    for my $pos (keys %$pos_hash){
        $values[$pos] += $pos_hash->{ $pos };
    }
    __PACKAGE__->new([$space_name, @values]);
}

sub blend {
    my ($self, $c2, $factor, $space_name ) = @_;
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $factor //= 0.5;
    $space_name //= 'HSL';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my @values1 = $self->get( $space_name );
    my @values2 = $c2->get( $space_name );
    my @rvalues = map { ((1-$factor) * $values1[$_]) + ($factor * $values2[$_]) } 0 .. $#values1;
    __PACKAGE__->new([$space_name, @rvalues]);
}

########################################################################

sub distance {
    my ($self, $c2, $space_name, $metric, $range) = @_;
    return carp "need value object as second argument" unless ref $c2 eq __PACKAGE__;
    $space_name //= 'HSL';
    Graphics::Toolkit::Color::Space::Hub::check_space_name( $space_name ) and return;
    my @values1 = $self->get( $space_name, 'list', 'normal' );
    my @values2 = $c2->get( $space_name, 'list', 'normal' );
    return unless defined $values1[0] and defined $values2[0];
    my $space = Graphics::Toolkit::Color::Space::Hub::get_space( $space_name );
    my @delta = $space->delta( \@values1, \@values2 );
    @delta = $space->denormalize( \@delta, $range);
    return unless defined $delta[0] and @delta == $space->dimensions;

    if (defined $metric and $metric){ # individual metric / subspace distance
        my @components = split( '', $metric );
        my $pos = $space->basis->key_pos( $metric );
        @components = defined( $pos )
                    ? ($pos)
                    : (map  { $space->basis->shortcut_pos($_) }
                       grep { defined $space->basis->shortcut_pos($_) } @components);
        return - carp "called 'distance' for metric $metric that does not fit color space $space_name!" unless @components;
        @delta = map { $delta [$_] } @components;
    }
    # Euclidean distance:
    @delta = map {$_ * $_} @delta;
    my $d = 0;
    for (@delta) {$d += $_}
    return sqrt $d;
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Value - single color related high level methods

=head1 SYNOPSIS

Readonly object that holds values of a color and provides all the methods
to get or measure them or produce one related color values object.

for all color value related math. Can handle vectors of all
spaces mentioned in next paragraph and translates also into and from
different formats such as I<RGB> I<hex> ('#AABBCC').

    use Graphics::Toolkit::Color::Value;

    my $blue = Graphics::Toolkit::Color::Value->new( 'hsl(220,50,60)' );
    my @rgb = $blue->get();
    my $purple = $blue->set({red => 220});


=head1 DESCRIPTION

The object that holds the normalized original values of the color
definition and the normalized RGB tripled if it was not defined by RGB
values. This way we omit conversion and rounding errors.

This package is a mediation layer between C<Graphics::Toolkit::Color::Space::Hub>
below, where its just about number crunching of value vectors and the user
API above in C<Graphics::Toolkit::Color> where it's mainly about producing
sets of colors.

=head1 METHODS

=head2 new

=head2 get

=head2 set

=head2 add

=head2 blend

=head2 distance

Converts a value tuple (vector) of any space above into the base space (RGB).
Takes two arguments the vector (array of numbers) and name of the source space.
The result is also a vector in for of a list. The result values will
clamped (changed into acceptable range) to be valid inside the target
color space.


    my @rgb = G.::T.::C.::Value::deconvert( [220, 50, 70], 'HSL' ); # convert from HSL to RGB

=head2 convert

Converts a value vector from base space (RGB) into any space above.
Takes two arguments the vector (array of numbers) and name of the target space.
The result is also a vector in for of a list. The result values will
clamped (changed) to be valid inside the target color space.

    my @hsl = G.::T.::C.::Value::convert( [20, 50, 70], 'HSL' );    # convert from RGB to HSL

=head2 deformat

Transfers values from many formats into a vector (array of numbers - first
return value). The second return value is the name of a color space which
supported this format. All spaces support the following format names:
I<hash>, I<char_hash> and the names and shortcuts of the vector names.
Additonal formats are implemented by the Graphics::Toolkit::Color::Value::*
modules. The values themself will not be changed, even if they are outside
the boundaries of the color space.

    # get [170, 187, 204], 'RGB'
    my ($rgb, $space) = G.::T.::C.::Value::deformat( '#aabbcc' );
    # get [12, 34, 54], 'HSL'
    my ($hsl, $s) = G.::T.::C.::Value::deformat( { h => 12, s => 34, l => 54 } );


=head2 format

Reverse function of I<deformat>.

    # get { h => 12, s => 34, l => 54 }
    my $h = G.::T.::C.::Value::format( [12, 34, 54], 'HSL', 'char_hash' );
    # get { hue => 12, saturation => 34, lightness => 54 }
    my $h = G.::T.::C.::Value::format( [12, 34, 54], 'HSL', 'hash' );
    # '#AABBCC'
    my $str = G.::T.::C.::Value::format( [170, 187, 204], 'RGB', 'hex' );


=head2 distance

Computes a real number which designates the distance between two points
in any color space above. The first two arguments are the two point vectors.
Third (optional) argument is the name of the color space, which defaults
to the base space (RGB).

    my $d = distance([1,1,1], [2,2,2], 'RGB');  # approx 1.7
    my $d = distance([1,1,1], [356, 3, 2], 'HSL'); # approx 6


=head1 SEE ALSO

=over 4

=item *

L<Convert::Color>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
