package XML2::DOM::Attribute;

use base "XML2::DOM::NameSpace";

use strict;
use warnings;

sub ownerElement
{
	return $_[0]->{'owner'};
}

return 1;
