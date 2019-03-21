package XMLStylesheet::MainStylesheetTemplate;

use Data::Dumper::Simple;

##
sub new{
		my $class = shift;
		#my %args = @_;

#		print "new in the stylesheet\n";
		my $self = bless {}, $class;
		$self->{t_output} = 0;

		$self->{namespace} = $class;
		$self->{printout} = 0;
		
		if ( exists($args{output} ) && ( $args{output} eq 'print') ){
				$self->{printout} = 1;
		}

		return $self;
}

sub esq{
		my $s = shift;
		$s =~ s/'/\\'/g;
		return $s;
}


## args: -outputfilename (path.filename)
##			 -namespace
##			 -output: if eq 'print', the compiled template will printout while parsing, should be faster.
##								otherwise the template's output function will return the parsed template
##			
## returns: 1 on success
##					0 if the file could not be opened
sub start_compile{
		my $self = shift;
		my %args = @_;

		$self->{template}->{params} = [];
		$self->{globalparams} = {};
#		$self->{output} = $args{output} || 0;
		$self->{if} = 0;
		$self->{lasttagif} = 0;
		$self->{t_output} = 0;

		if ( $args{output} eq 'print' ){
				$self->{printout} = 1;
		} else {
				$self->{printout} = 0;
		}
		
		if ( !open F, ">", $args{outputfilename} ){
				print STDERR "Couldn't open $args{outputfilename} for writing.\n";
				return 0;
		}
		$self->{handle} = \*F;

		print F "package $args{namespace};\n";
		print F << 'ENDP';

sub new{
		my $class = shift;
		return bless {}, $class;
}

sub output{
		my $self = shift;
		my $params = shift;
		my $globalparams = shift;
		if ( !defined( $globalparams ) ){
			$globalparams = {};
		}
		my $templatename = '';

ENDP

		if ( !$self->{printout} ){
				print F '$s = "";'."\n\n";
		}

		if ( exists( &{"$self->{namespace}::init_globals"} ) ){
				my $f = "init_globals";
				my $ret = $self->$f( %args );
		}

		return 1;
}

sub end_compile{
		my $self = shift;
		$self->t_code('');
		my $f = $self->{handle};

		if ( $self->{printout} ){
				print $f "\nreturn 1\n}\n\n1;\n";
		} else {
				print $f "\nreturn \$s\n}\n\n1;\n";
		}
		close $f;
}


sub warn{
		my $self = shift;
		my $msg = shift;

		print STDERR "$msg\n";
}

sub start_tag_default{
		my $self = shift;
		my $tag = shift;
		my %attrs = @_;

		$self->warn( "start_tag_default..\nUnknown Tag: $tag\n");
}

sub end_tag_default{
		my $self = shift;
		my $tag = shift;
		my %attrs = @_;

#		$self->warn( "end_tag_default..\nUnknown Tag: $tag\n");
}



sub start_tag_loop{
		my $self = shift;

		my %args = @_;

#		print "start_tag_loop, args: ",Dumper(%args);

		if ( exists( $args{loopname} ) ){
				$args{loopname} =~ s/^\[\$(.*)\]/$1/;
		}
		if ( !exists($args{loopname} ) || length($args{loopname}) == 0  ){
				$args{loopname} = '_';
		}

		$self->t_code( 'push @loops, $params;
		foreach $params (@{$params->{'.$args{loopname}."}}){\n" );
}

sub end_tag_loop{
		my $self = shift;

#		my %args = @_;

		$self->t_code( '}
		$params = shift @loops;
');
}

sub start_tag_if{
		my $self = shift;

		my %args = @_;

#		print "start_tag_if, args: ",Dumper(%args);
		$args{value} =~ s/^\[\$(.*)\]/$1/ if ( exists($args{value}) );
		$args{param} =~ s/^\[\$(.*)\]/$1/ if ( exists($args{param}) );

		if ( exists( $args{value} ) && (length($args{value}) > 0) ){ # <if value="varname"> / <TMPL_IF value="varname"> value needs to be defined and != 0
				$self->t_code( 'if ( exists($params->{'.$args{value}.'}) && $params->{'.$args{value}.'} ){' );
				$self->{if} ++;		
		} elsif ( exists( $args{expr} ) && (length($args{expr}) > 0) && (exists($args{param}) )){ #<if expr="expression" params="variablename">
				my $e = $args{expr};
				my $p = $args{param};

				$e =~ s/\[\$\w*\]/\$params->{$p}/g;


				$self->t_code( 'if ( exists( $params->{'.$p.'}) && ( '.$e.' ) ){'); 

				$self->{if} ++;		
		} else {
				$self->warn("Missing parameter for if tag");
				$self->t_code( 'if (0) {');
				$self->{if} ++;		
		}

		
}

sub end_tag_if{
		my $self = shift;

#		my %args = @_;

		if ( $self->{if} ){
				$self->t_code( '}');
				$self->{if} --;
				$self->{lasttagif} = 1;
		}
}

sub start_tag_else{
		my $self = shift;

#		my %args = @_;

		if ( $self->{lasttagif} ){
				$self->t_code( ' else {');
#				$self->{if} --;
				$self->{lasttagif} = 0;
		} else {
				$self->warn( 'Discovered ELSE tag without previous IF !' );
		}
}

sub end_tag_else{
		my $self = shift;

#		my %args = @_;
		$self->t_code( '}' );
}



sub t_output{
		my $self = shift;
		my $output = shift;

		my $f = $self->{handle};

		if ( $output =~ /\[\$/ ){
				foreach my $p ( keys(%{$self->{template}->{params}}) ){
						my $s = $p;
						my $p2 = $p;
						$p2 =~ s/^.//;


						$s =~ s/\$/\\\$/;
#						print "output: param $s\n,p2: $p2\n";
#				print $output,"\n";
#				my $h = $self->{currentargs};
#				print Dumper($h); 
						if ( $output =~ /\[$s\]/ ){
								if ( exists( $self->{currentargs}->{$p2} ) ){
#												print "exists.\n";
										$self->{currentargs}->{$p2} =~  /\[\$(\w*)\|*(.*)\]/;
#								print "found: $1\n";
										my $rep = $1;
										if ( defined($2) ){
												my $def = esq($2);										
												$output =~ s/\[$s\]/'.(\$params->{$rep}||'$def').'/g;
										} elsif ( defined($rep) ) {								
												$output =~ s/\[$s\]/'.\$params->{$rep}.'/g;
										} else{
												$output =~ s/\[$s\]/$self->{currentargs}->{$p2}/g;
										}

								} else {
#								print "p: $p2  - doe\n";
										$output =~ s/\[$s\]//g;
								}
						}
				}
		}
		if ( $output =~ /\[\$/ ){
#				print Dumper($self->{currentargs});
				foreach my $p ( keys(%{$self->{currentargs}}) ){
						my $s = $p;
						my $p2 = $p;
						$p2 =~ s/^.//;


						$s =~ s/\$/\\\$/;
#						print "output: param $s\n,p2: $p2\n";
#				print $output,"\n";
#				my $h = $self->{currentargs};
#				print Dumper($h); 
						if ( $output =~ /\[\$$s\]/ ){
								if ( exists( $self->{currentargs}->{$p2} ) ){
#												print "exists.\n";
										$self->{currentargs}->{$p2} =~  /\[\$(\w*)\|*(.*)\]/;
#								print "found: $1\n";
										my $rep = $1;
										if ( defined($2) ){
												my $def = esq($2);										
												$output =~ s/\[$s\]/'.(\$params->{$rep}||'$def').'/g;
										} elsif ( defined($rep) ) {								
												$output =~ s/\[$s\]/'.\$params->{$rep}.'/g;
										} else{
												$output =~ s/\[\$$s\]/$self->{currentargs}->{$p2}/g;
										}

								} else {
#								print "p: $p2  - doe\n";
										$output =~ s/\[\$$s\]//g;
								}
						}
				}
		}


		if ( $output =~ /\[\$/ ){
				foreach my $p ( keys(%{$self->{globalparams}}) ){
						my $s = $p;
						my $p2 = $p;
						$p2 =~ s/^.//;


						$s =~ s/\$/\\\$/;
#						print "output: param $s\n,p2: $p2\n";
#				print $output,"\n";
#				my $h = $self->{currentargs};
#				print Dumper($h); 
						if ( $output =~ /\[$s\]/ ){
												$output =~ s/\[$s\]/'.(\$globalparams->{$p2}||'').'/g;
						}
				}
		}

		if ( !$self->{t_output} ){
				if ( $self->{printout} ){
						print $f "print '";
				} else {
						print $f "\$s .= '";
				}
				$self->{t_output} = 1;
		}
#		$output =~ s/'/\\'/g;
		print $f $output;
}
		
sub t_code{
		my $self = shift;
		my $code = shift;

		my $f = $self->{handle};

		if ( $self->{t_output} ){
				print $f "';\n";
				$self->{t_output} = 0;
		}
		print $f $code;
}


sub start_tag{
		my $self = shift;
		my $tag = shift;
		my %args = @_;

#		print "\nYYY   start_tag, StylesheetTemplate:  ",Dumper(%args);
		$self->{currentargs} = \%args;
						

		if ( exists( &{"$self->{namespace}::start_tag_$tag"} ) ){
				my $f = "start_tag_$tag";
				my $ret = $self->$f( %args );
				$self->{lasttagif} = 0;
				return $ret;
		} else {
#		print "\nYYY2   start_tag, Stylesheet:  ",Dumper(%args);
				return $self->start_tag_default( $tag, %args );
		}
}

sub end_tag{
		my $self = shift;
		my $tag = shift;
		my %args = @_;

		$self->{currentargs} = \%args;
#		$self->{template}->{params} = [];

		if ( exists( &{"$self->{namespace}::end_tag_$tag"} ) ){
				my $f = "end_tag_$tag";
				return $self->$f(%args);
		} else {
				return $self->end_tag_default( $tag, %args );
		}

}




1;
