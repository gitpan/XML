package XML2::Element;

=pod 

=head1 NAME

XML2::Element - XML Element level control

=head1 DISCRIPTION

Element base class represents an element at the XML level.
More specific element classes control the xml functionality
which is abstracted from the xml.

=head1 AUTHOR

Martin Owens <doctormo@cpan.org> (Fork)
Ronan Oger <ronan@roasp.com> 

=head1 SEE ALSO

perl(1),L<XML2>,L<XML2::Parser>

=cut

$VERSION = "1.00";

use base "XML2::DOM::Element";
use strict;
use Carp;

use XML2::Attribute;
use XML2::Element::CDATA;

sub new
{
    my ($proto, $name, %opts) = @_;
	my $class = ref($proto) || $proto;

	my $self = bless \%opts, $class;
    $self->{'name'} = $name;

    return $self;
}

=head2 xmlify

Returns the element and all it's sub elements as a
serialised xml string

my $xml = $element->xmlify;

=cut
sub xmlify
{
	my ($self, %p) = @_;
	my ($ns, $indent, $level, $sep) = @p{qw/namespace indent level seperator/};

	$indent = '  ' if not $indent;
	$level = 0 if not $level;

	my $xml = $sep;

	$xml .= $indent x $level;

	if($self->hasChildren or $self->hasCDATA) {
		$xml .= $self->_serialise_open_tag($ns);
		if($self->hasChildren) {
			foreach my $child ($self->getChildren) {
				$xml .= $child->xmlify(
						indent    => $indent,
						level     => $level+1,
						seperator => $sep,
						);
			}
			$xml .= $sep.($indent x $level);
		} else {
			$xml .= $self->cdata->text;
		}
		$xml .= $self->_serialise_close_tag();
	} else {
		$xml .= $self->_serialise_tag();
	}
	return $xml;
}

=head2 getElementByXPath

Returns an element by XPath normal XPath rules apply. 

=cut
sub getElementByXPath
{
	my ($self, $path) = @_;
	# Remove double directories, prevents repathing to root
	$path =~ s/\/\//\// if not ref($path);
	# Aquire Next steps in Path
	my @path = ref($path) ? @{$path} : split(/\//, $path);
	return if not @path;
	my $this = shift @path;
	my $next;
	if($this eq '') {
		$next = $self->document->documentElement;
	} elsif($this eq '..') {
		$next = $self->getParent;
	} elsif($this eq '.') {
		$next = $self;
	} else {
		$next = $self->getChildrenByName( $this );
	}
	return $next if not @path;
	return $next->getElementByXPath( \@path );
}

=head2 _attribute_handle

Inherited method, returns attribute as new object or undef.

$attribute = $element->_attribute_handle( $attribute_name, $ns );

Used by XML2::DOM for auto attribute object handlers.

=cut
sub _attribute_handle
{
	my ($self, $name, %opts) = @_;
	return XML2::Attribute->new( name => $name, owner => $self, %opts );
}

=head2 _has_attribute

Inherited method, returns true if attribute has an object.

Used by XML2::DOM for auto attribute object handlers.

=cut
sub _has_attribute { 1 }

=head2 _can_contain_elements

Inherited method, returns true if the element can contain sub elements

=cut
sub _can_contain_elements { 1 }


=head2 _can_contain_attributes

Inherited method, returns true if the element can have attributes.

=cut
sub _can_contain_attributes { 1 }

=head2 _serialise_open_tag

XML ELement serialisation, Open Tag.

=cut
sub _serialise_open_tag
{
	my ($self) = @_;
	my $name = $self->name;
	my $at=' '.$self->_serialise_attributes if $self->hasAttributes;
	return "<$name$at>";
}

=head2 _serialise_tag

XML ELement serialisation, Self contained tag.

=cut
sub _serialise_tag
{
	my ($self) = @_;
	my $name = $self->name;
	my $at= $self->hasAttributes ? ' '.$self->_serialise_attributes : '';
	return "<$name$at \/>";
}

=head2 _serialise_close_tag

XML ELement serialisation, Close Tag.

=cut
sub _serialise_close_tag
{
	my ($self) = @_;
	my $name = $self->name;
	return "</$name>";
}

=head2 _serialise_attributes

XML ELement serialisation, Attributes.

=cut
sub _serialise_attributes
{
    my ($self) = @_;
    return $self->getAttributes(3);
}

sub error ($$$) {
    my ($self,$command,$error)=@_;
	confess "Error requires both command and error" if not $command or not $error;
	if($self->document) {
		if ($self->document->{-raiseerror}) {
			die "$command: $error\n";
		} elsif ($self->document->{-printerror}) {
			print STDERR "$command: $error\n";
		}
	}

    $self->{errors}{$command}=$error;
}

1;
