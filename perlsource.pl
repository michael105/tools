#!/usr/bin/perl -w
## Looks for the module's source supplied as first arg.
## Fires vi on this module



my $m = shift;


$m =~ s/::/\//g;
$m.='.pm';
my $b = 0;

foreach my $p (@INC){
		if ( -e "$p/$m" ){
				print "Found:\n$p/$m\n";
				system("vi $p/$m");
				$b = 1;
				last;
		}
}

if ( ! $b ){
		print "Not found.\n";
} 






