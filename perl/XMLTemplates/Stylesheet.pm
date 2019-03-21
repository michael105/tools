package XMLTemplates::Stylesheet;

use Data::Dumper::Simple;

use XMLTemplates::StylesheetCompiler;

sub new{
		my $class = shift;
		my %args = @_;

		my $self = {};
		bless $self, $class;

		$self->{tmpfilepath} = $args{tmpfilepath} || '/tmp'; #UNSECURE DEFAULT!!! This path may not be writable/readable by other users !

		$self->{outputfilename} = "$args{tmpfilepath}/$args{stylesheet}_$args{language}.pm";
		$self->{stylesheetpath} = $args{stylesheetpath};
		$self->{stylesheetname} = $args{stylesheet};
		$self->{tmpfilepath} = $args{tmpfilepath};
		$self->{language} = $args{language};
		$self->{output} = $args{output} || '';


		$self->load_stylesheet(%args);		

		return $self;
}

sub set_output_filename{
		my $self = shift;
		my $fn = shift;

		$self->{stylesheet}->set_output_filename($self->{tmpfilepath}.$fn);
}

sub check_mtimes{
		my $self = shift;
		my %args = @_;

		$self->load_stylesheet();
		return;


		my $fn = $self->{outputfilename};
		my $changed = 0;

		# Compare compiled file in the cache path with the template (if exists)
		my $mtime = 0;
		my $mtime_stylesheet = 1;
		if ( -e $fn ){
				my @a;
				@a = stat $fn;
				$mtime = $a[9];
				$self->{ctime} = $a[9];
				@a = stat "$self->{stylesheetpath}/$self->{stylesheetname}.xml";
				$mtime_stylesheet = $a[9];
#				print "mtime: $mtime\n";
#				print "mtime_stylesheet: $mtime_stylesheet\n";
		} 
		# if the file doesn't exist or is older than the stylesheet compile the stylesheet
		if ( $mtime < $mtime_stylesheet ){
				my $c = XMLTemplates::StylesheetCompiler->new();
				$c->compile( stylesheet=>$self->{stylesheetname}, tmpfilepath=>$self->{tmpfilepath},
									stylesheetpath=>$self->{stylesheetpath}, language=>$self->{language});
				$changed = 1;
		}

		if ( $changed || !defined( $self->{stylesheet} ) ){
				$self->load_stylesheet();
		}
}

sub load_stylesheet{
		my $self = shift;

		my $fn = $self->{outputfilename};
		my $changed = 0;

		# Compare compiled file in the cache path with the template (if exists)
		my $mtime = 0;
		my $mtime_stylesheet = 1;
		if ( -e $fn ){
				my @a;
				@a = stat $fn;
				$mtime = $a[9];
				$self->{ctime} = $a[9];
				@a = stat "$self->{stylesheetpath}/$self->{stylesheetname}.xml";
				$mtime_stylesheet = $a[9];
#				print "mtime: $mtime\n";
#				print "mtime_stylesheet: $mtime_stylesheet\n";
		}
		# if the file doesn't exist or is older than the stylesheet compile the stylesheet
		if ( $mtime < $mtime_stylesheet ){
				my $c = XMLTemplates::StylesheetCompiler->new();
				$c->compile( stylesheet=>$self->{stylesheetname}, tmpfilepath=>$self->{tmpfilepath},
									stylesheetpath=>$self->{stylesheetpath}, language=>$self->{language});
				$changed = 1;
		}

		if ( $changed || !defined( $self->{stylesheet} ) ){
				delete $INC{$fn};
				require $fn;
				$self->{stylesheet} = "XMLStylesheet::$self->{stylesheetname}_$self->{language}"->new();
				$self->{namespace} = "XMLStylesheet::$self->{stylesheetname}_$self->{language}";
				my @a;
				@a = stat $fn;
				$self->{ctime} = $a[9];
		}
}

# starts the compile of a template
sub start_compile{
		my $self = shift;
		return $self->{stylesheet}->start_compile(@_);
}

# ends the compile of a template
sub end_compile{
		my $self = shift;
		return $self->{stylesheet}->end_compile(@_);
}



sub start_tag{
		my $self = shift;
#		my %args = @_;

		return $self->{stylesheet}->start_tag( @_ );
#		print "\nYYY   start_tag, Stylesheet:  ",Dumper(%args);
#
#		if ( exists( &{"$self->{namespace}::start_tag_$args{tag}"} ) ){
#				my $f = "start_tag_$args{tag}";
#		print "\nYYY2   start_tag, Stylesheet:  ",Dumper(%args);
#				return $self->{stylesheet}->$f( %args );
#		} else {
#		print "\nYYY2   start_tag, Stylesheet:  ",Dumper(%args);
#				return $self->{stylesheet}->start_tag_default( %args );
#		}
}

sub end_tag{
		my $self = shift;
		#	my %args = @_;

		return $self->{stylesheet}->end_tag( @_ );
#		if ( exists( &{"$self->{namespace}::end_tag_$args{tag}"} ) ){
#				my $f = "end_tag_$args{tag}";
#				return $self->{stylesheet}->$f(%args);
#		} else {
#				return $self->{stylesheet}->end_tag_default( %args );
#		}

}







1;

