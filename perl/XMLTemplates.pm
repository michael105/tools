package XMLTemplates;

use XMLTemplates::Template;
use XMLTemplates::Stylesheet;

use hashes;


sub i18n_db{
		return shift;
}

sub i18n{
		return shift;
}

sub qu{
		return '"'.shift().'" ';
}

## Creates the main XMLTemplates instance.
## args: -tmpfilepath
##			 -stylesheetpath
##			 -templatepath
sub new{
		my $class = shift;
		my %args = @_;

		my $self = {};

		$args{tmpfilepath} = $args{tmpfilepath} || '/tmp'; #UNSECURE DEFAULT!!! This path may not be writable/readable by other users !
		

		$self->{tmpfilepath} = $args{tmpfilepath};
		$self->{stylesheetpath} = $args{stylesheetpath};
		$self->{templatepath} = $args{templatepath};

#		$self->{stylesheets}->{$args{stylesheet}}->{$args{language}} = XMLTemplates::Stylesheet->new( %args );

		$self->{templates} = {};
		print STDERR "new in XMLTemplates\n";

		return bless $self, $class;
}

sub setLanguage{
		my $self = shift;

		$self->{lang} = shift;
}

## Returns a template instance, loads and compiles the file if needed.
## args: -templatename 	The filename of the (new or already compiled) template, without extension
##			 -stylesheet	The filename of the main xml template ("stylesheet") without extension
##			 -language	language abbreviation
##			 -output: if eq 'print', the compiled template will printout while parsing, should be faster.
##								otherwise the template's output function will return the parsed template
#
sub get_template{
		my $self = shift;

		my %args = @_;
		if ( !exists($self->{stylesheets}->{$args{stylesheet}}->{$args{language}}) ){
				$self->{stylesheets}->{$args{stylesheet}}->{$args{language}} = XMLTemplates::Stylesheet->new( %args, 
							tmpfilepath=>$self->{tmpfilepath}, stylesheetpath=>$self->{stylesheetpath} );
		} else {
				print STDERR "checking stylesheet\n";
				$self->{stylesheets}->{$args{stylesheet}}->{$args{language}}->check_mtimes();
		}

		if ( !defined(hash_path( $self, 'templates', $args{templatename}, $args{stylesheet}, $args{language} ) )){
				$self->{templates}->{$args{templatename}}->{$args{stylesheet}}->{$args{language}} = XMLTemplates::Template->new(
							tmpfilepath=>$self->{tmpfilepath}, templatepath=>$self->{templatepath}, stylesheetname=>$args{stylesheet},
							stylesheetname=>$args{stylesheet}, language=>$args{language}, templatename=>$args{templatename},
							stylesheet=>$self->{stylesheets}->{$args{stylesheet}}->{$args{language}},
							output=>$args{output} || ''
				);
		} else {
				print STDERR "checking template\n";
				$self->{templates}->{$args{templatename}}->{$args{stylesheet}}->{$args{language}}->check_mtimes();				
				$self->{templates}->{$args{templatename}}->{$args{stylesheet}}->{$args{language}}->clear();				
		}


		return $self->{templates}->{$args{templatename}}->{$args{stylesheet}}->{$args{language}};
}





1;
