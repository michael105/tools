package filter;

BEGIN{
				use Exporter;
				@ISA='Exporter';
				@EXPORT=qw/filterlines filter/;
}


## Filters all lines between and including startpattern and endpattern
## args: 	startpattern
##				endpattern
##				array to filter
## returns: The filtered array
sub filterlines{
				my $startpattern = shift;
				my $endpattern = shift;

				my $b = 1;
				my @a;

				while ( my $l = shift ){
								if ( $b ){
												if ( $l =~ /$startpattern/ ){
																$b = 0;
												} else {
																push @a, $l;
												}
								} else {
												$b = 1 if ( $l =~ /$endpattern/ )
								}
				}
				return @a;
}


## Filters all  between and including startpattern and endpattern
## args: 	startpattern
##				endpattern
##				array to filter
## returns: The filtered array
sub filter{
				my $startpattern = shift;
				my $endpattern = shift;

				my $b = 1;
				my @a;

				while ( my $l = shift ){
								if ( $b ){
												if ( $l =~ /(.*)$startpattern/ ){
																push @a, $1;
																$b = 0;
												} else {
																push @a, $l;
												}
								} else {
												if ( $l =~ /$endpattern(.*)/ ){
																push @a, $1;
																$b=1;
												}
								}
				}
				return @a;
}											












1;
