package Misc::Hashes;
#* description
# Various functions for hashes



BEGIN{
				use Exporter;
				our @ISA = qw/Exporter/;
				@EXPORT = qw/flatten_hash unflatten_hash make_hashref hash_path hash_grep hash_egrep hash_clone/;
}


## converts a nested hash into a flat format
## args: ref to the hash
## returns: array with the lines
sub flatten_hash{
	my $hash = shift;
	my $line = shift || "";

	my @lines = ();



	foreach my $key ( sort( {return ($a <=> $b) if ( ! ("$a$b" =~ /\D/) ); return ($a cmp $b)} keys(%{$hash}) ) ){
		my $l = "$line$key \t";
	
		my $var = ref( $hash->{$key} );
		if ( $var eq 'HASH' ){
			push @lines, flatten_hash( $hash->{$key}, $l );
#			push @lines, "\n";
		} elsif ( $var eq '' ) {
			my $v = $hash->{$key};
			$v =~ s/\\/\\\\/g;
			$v =~ s/\n/\\n/g;
			$v =~ s/ /\\s/g;
			push @lines, "$l$v\n";
		} else {
			die "flatten_hash cannot handle refs of type $var";
		}
	}

	return @lines;
}

## Converts the flat format of flatten_hash back to a hash
sub unflatten_hash{
	my @lines = @_;

	my $hash = {};


	foreach my $l ( @lines ){
		my $p = $hash;

		my @a = split( /\s+/, $l );
		next if ( scalar(@a) < 2 );

		my $v = pop @a;
		chomp $v;
		print "v: $v\n";
		$v =~ s/([^\\])\\s/$1 /g;
		$v =~ s/([^\\])\\n/$1\n/g;
		$v =~ s/\\\\/\\/g;
		print "v2: $v\n";

		my $lastkey = pop @a;

		foreach my $key ( @a ){
			$p->{$key} = {} if ( !exists($p->{$key}) );
			$p = $p->{$key};
		}

		$p->{$lastkey} = $v;
	}


	return $hash;
}


## Returns a refenrence to a hash which keys are the supplied params, the values are all 1.
sub make_hashref{
				my @a = @_;
				my %hash;
				foreach my $key ( @a ){
								$hash{$key} = 1;
				}
				return \%hash;
}


## Returns a hash's value or undef
## Iterates through the hashes, tests each hash with exists
## Usage:
## my $value = hash_path( $ref_to_hash, 'key1', 'key2' (,...) );
##
## returns: undef or the value
sub hash_path{
		my $ref = shift;
		my @keys = @_;

		my $p = $ref;

		foreach my $key( @keys ){
				return undef if ( !exists( $p->{$key} ) );
				$p = $p->{$key};
		}

		return $p;	
}


## Seeks in a nested hash for one or several values with a key.
## Usage:
## foreach my $ref ( hash_grep( $hash, 'keyname' ) ){ $$ref = 'New Value' }
## 
## args: 
## -ref to hash
## -keyname
## returns:
## an array of refs to the values
sub hash_grep{
	my $hash  = shift;
	my $key = shift;


	my @results;

	foreach my $k ( keys(%{$hash}) ){
		if ( $k eq $key ){
			push @results, \$hash->{$k};
		}
		push @results, hash_grep( $hash->{$k}, $key );
	}
	return @results;
}

## Seeks in a nested hash for one or several values with a key matching a pattern.
## Usage:
## foreach my $ref ( hash_egrep( $hash, '%d' ) ){ $$ref = 'New Value' }
## 
## args: 
## -ref to hash
## -keyname
## returns:
## an array of refs to the values
sub hash_egrep{
	my $hash  = shift;
	my $pattern = shift;


	my @results;

	foreach my $k ( keys(%{$hash}) ){
		if ( $k =~ /$pattern/ ){
			push @results, \$hash->{$k};
		}
		push @results, hash_egrep( $hash->{$k}, $pattern );
	}
	return @results;
}



## Make a deep copy of a hash
## args:
## hashref source
##
## returns:
## ref to the cloned hash
sub hash_clone{
	my $hash = shift;

	return $hash if ( !ref($hash) );

	my $dest;

	foreach my $k ( keys(%$hash) ){
		$dest->{$k} = hash_clone( $hash->{$k} );
	}
	return $dest;
}


1;
