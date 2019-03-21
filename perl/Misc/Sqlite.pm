package Misc::Sqlite;

use DBI;
use Data::Dumper::Simple;



## args: (named)
## 	-tables
##	-db
sub ensuretables{
	my %args = @_;

	my $db = $args{db};

	my $schema = $db->selectall_hashref(".schema", {});

	print Dumper($schema);
	



}




















1;
