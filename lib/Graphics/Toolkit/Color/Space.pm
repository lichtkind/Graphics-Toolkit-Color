use v5.12;
use warnings;

# common code of Graphics::Toolkit::Color::Space::Instance::* packages

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Shape;

sub new {
    my $pkg = shift;
    my %args = @_;
    my $basis = Graphics::Toolkit::Color::Space::Basis->new( $args{'axis'}, $args{'short'}, $args{'prefix'}, $args{'name'});
    return $basis unless ref $basis;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, $args{'type'}, $args{'range'}, $args{'precision'} );
    return $shape unless ref $shape;
    my $format = Graphics::Toolkit::Color::Space::Format->new( $basis, $shape, $args{'suffix'} );
    return $format unless ref $format;
    bless { basis => $basis, shape => $shape, format => $format, convert => {} };
}

########################################################################

sub basis            { $_[0]{'basis'} }
sub name             { $_[0]->basis->space_name }
sub dimensions       { $_[0]->basis->count }
sub is_value_tuple   { $_[0]->basis->is_value_tuple( $_[1] ) }

########################################################################

sub shape             { $_[0]{'shape'} }
sub in_range          { shift->shape->in_range( @_ ) }       # @values -- @range           --> |!~      # errmsg
sub clamp             { shift->shape->clamp( @_ ) }          # @values -- @range           --> |@vector
sub normalize         { shift->shape->normalize(@_)}         # @values -- @range           --> |@vector
sub denormalize       { shift->shape->denormalize(@_)}       # @values -- @range           --> |@vector
sub denormalize_delta { shift->shape->denormalize_delta(@_)} # @values -- @range           --> |@vector
sub delta             { shift->shape->delta( @_ ) }          # @values -- @vector, @vector --> |@vector # on normalize values

########################################################################

sub format            { $_[0]{'format'} }
sub add_formatter     { shift->format->add_formatter(@_) }
sub add_deformatter   { shift->format->add_deformatter(@_) }
sub format            { shift->format->format(@_) }
sub deformat          { shift->format->deformat(@_) }

#### conversion ########################################################

sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }

sub add_converter {
    my ($self, $space_name, $to_code, $from_code, $mode) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code, mode => $mode };
}

sub convert {
    my ($self, $values, $space_name) = @_;
    return unless $self->{'basis'}->is_array( $values ) and defined $space_name and $self->can_convert( $space_name );
    return [$self->{'convert'}{ uc $space_name }{'to'}->(@$values)];
}
sub deconvert {
    my ($self, $values, $space_name) = @_;
    return unless ref $values eq 'ARRAY' and defined $space_name and $self->can_convert( $space_name );
    return [ $self->{'convert'}{ uc $space_name }{'from'}->(@$values) ];
}

1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space - color space constructor

=head1 SYNOPSIS

Color spaces are objects( instances ) of this class, who provide property
details via the constructor and formatter and converters via CODE ref.

    use Graphics::Toolkit::Color::Space;

    my  $def = Graphics::Toolkit::Color::Space->new( axis => [qw/one two three/],
                                                    short => [qw/1 2 3/],
                                                   prefix => 'pre',
                                                     name => 'demo'
                                                     type => [qw/linear circular angular/]
                                                    range => [1, [-2, 2], [-3, 3]],
                                                precision => [-1, 0, 1],
                                                   suffix => ['', '', '%'],
                                                     );

    $def->add_converter(    'RGB',   \&to_rgb, \&from_rgb );
    $def->add_formatter(   'name',   sub {...} );
    $def->add_deformatter( 'name',   sub {...} );


=head1 DESCRIPTION

This package provides the API for constructing color spaces, which are instances
of this class. Plase name them L<Graphics::Toolkit::Color::Space::Instance::*>.
These instances are supposed to be held by L<Graphics::Toolkit::Color::Space::Hub>.
So if you are an author of your own color space, you have to send it to the Hub
manually at runtime or submit you color space as merge request.

=head1 METHODS

=head2 new

The constructor takes eight named arguments, of which only I<axis> is required.
The values of these arguments have to be in most cases an ARRAY references,
which have one element for each axis of this space. Sometimes are also strings
acceptable, either because the target value of tha argument is an scalar
(I<name> and I<prefix>) or bcause a scalar is interpreted as the value to be set
for all axis (dimensions).

The argument B<axis> defines the full names of all axis, which will set also the
numbers of dimensions of this space. Each axis will have also a shortcut name,
which is per default the first letter of the full name. If you prefer other
shortcuts, define them via the B<short> argument.

The upper-cased concatination of all shortcut names (in the order as presented
by the I<axis> argument) is the default name if this color space.
That can be changed via the B<name> argument or extended (prepended) via B<prefix>.
Both I<name> and I<prefix> expext an string input.

If no argument under the name B<type> is provided, then all dimensions will be
I<linear> (Euclidean). But you might want to change that for some axis to be
I<circular> or it's alias I<angular>. This will influenc how the methods I<clamp>
ans I<delta> work. A third option for the I<type> argument is I<no>, which
indicates that you can not treat the values of this dimension as numbers.

Under the argument B<range> you can set the numeric limits of each dimension.
If none are provided, normal ranges (0 .. 1) are assumed. One number
is understood as the upper limit of all dimensions and the lower bound
being zero. An ARRAY ref with two number set the lower and upper bound of
each dimension, but you can also provide an ARRAY ref filled with numbers
or ARRAY ref defining the bounds for each dimension. You can also use
the string I<'normal'> to indicate normal ranges (0 .. 1).

The argument B<precision> defines how many decimals a value of that dimension
has to have. Zero makes the values practically an integer and negative values
express the demand for the maximally available precision. The default precision
is -1, except when min and max value of the range are int. Then the default
precision will be zero as well - except for normal ranges. With them the default
precision is again -1.

The argument B<suffix> is only interesting if color values has to have a suffix
like I<'%'> in '63%'. Its defaults to the empty string.

=head2 add_converter

Takes three arguments:

1. A name of a space the values will be converter from and to
(usually just 'RGB').

2. & 3. Two CODE refs of the actual converter methods, which have to take
the normalized values as a list and return normalized values as a list.
The first CODE converts to the named (by first argument) space and
the second from the named into the name space the objects implements.

=head2 add_formatter

Takes two arguments: name of the format and CODE ref that takes the
denormalized values as a list and returns whatever the formatter wishes
to provide, which then the GTC method I<values> can provide.

=head2 add_deformatter

Same as I<add_formatter> but the CODE does here the opposite transformation,
providing a format reading ability for the GTC constructor.


=head1 COPYRIGHT & LICENSE

Copyright 2023-24 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
