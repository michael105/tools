package Misc::Snippets;
## Various snippets 

use Cwd;

BEGIN{
				use Exporter;
				@EXPORT = qw/readfile gettempfilename strexist fdate ftime fsize hbytes default savefilename quote/;
				our @ISA = qw/Exporter/;
}


#use utf8;


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


				if ( !-e $args{filename} ){
#					print "read: $args{filename}\n";
					# resolve relative paths (./ ../)
					$args{filename} =~ s/^\.\//$ENV{PWD}\//;
					$args{filename} = Cwd::realpath($args{filename});
#					print "read: $args{filename}\n";
				}
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

## Returns the filesize in bytes
##
sub fsize{
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		       $atime,$mtime,$ctime,$blksize,$blocks)
		              = stat(shift);
	return $size;
}


## Returns the supplied number as a splitted array: (Terabytes, Gigabytes, Megabytes, Kilobytes and bytes)
sub hbytes{
	my $b = shift;

	my @ret;

	foreach my $a ( 4,3,2,1){
		my $c = int ( $b/(1024**$a) );
		if ( $c > 1 ){
			push @ret,$c;
			$b-=$c*1024**$a;
		}
	}
	push @ret, $b;
	return @ret;
}


## if arg1 is defined, return arg1, otherwise arg2 or, if arg2 is not defined, return 0.
sub default{
	defined($_[0]) ? $_[0] : ( exists($_[1]) ? $_[1] : 0 );
}

## quote: 
## " -> \"  
## ' -> \'
## \ -> \\
sub quote{
	my $s = shift;
	my $rep = { '"'=>'\"', "'"=>"\\'", '\\'=>'\\\\' };
	$s =~ s/([\\'"])/$rep->{$1}/g;
	return $s;
}

use utf8;
my $convert = { 
'ä'=>'ae',
'Ä'=>'Ae',
'ö'=>'oe',
'Ö'=>'Oe',
'ü'=>'ue',
'Ü'=>'Ue',
'ß'=>'ss',
' '=>'_'
};

## Convert a given string to a "save" filename.
## Changes : German Umlauts to 'ae', 'oe', ..
##   space to _
## Strips All Non alphabetic chars except: . _ + - : ,
sub savefilename{
	my $s = shift;
#	print $s,"\n";
	utf8::decode($s);
#	print $s,"\n";

	$s =~ s/([äöüÄÖÜß ])/$convert->{$1}/g;
#	print $s,"\n";
	$s =~ s/[^\w.+:,-]//g;
	return $s;
}

my $umlautconvert = { 
'ä'=>'ae',
'Ä'=>'Ae',
'ö'=>'oe',
'Ö'=>'Oe',
'ü'=>'ue',
'Ü'=>'Ue',
'ß'=>'ss',
};

## Convert German umlauts to 'ae', 'oe', ..
sub convert_umlaute{
	my $s = shift;
#	print $s,"\n";
	utf8::decode($s);
#	print $s,"\n";

	$s =~ s/([äöüÄÖÜß])/$umlautconvert->{$1}/g;
#	print $s,"\n";
	#$s =~ s/[^\w.+:,-]//g;
	return $s;
}



1;
