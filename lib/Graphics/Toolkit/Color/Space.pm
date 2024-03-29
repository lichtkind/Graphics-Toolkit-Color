use v5.12;
use warnings;

# common code of Graphics::Toolkit::Color::Space::Instance::*

package Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Basis;
use Graphics::Toolkit::Color::Space::Shape;

sub new {
    my $pkg = shift;
    my %args = @_;
    my $basis = Graphics::Toolkit::Color::Space::Basis->new( $args{'axis'}, $args{'short'}, $args{'prefix'} );
    return unless ref $basis;
    my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, $args{'range'}, $args{'type'} );
    return unless ref $shape;

    # which formats the constructor will accept, that can be deconverted into list
    my %deformats = ( hash => sub { $basis->list_from_hash(@_)   if $basis->is_hash(@_) },
               named_array => sub { @{$_[0]}[1 .. $#{$_[0]}]     if $basis->is_named_array(@_) },
                    string => sub { $basis->list_from_string(@_) if $basis->is_string(@_) },
                css_string => sub { $basis->list_from_css(@_)    if $basis->is_css_string(@_) },
    );
    # which formats we can output
    my %formats = (list => sub { @_ },                                 #   1, 2, 3
                   hash => sub { $basis->key_hash_from_list(@_) },     # { red => 1, green => 2, blue => 3 }
              char_hash => sub { $basis->shortcut_hash_from_list(@_) },# { r =>1, g => 2, b => 3 }
                  array => sub { $basis->named_array_from_list(@_) },  # ['rgb',1,2,3]
                 string => sub { $basis->named_string_from_list(@_) }, #  'rgb: 1, 2, 3'
             css_string => sub { $basis->css_string_from_list(@_) },   #  'rgb(1,2,3)'
    );

    bless { basis => $basis, shape => $shape, format => \%formats, deformat => \%deformats, convert => {} };
}
sub basis            { $_[0]{'basis'}}
sub name             { $_[0]->basis->name }
sub dimensions       { $_[0]->basis->count }
sub is_array         { $_[0]->basis->is_array( $_[1] ) }
sub is_partial_hash  { $_[0]->basis->is_partial_hash( $_[1] ) }
sub has_format       { (defined $_[1] and exists $_[0]{'format'}{ lc $_[1] }) ? 1 : 0 }
sub can_convert      { (defined $_[1] and exists $_[0]{'convert'}{ uc $_[1] }) ? 1 : 0 }

########################################################################

sub delta             { shift->{'shape'}->delta( @_ ) }      # @values -- @vector, @vector --> |@vector # on normalize values
sub check             { shift->{'shape'}->check( @_ ) }      # @values -- @range           -->  ?       # pos if carp
sub clamp             { shift->{'shape'}->clamp( @_ ) }      # @values -- @range           --> |@vector
sub normalize         { shift->{'shape'}->normalize(@_)}     # @values -- @range           --> |@vector
sub denormalize       { shift->{'shape'}->denormalize(@_)}   # @values -- @range           --> |@vector
sub denormalize_range { shift->{'shape'}->denormalize_range(@_)}#@values -- @range         --> |@vector

########################################################################

sub add_formatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or ref $code ne 'CODE';
    return 0 if $self->has_format( $format );
    $self->{'format'}{ $format } = $code;
}
sub format {
    my ($self, $values, $format) = @_;
    return unless $self->basis->is_array( $values );
    $self->{'format'}{ lc $format }->(@$values) if $self->has_format( $format );
}

sub add_deformatter {
    my ($self, $format, $code) = @_;
    return 0 if not defined $format or ref $format or exists $self->{'deformat'}{$format} or ref $code ne 'CODE';
    $self->{'deformat'}{ lc $format } = $code;
}
sub deformat {
    my ($self, $values) = @_;
    return undef unless defined $values;
    for my $deformatter (values %{$self->{'deformat'}}){
        my @values = $deformatter->($values);
        return @values if @values == $self->dimensions;
    }
    return undef;
}

########################################################################

sub add_converter {
    my ($self, $space_name, $to_code, $from_code, $mode) = @_;
    return 0 if not defined $space_name or ref $space_name or ref $from_code ne 'CODE' or ref $to_code ne 'CODE';
    return 0 if $self->can_convert( $space_name );
    $self->{'convert'}{ uc $space_name } = { from => $from_code, to => $to_code, mode => $mode };
}
sub convert {
    my ($self, $values, $space_name) = @_;
    return unless $self->{'basis'}->is_array( $values ) and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'to'}->(@$values) if $self->can_convert( $space_name );
}

sub deconvert {
    my ($self, $values, $space_name) = @_;
    return unless ref $values eq 'ARRAY' and defined $space_name;
    $self->{'convert'}{ uc $space_name }{'from'}->(@$values) if $self->can_convert( $space_name );
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
                                                   prefix => 'demo',
                                                    range => [1, [-2, 2], [-3, 3]],
                                                     type => [qw/linear linear angular/]);

    $def->add_converter('RGB', \&to_rgb, \&from_rgb );
    $def->add_formatter(   'name',   sub {...} );
    $def->add_deformatter( 'name',   sub {...} );


=head1 DESCRIPTION

This package provides the API for color space authors.
The module is supposed to be used by L<Graphics::Toolkit::Color::Space::Hub>
and L<Graphics::Toolkit::Color::Values> and not directly, thus it exports
no symbols and has a much less DWIM API then the main module.

=head1 METHODS

=head2 new

The constructor takes five named arguments. Only I<axis>, which takes
an ARRAY ref with the names of the axis, is required. The first letter
of each axis name becomes the name shortcut for each axis, unless
separate shortcut names are provided under the named argument I<short>.
The name of a color space is derived from the combined axis shortcuts.
If that would lead to an already taken name, you can provide an additional
I<prefix>, which will pasted in front of the space name.

Under the argument I<range> you can set the limits of each dimension.
If none are provided, normal ranges (0 .. 1) are assumed. One number
is understood as the upper limit of all dimensions and the lower bound
being zero. An ARRAY ref with two number set the lower and upper bound of
each dimension, but you can also provide an ARRAY ref filled with numbers
or ARRAY ref defining the bounds for each dimension. If no argument under
the name L<type> is provided, then all dimensions will be I<linear> (Euclidean).
But you might want to change that for some to I<circular> or I<angular>
which both means that this dimension is not measured in length but
with an angle from the origin.

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

Copyright 2023 Herbert Breunung.

This program is free software; you can redistribute it and/or modify it
under same terms as Perl itself.

=head1 AUTHOR

Herbert Breunung, <lichtkind@cpan.org>

=cut
