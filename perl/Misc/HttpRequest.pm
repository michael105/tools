package Misc::HttpRequest;
## Handles an httprequest
## usage: httprequest::request( $client );


use IO::Socket::INET;

##args: The client ( io::socket::INET server's accept response )
## returns: ref to hash : { 
sub request{
		my $r = shift;

		my %hash;
		$hash{peerhost} = $r->peerhost() or return {};

		my $line = <$r>;
		return {} if ( ! ($line =~ /^GET (\S*)/) );
		$hash{GET} = $1;

		#while ( ( $line = <$r> ) && ( $line =~ /(\S*): (.*)/ ) ){ 
		while ( defined( $r) && ( $line = <$r> ) && ( defined($line) ) && length($line)>4 ){
				if ( $line =~ /^Cookie: (.*)/ ){
						my @cookies = split('; ', $1 ) ;
						foreach my $c ( @cookies ){
								$c =~ /(.*)=(\S*)/;
								$hash{Cookie}->{$1} = $2;
						}


				}
		}

		return \%hash;
}




1;

