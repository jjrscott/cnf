package Dumper;

use JSON::PP;

my $json = JSON::PP->new->canonical(1)->pretty(1)->relaxed(1)->allow_nonref();

sub Dumper
{
	if (@_ > 1)
	{
		return $json->encode(\@_);
	}
	else
	{
		return $json->encode($_[0]);
	}
}
	
return 1;