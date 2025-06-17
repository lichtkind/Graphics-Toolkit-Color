
# common code of Graphics::Toolkit::Color::Space::Instance::* packages

package Graphics::Toolkit::Color::Space;
use v5.12;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Shape;
use Graphics::Toolkit::Color::Space::Format;
use Graphics::Toolkit::Color::Space::Util qw/:all/;
our @EXPORT_OK = qw/round_int round_decimals rmod min max apply_d65 remove_d65 mult_matrix3 close_enough is_nr/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


sub new {
    my $pkg = shift;
    my %args = @_;
    my $basis = Graphics::Toolkit::Color::Space::Basis->new( $args{'axis'}, $args{'short'}, $args{'prefix'}, $args{'name'}, $args{'alias'});
    return $basis unless ref $basis;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, $args{'type'}, $args{'range'}, $args{'precision'} );
    return $shape unless ref $shape;
    my $format = Graphics::Toolkit::Color::Space::Format->new( $basis, $args{'suffix'}, $args{'value_form'} );
    return $format unless ref $format;
    bless { basis => $basis, shape => $shape, format => $format, convert => {} };
}

########################################################################

sub basis              { $_[0]{'basis'} }
sub name               { shift->basis->space_name }           #          --> ~
sub alias              { shift->basis->alias_name }           #          --> ~
sub axis               { shift->basis->axis_count }           #          --> +
sub is_value_tuple     { shift->basis->is_value_tuple(@_) }   # @+values --> ?
sub is_partial_hash    { shift->basis->is_partial_hash(@_) }  # %+values --> ?

########################################################################

sub shape              { $_[0]{'shape'} }
sub range_check        { shift->shape->in_range( @_ ) }       # @+values -- @+range, @+precision   --> @+values|!~   # errmsg
sub clamp              { shift->shape->clamp( @_ ) }          # @+values -- @+range, @+precision   --> @+rvals       # result values
sub round              { shift->shape->round( @_ ) }          # @+values -- @+precision            --> @+rvals       # result values
sub normalize          { shift->shape->normalize(@_)}         # @+values -- @+range                --> @+rvals|!~
sub denormalize        { shift->shape->denormalize(@_)}       # @+values -- @+range, @+precision   --> @+rvals|!~
sub denormalize_delta  { shift->shape->denormalize_delta(@_)} # @+values -- @+range                --> @+rvals|!~
sub delta              { shift->shape->delta( @_ ) }          # @+values1, @+values2               --> @+rvals|      # on normalized values

########################################################################

sub form               { $_[0]{'format'} }
sub format             { shift->form->format(@_) }            # @+values, ~format_name -- @~suffix --> $*color
sub deformat           { shift->form->deformat(@_) }          # $*color                -- @~suffix --> @+values, ~format_name
sub has_format         { shift->form->has_format(@_) }        # ~format_name                       --> ?
sub has_deformat       { shift->form->has_deformat(@_) }      # ~format_name                       --> ?
sub add_formatter      { shift->form->add_formatter(@_) }     # ~format_name, &formatter           --> &?
sub add_deformatter    { shift->form->add_deformatter(@_) }   # ~format_name, &deformatter         --> &?
sub set_value_formatter{ shift->form->set_value_formatter(@_)}# &pre_formatter, &post_formatter    --> &?

#### conversion ########################################################

sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }
sub add_converter {
    my ($self, $space_name, $to_code, $from_code, $normalize) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    return 0 if defined $normalize and ref $normalize ne 'HASH';
    $normalize = { from => 1, to => 1, } unless ref $normalize; # default is full normalisation
    $normalize->{'from'} = {} if not exists $normalize->{'from'}
                                 or (exists $normalize->{'from'} and not $normalize->{'from'});
    $normalize->{'from'} = {in => 1, out => 1} if not ref $normalize->{'from'};
    $normalize->{'from'}{'in'} = 0 unless exists $normalize->{'from'}{'in'};
    $normalize->{'from'}{'out'} = 0 unless exists $normalize->{'from'}{'out'};
    $normalize->{'to'} = {} if not exists $normalize->{'to'}
                               or (exists $normalize->{'to'} and not $normalize->{'to'});
    $normalize->{'to'} = {in => 1, out => 1} if not ref $normalize->{'to'};
    $normalize->{'to'}{'in'} = 0 unless exists $normalize->{'to'}{'in'};
    $normalize->{'to'}{'out'} = 0 unless exists $normalize->{'to'}{'out'};
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code, normalize => $normalize };
}

sub convert {
    my ($self, $values, $space_name) = @_;
    return unless $self->is_value_tuple( $values ) and defined $space_name and $self->can_convert( $space_name );
    return [$self->{'convert'}{ uc $space_name }{'to'}->( $values )];
}
sub deconvert {
    my ($self, $values, $space_name) = @_;
    return unless ref $values eq 'ARRAY' and defined $space_name and $self->can_convert( $space_name );
    return [ $self->{'convert'}{ uc $space_name }{'from'}->( $values ) ];
}

#### full pipe IO ops ##################################################

sub read { # formatted color blob in local space --> normalized RGB
    my ($self, $color, $range, $precision, $suffix) = @_;
    my ($values, $format_name) = $self->deformat( $color, $suffix);
    $values = $self->round( $values, $precision) if defined $precision;
    $values = $self->normalize( $values, $range);
    $values = $self->convert( $values, 'RGB');
    return (not ref $values) ? $values :
                   wantarray ? ($values, $format_name) : $values;
}

sub write { # normalized @RGB --> formatted color in local space
    my ($self, $values, $format_name, $range, $precision, $suffix) = @_;
    $values = $self->deconvert( $values, 'RGB');
    $values = $self->denormalize( $values, $range);
    $values = $self->round( $values, $precision);
    $self->format( $values, $format_name, $suffix);
}


1;

__END__

=pod

=head1 NAME

Graphics::Toolkit::Color::Space - base class of all color spaces

=head1 SYNOPSIS

Color spaces are objects that hold all detail information of a color space.
Among these are its name, alias, count, length and type of axis.
The conversion and formatting algorithms are also located here,
but provided by the instances.

    use Graphics::Toolkit::Color::Space;

    my $def = Graphics::Toolkit::Color::Space->new (
                      prefix => 'pre',
                        name => 'demo',
                       alias => 'alias',
                        axis => [qw/one two three/],
                       short => [qw/1 2 3/],
                        type => [qw/linear circular angular/]
                       range => [1, [-2, 2], [-3, 3]],
                   precision => [-1, 0, 1],
                      suffix => ['', '', '%'],
    );

    $def->add_converter(    'RGB',   \&to_rgb, \&from_rgb );
    $def->add_formatter(   'name',   sub {...} );
    $def->add_deformatter( 'name',   sub {...} );


=head1 DESCRIPTION

This package provides the API for constructing custom color spaces.
Please name them L<Graphics::Toolkit::Color::Space::Instance::MyName>.
These instances are supposed to be loaded by L<Graphics::Toolkit::Color::Space::Hub>.
So if you are an author of your own color space, you have to call C<*::Hub::add_space>
manually at runtime or submit you color space as merge request and I add
your space into the list of automatically loaded spaces.

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
