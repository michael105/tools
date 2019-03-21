package mod;

sub new{
		return bless {};
}
sub function{
		my $a = shift;
		print "function: $a\n",@_,"\n";
}

1;


