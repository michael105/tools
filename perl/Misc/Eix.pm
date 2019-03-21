package Misc::Eix;
## Some handling Functions for eix

## args (named)
## -handler: ref to a handler, with the output of eix -c
## -array: ref,alternative to the handler
sub parse_compact{
	my %args = @_;


	my $l;

	while ( ( exists($args{handler}) && ( $l = <$args{handler}> ) ) || ( exists($args{array}) && ( $l = shift(@{$args{array}}) ) ) ){
		print "line: $l\n";





	}


}












1;

