package snippets;
## Various snippets 

BEGIN{
				use Exporter;
				@EXPORT = qw/readfile gettempfilename strexist fdate ftime/;
				our @ISA = qw/Exporter/;
}





#* desc
# reads a file and returns an array with it's content.
# can be callen with a named param filename or just the param filename.
#* args: 
# -filename: The filename
# 
#* returns: 
# An array with the file's content
sub readfile {
				my %args;
				if ( @_ > 1 ){
						(%args) = @_;
				}	else {
						$args{filename} = shift;
				}
				#		$args{filename} = $a[0] if ( !defined($args{filename} ) );

				open F, $args{filename} or die "No such file $args{filename}";
				@a = <F>;
				close F;
				return @a;
}

## returns a unique temporary filename
## params:
## 	a name to prepend to the filename
## returns: the filename, which is guaranteed to be unique
sub gettempfilename{
		my $name = shift;

		open( FLOCK, '>>', "/tmp/$name-lock" );
		flock FLOCK, 2;
		
		my $number = 0;
		if ( open F, "</tmp/$name" ){
				$number = <F>;
				close F;
		}

		open F, ">/tmp/$name";
		if ( !defined($number)){
				$number = 0;
		}
		my $n = $number +1;
		seek F, 0, 0;
		print F $n;
		close F;
		close FLOCK;
		return "/tmp/$name-$number";
}

## Appends the string to the supplied ref, if the ref is null, the ref is the string.
## params: 
## ref
## the string to append
sub appendstring{
				my $ref = shift;
				my $string = shift;

				if ( defined( ${$ref} )){
								${$ref} .= $string;
				} else {
								${$ref} = $string;
				}
}
	

## Returns true if the supplied argument is defined and length > 0
sub strexist{
				my $str = shift;
				return 1 if ((defined($str))&&(length($str)>0) );
				return 0;
}

## Returns the current date in the format day.month.year
## 
sub fdate{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	$mon++;
	return ("$mday.$mon.$year");
}

## Returns the current time in the format hour:minute:seconds
## 
sub ftime{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return ("$hour:$min:$sec");
}



1;
