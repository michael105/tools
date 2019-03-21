package XMLTemplates::Template;

use XMLTemplates::TemplateCompiler;


use Data::Dumper::Simple;



sub new{
		my $class = shift;
		my %args = @_;

		my $self = {};
		bless $self, $class;

		$self->{tmpfilepath} = $args{tmpfilepath} || '/tmp'; #UNSECURE DEFAULT!!! This path may not be writable/readable by other users !

		my $tmplname = $args{templatename};
		$tmplname =~ s/\//_/g;
		$tmplname =~ s/\.tmpl//g;
		print STDERR "tmplname: $tmplname\n";
		$self->{outputfilename} = "$args{tmpfilepath}/TMPL_$tmplname"."_$args{stylesheetname}_$args{language}.pm";
		$self->{namespace} = "XMLTemplates::TMPL_$tmplname"."_$args{stylesheetname}_$args{language}";

		$self->{templatepath} = $args{templatepath};
		$self->{templatename} = $args{templatename};
		$self->{tmpfilepath} = $args{tmpfilepath};
		$self->{language} = $args{language};
		$self->{stylesheetname} = $args{stylesheetname};
		$self->{stylesheet} = $args{stylesheet};
		$self->{output} = $args{output} || '';
		$self->{globalparams} = $args{globalparams} || {};

		$self->load_template();

		return $self;
}

sub clear{
		my $self = shift;
		print STDERR "clear()\n";
		#print STDERR "puser: $self->{params}->{puser}\n";
			delete $self->{params};
			$self->{params} = {};
			#print STDERR "puser: $self->{params}->{puser}\n";

			$self->{globalparams} = {};
}


sub check_mtimes{
		my $self = shift;
		my %args = @_;
		
		$self->load_template();
		return;

		my $fn = $self->{outputfilename};
		my $changed = 0;

		# Compare compiled file in the cache path with the template (if exists)
		my $mtime = 0;
		my $mtime_template = 1;
		my $sctime = 0;
		if ( -e $fn ){
				my @a;
				@a = stat $fn;
				$mtime = $a[9];
				$self->{ctime} = $a[9];
				@a = stat "$self->{templatepath}/$self->{templatename}.xml";
				$mtime_template = $a[9];
				@a = stat $self->{stylesheet}->{outputfilename};
				$sctime = $a[9];
			print STDERR "mtime: $mtime\n";
				print STDERR "mtime_template: $mtime_template\n";
		} 
		# if the file doesn't exist or is older than the template compile the template
		if ( ($mtime <= $mtime_template) || ($mtime <= $sctime) ){
				my $c = XMLTemplates::TemplateCompiler->new();
				$c->compile( template=>$self->{templatename}, tmpfilepath=>$self->{tmpfilepath}, namespace=>$self->{namespace},
									templatepath=>$self->{templatepath}, language=>$self->{language}, outputfilename=>$self->{outputfilename},
									stylesheetname=>$self->{stylesheetname}, stylesheet=>$self->{stylesheet}, output=>$self->{output} );
				$changed = 1;
		}

		if ( $changed || !defined( $self->{template} ) ){
				$self->load_template();
		}
}

sub load_template{
		my $self = shift;

		my $fn = $self->{outputfilename};
		my $changed = 0;

		# Compare compiled file in the cache path with the template (if exists)
		my $mtime = 0;
		my $mtime_template = 1;
		my $sctime = 1;
		if ( -e $fn ){
				my @a;
				@a = stat $fn;
				$mtime = $a[9];
				$self->{ctime} = $a[9];
				@a = stat "$self->{templatepath}/$self->{templatename}.xml";
				$mtime_template = $a[9];
				@a = stat $self->{stylesheet}->{outputfilename};
				$sctime = $a[9];
			print STDERR "mtime: $mtime\n";
				print STDERR "mtime_template: $mtime_template\n";
		}
		# if the file doesn't exist or is older than the template compile the template
		if ( $mtime <= $mtime_template || ( $mtime <= $sctime )){
				my $c = XMLTemplates::TemplateCompiler->new();
				$c->compile( template=>$self->{templatename}, tmpfilepath=>$self->{tmpfilepath}, namespace=>$self->{namespace},
									templatepath=>$self->{templatepath}, language=>$self->{language}, outputfilename=>$self->{outputfilename},
									stylesheetname=>$self->{stylesheetname}, stylesheet=>$self->{stylesheet}, output=>$self->{output} );
				$changed = 1;
		}

		if ( $changed || !defined( $self->{template} )  ){
				delete $INC{$fn};
				require $fn;
#				$self->{template} = "XMLTemplates::TMPL_$self->{templatename}_$self->{stylesheetname}_$self->{language}"->new();
				$self->{template} = "$self->{namespace}"->new();
#				$self->{namespace} = "XMLTemplates::TMPL_$self->{templatename}_$self->{stylesheetname}_$self->{language}";
#				$self->{namespace} = "XMLTemplates::$self->{namespace}";
				my @a;
				@a = stat $fn;
				$self->{ctime} = $a[9];
		}
}


##
sub param{
		my $self = shift;
		my %params = @_;

		foreach my $key ( keys(%params) ){
				print STDERR "param $key : $params{$key}\n";
				$self->{params}->{$key} = $params{$key};
		}

}
##
sub globalparam{
		my $self = shift;
		my %params = @_;

		foreach my $key ( keys(%params) ){
				$self->{globalparams}->{$key} = $params{$key};
		}

}


##
sub output{
		my $self = shift;
		my $params = shift;
		my $globalparams = shift;
		if ( !defined($globalparams)){
				$globalparams = $self->{globalparams};
		}

		if ( defined( $params )){
#				print "Defined\n";
				$self->{template}->output( $params, $globalparams );
		} else {
				print STDERR "params not defined\n", Dumper( $self->{params} );
				$self->{template}->output( $self->{params}, $globalparams );
		}
}








1;
