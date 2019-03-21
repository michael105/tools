package Misc::Files;
## Some Functions for file handling
use warnings;

use snippets;
use hashes;



use File::Spec;

$separator = '/';


BEGIN{
	use Exporter;
	@EXPORT = qw/fcopy/;
	our @ISA = ( 'Exporter' );
}

#*desc	
# copies files and directories, preserves attributes
# creates the target directory structure if needed
# Preserves ownership if possible, but doesn't check whether it is allowed to preserve ownership!
#
#*args (named)
# 	+ -source: sourcefile or directory
#	+ -destdir: 	destination directory
#	-destfile: 	destination filename
#	-directories: if true copies also directories recursively, overwrites existing data in dest!
#	-handlers:	a hash with handler functions:
#			{ sourceisdir=>sub{ .. }
#			}
sub fcopy{
	my %args = @_;

	my ( $a , $sourcedir, $sourcefn ) = File::Spec->splitpath( $args{source} ); 
	my $dest = $args{destdir};
	if ( $dest !~ /$separator$/ ){
		$dest .= $separator;
	}

	$dest .= $sourcedir;
	if ( $dest !~ /$separator$/ ){
		$dest .= $separator;
	}

	$dest =~ s/\/\.\//\//g; # unix specific! (parses /./ into /)
	$destinationdir = $dest;
	$destinationdir =~ s/$separator$//;

	if ( strexist($args{destfile} )){
		$dest .= $args{destfile};
	} else {
		$dest .= $sourcefn;
	}

	if ( !exists($args{directories}) || ( ! $args{directories} ) ){
		if ( -d $args{source} ){ # sourcefile is a directory
			print "Source is a directory in fcopy, won't copy that without directories being set !\n";
			if ( hash_path( \%args, 'handlers', 'sourceisdir' )){
				#print "2\n";
				my $f = $args{handlers}->{sourceisdir};
				return &$f(destinationdir=>$destinationdir, destination=>$dest, %args);

			}
			return 1;
		}
	}

	if ( ! -e $args{source} ){
		print "Sourcefile $args{source} doesn't exist !\n";
		return 2;
	}

	if ( ! -d $destinationdir ){
		print "Target dir $destinationdir doesn't exist!\n";
		if ( -e $destinationdir ){
			print "Error: Target dir Exists, but isn't a directory!\nAborting.\n";
			return 3;
		}

	return 0 if ( system( "cp -a $args{source} $dest" ) == 0 ); # Copy worked. No more work


	print "Error..\n";
}
	
	








1;

