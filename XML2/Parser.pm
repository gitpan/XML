package XML2::Parser;

use strict;
use base qw(XML::SAX::Base);
use Carp;

sub new
{
	my ($proto, %opts) = @_;
	$opts{'inline'} = 1;
	if(not $opts{'document'}) {
		croak "Unable to parse xml without document";
	}
	return bless \%opts, $proto;
}

sub document
{
	my ($self) = @_;
	return $self->{'document'};
}

sub start_document {
	my ($self, $doc) = @_;
	$self->{'inline'} = 0;
}

sub end_document {
	my ($self) = @_;
}

sub start_element
{
	my ($self, $node) = @_;
	$self->text;
	# ELEMENT
	# LocalName - The name of the element minus any namespace prefix it may have come with in the document.
	# NamespaceURI - The URI of the namespace associated with this element, or the empty string for none.
	# Attributes - A set of attributes as described below.
	# Name - The name of the element as it was seen in the document (i.e.  including any prefix associated with it)
	# Prefix - The prefix used to qualify this element’s namespace, or the empty string if none.

	my $element;
	my $parent = $self->{'parent'};

	if(not $parent and not $self->{'inline'}) {
		$self->document->doctype->name($node->{'LocalName'});
	}

	if($node->{'Prefix'}) {
		my $ns = $self->document->getNamespace( $node->{'Prefix'} );
		if(not $ns) {
			warn "Could not get namespace for node: ".$node->{'Prefix'}."\n";
		}
		$element = $self->document->createElementNS( $ns, $node->{'LocalName'} );
	} else {
		$element = $self->document->createElement( $node->{'LocalName'}, document => $self->document );
	}

	if($parent) {
		$parent->appendChild($element);
	} else {
		$self->{'parents'} = [];
		$self->document->documentElement($element);
		# Name spaces, we do this first so later on we don't try adding attributes
		# into the document element that have namespaces yet to be added in the hash
		# order (perl!)
		my $ns = $self->document->getNamespace( 'xmlns' );
		foreach my $a (keys(%{$node->{'Attributes'}})) {
			my $attribute = $node->{'Attributes'}->{$a};
			if($attribute->{'Name'} eq 'xmlns') {
#				warn "Namespace ".$attribute->{'Prefix'}.':'.$attribute->{'Name'}.'='.$attribute->{'Value'}." to ".$node->{'Name'}."\n";
				$element->setAttribute( $attribute->{'LocalName'}, $attribute->{'Value'} );
			} elsif($attribute->{'Prefix'} eq 'xmlns') {
#				warn "NSW ".$attribute->{'Prefix'}.':'.$attribute->{'Name'}.'='.$attribute->{'Value'}." to ".$node->{'Name'}."\n";
				$self->document->createNamespace($attribute->{'LocalName'}, $attribute->{'Value'});
			} else {
				next;
			}
			delete($node->{'Attributes'}->{$a});
		}

	}

	# ATTRIBUTES {}
    # LocalName - The name of the attribute minus any namespace prefix it may have come with in the document.
    # NamespaceURI - The URI of the namespace associated with this attribute. If the attribute had no prefix, then this consists of just the empty string.
    # Name - The attribute’s name as it appeared in the document, including any namespace prefix.
    # Prefix - The prefix used to qualify this attribute’s namepace, or the empty string if none.
    # Value - VALUE.

	foreach my $attribute (values(%{$node->{'Attributes'}})) {
		if($attribute->{'Prefix'}) {
			my $ns = $self->document->getNamespace( $attribute->{'Prefix'} );
			if(not $ns) {
				warn "Could not get namespace for attribute: ".$attribute->{'Prefix'}." (".$attribute->{'NamespaceURI'}.")\n";
				next;
			}
			$element->setAttributeNS( $ns, $attribute->{'LocalName'}, $attribute->{'Value'} );
		} else {
			$element->setAttribute( $attribute->{'LocalName'}, $attribute->{'Value'} );
		}
	}

	push(@{$self->{'parents'}}, $self->{'parent'})if $self->{'parent'};
	$self->{'parent'} = $element;

}

sub end_element
{

	my ($self, $element) = @_;
	$self->text;
    # ELEMENT
	# LocalName - The name of the element minus any namespace prefix it may have come with in the document.
	# NamespaceURI - The URI of the namespace associated with this element, or the empty string for none.
	# Name - The name of the element as it was seen in the document (i.e.  including any prefix associated with it)
	# Prefix - The prefix used to qualify this element’s namespace, or the empty string if none.
	$self->{'parent'} = pop @{$self->{'parents'}};
}

sub characters
{
	my ($self, $text) = @_;

	# We wish to keep track of text characters, and
	# and deal with text once other elements are found
	$self->{'text'} = '' if not defined($self->{'-text'});
	$self->{'text'} .= $text->{'Data'};
}

sub text
{
	my ($self) = @_;
	if($self->{'text'}) {
		my $text = $self->{'text'};
		if($text =~ /\S/) {
			$self->{'parent'}->cdata($text);
		}
		delete($self->{'text'});
	}
}

sub comment
{
	my ($self, $comment) = @_;
	$self->text;
	warn "Comment '".$comment->{'Data'}."'\n";
	# Data
}

sub start_cdata
{
	warn "START CDATA\n";
}
sub end_cdata
{
	warn "END CDATA\n";
}

sub processing_instruction
{
	warn "PI\n";
}

# We want to store the below details for the document creation

sub doctype_decl
{
	my ($self, $dtd) = @_;
	my $doc = $self->document;
	# Name
	# SystemId
	# PublicId
	warn "Setting doctype name to ".$dtd->{'Name'}."\n";
	$doc->doctype->name($dtd->{'Name'});
	$doc->doctype->systemId($dtd->{'SystemId'});
	$doc->doctype->publicId($dtd->{'PublicId'});
#	$self->{'dtd'} = $dtd;
}

sub xml_decl
{
	my ($self, $xml) = @_;
	my $doc = $self->document;
	# Version
	# Encoding
	# Standalone
	$doc->version($xml->{'Version'});
	$doc->encoding($xml->{'Encoding'});
	$doc->standalone($xml->{'Standalone'});
#	$self->{'xml'} = $xml;
}

return 1;
