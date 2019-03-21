package Misc::Arguments;
#* author
# Michael (misc) Myer
#
#* license
# GPL
#
#* version
# 0.3
#
#* usage 
# use arguments;
# arguments::parse();
#
#* description
# Parses the script arguments via Getopt::Mixed.
# shows: 
# - the script Misc::Documentation via Misc::Documentation::print_scriptdocu() if --help or -h is defined
# - the script version on --version or -v
# 
#

use Misc::Hashes;

use Getopt::Mixed "nextOption";


use Switch;

use Misc::Documentation;

# Parse the options for -v or -h,
# print the help/usage if they are there

#my $options="h help>h v version>v license";
#Getopt::Mixed::init($options);

#while (my ($option, $value) = nextOption()) {
#				switch ($option){
#								case 'v' {
#												Misc::Documentation::print_version();
#								}
#								case 'h' {
#												Misc::Documentation::print_help();
#								}
#								case 'license' {
#												Misc::Documentation::print_license();
#								}
#				}
#}

#print "Arguments: ",join("\n",@ARGV),"\n";


## parses command line arguments.
## All Arguments which are not recognized will be left in @ARGV
## params:
## a string which describes the options:
##		optionname[(=|:)(s|i|f)]
## 		=s :s    option takes a mandatory (=) or optional (:) string argument
##		=i :i    option takes a mandatory (=) or optional (:) integer argument
##		=f :f    option takes a mandatory (=) or optional (:) real number argument
##		>new     option is a synonym for option `new'
##		e.g. : "s=s d:i v verbose>v"	: -s takes a string, -d an integer, -v is a synonym for --verbose
##	the number of needed options (will print the help without enough options)
## an array of needed options (the short names)
## returns: a ref to an hash, the (short) options are the keys.
sub parse{
				my ( $options ) = shift;
				my $neededparams = shift || 0;
				my @neededoptions = @_;

				my %args;

				$options.=" h help>h v version>v license";

				my $n = Misc::Hashes::make_hashref( @neededoptions );

				#print join("\n",@neededoptions);

				$options =~ s/^\s//g;
#				print "Options: $options\n";
				Getopt::Mixed::init($options);

				while (my ($option, $value) = nextOption()) {
					$neededparams --;
								switch ($option){
												case 'v' {
																Misc::Documentation::print_version();
												}
												case 'h' {
																Misc::Documentation::print_help();
												}
												case 'license' {
																Misc::Documentation::print_license();
												}
								}
#								print "option: $option    $value\n";
								$args{$option}=$value;
								delete $n->{$option};
				}
		    Getopt::Mixed::cleanup();

				if ( (scalar( keys( %{$n} ) ) > 0) || ( $neededparams > 0 )  ){
								Misc::Documentation::print_help();
				}
				return \%args;
}
	



1;
