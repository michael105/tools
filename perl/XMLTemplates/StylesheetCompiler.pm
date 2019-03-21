package XMLTemplates::StylesheetCompiler;


## fehlt noch:
## Rekursion der Templates ( z.B. Tag in basic.xml: <TMPL_textinput name="dbname" value="VALUE1" ... >
##	Sollte relativ einfach über das aufrufen der entsprechenden tag_start_textinput im kompilierten Stylesheet 
##  zu realisieren sein.
##  Tags:  <if value="$bezeichner">
#					 </if>
#					 <else>
#					 </else>


use XML::Parser;

use Data::Dumper::Simple;
use Module::Locate;


use hashes;

sub error{
		my $self = shift;
		my $msg = shift;

		print STDERR "Error while compiling stylesheet $self->{stylesheetfilename}\n";
		die join( " ", caller() )." $msg";
}


sub new{
		my $class = shift;

		my $self = {};

		$self = bless $self, $class;

		$self->{mainstylesheettemplate} = Module::Locate::locate('XMLTemplates::MainStylesheetTemplate') 
				or $self->error("Couldn't find MainStylesheetTemplate.pm in \@INC !");

		$self->{template}->{name} = '';

		return $self;
}

sub handle_init{
		my $self = shift;
}



sub s_arg{
#		my $self = shift;
		my $arg = shift;

		return '$args{'.$arg.'}';
}

#
#sub s_if_arg_exists{
#		my $self = shift;
##	my %args = @_;
#		my ( $arg, $if ) = @_;
#
#		my $f = $self->{handle};
#
#
#		print $f 'if ( exists('.s_arg($args{arg}).') ){'."\n";
#				print $f $if;
#		print $f '} else {'."\n".
#			'$self->warn( "Attribute $args{'.$arg.'} of template '.$self->{template}->{name}.' not supplied !" );'.
#		"\n}\n";
#
#}	
#



sub esq{
		my $s = shift;
		$s =~ s/'/\\\\\\'/g;
		return $s;
}




## args: attrib
## 			 paramkey
###      defaultvalue
sub t_if_attrib{
		my $self = shift;
		my ( $attrib, $paramkey, $defaultvalue ) = @_;
#		my %args = @_;
		my $f = $self->{handle};

		if ( defined($defaultvalue) ){
			$defaultvalue = esq( $defaultvalue );
		}

		print $f 'if ( exists('.s_arg($paramkey).") ){\n";
				print $f s_arg($paramkey).' =~ /^\[\$(\w*)\|*(.*)\]$/;'."\n";
				print $f 'if ( $1 ){'."\n";
											print $f '$self->t_code( "if (exists( \$params->{$1} )){\n" );'."\n";
													print $f '$self->t_output( \' '.$attrib.'="\\\'.$params->{\'.$1.\'}.\\\'"\');'."\n";
						print $f 'if ($2){'."\n";
											print $f '$self->t_code( "} else {\n" );'."\n";
													print $f '$self->t_output( \' '.$attrib.'="\'.esq($2).\'"\' );'."\n";
											print $f '$self->t_code( "}\n" );'."\n";

		if ( defined( $defaultvalue ) && (length($defaultvalue)>0) ){
						print $f "} else {\n";
											print $f '$self->t_code( "} else {\n");'."\n";
													print $f '$self->t_output( \' '.$attrib.'="'.$defaultvalue.'"\' );'."\n";
											print $f '$self->t_code( "}\n" );'."\n";
						print $f "}\n";
		} else {
						print $f "} else {\n";
											print $f '$self->t_code( "}\n");'."\n";
						print $f "}\n";
		}

#				print $f "} else {

			print $f "} else {\n";
											print $f '$self->t_output( \' '.$attrib.'="\'.esq('.s_arg($paramkey).').\'"\' );'."\n";
			print $f "}\n";


		if ( defined( $defaultvalue ) && (length($defaultvalue)>0) ){
				print $f "} else {\n";
											print $f   '$self->t_output( \' '.$attrib.'="'.$defaultvalue.'"\' );'."\n";
				print $f "}\n";
		} else {
				print $f "}\n";
		}
										
}


sub char_output{
		my $self = shift;

#		print "char_output\n";

		if ( !$self->{template}->{name} ){
				return;
		}

		if ( !$self->{char} ){
				return;
		}

		my $f = $self->{handle};

		if ( $self->{tagopen} ){
				print $f '$self->t_output(">\n");'."\n";
				$self->{tagopen} = 0;
		}

		my $s = $self->{char};



		$s = esq($s);


		print $f '$self->t_output( \''.$s.'\');'."\n";

		$self->{char} = '';

}


sub handle_start{
		my $self = shift;
		my $expat = shift;

		my $tag = shift;
		my %attrs = @_;

#		if ( $self->

		#$expat->{testing} = "xxx $element";

		if ( $self->{char} ){
				$self->char_output();
		}

		#	print "start, element: $tag\n";
#		print Dumper( %attrs );


		my $f = $self->{handle};

		if ( $tag eq 'GLOBAL' ){
				print $f 'sub init_globals{'."\n";
				print $f 'my $self = shift;'."\n";
				foreach my $param ( split( ',',$attrs{params} ) ){
						print $f '$self->{globalparams}->{\''.$param.'\'} = \''.$param.'\';'."\n";
				}
				print $f '}'."\n";
		}


		if ( $tag eq 'TEMPLATE' ){
				if ( length( $self->{template}->{name}) > 0  ){
						$self->error( "TEMPLATE section not closed with ENDTEMPLATE in $self->{template}->{name}" );
				}
			$self->{template}->{name} = $attrs{name};
				#$self->{template}->{params} = make_hashref( split( ',', $attrs{params} ) );
				my $p = '[';
				$self->{template}->{params} = {};
				if ( exists( $attrs{params} ) ){
						foreach my $value ( split(',',$attrs{params}) ){
								if ( $value =~ /(.*):(.*)/ ){
										$self->{template}->{params}->{$1} = $2;
										$p .= "'$2',";
								} else {
										$self->{template}->{params}->{$value} = $value;	
										$p .= "'$value',";
								}
						}
				}
			
				if ( $attrs{name} =~ /^_./ ){  # e.g.  <TEMPLATE name="_page">, would close the page tag in the template
						print $f "sub end_tag$attrs{name}";
						print $f " {\nmy \$self = shift;\nmy \%args = \@_;\n\n";
				} else {
						print $f "sub start_tag_$attrs{name}";
						print $f " {\nmy \$self = shift;\nmy \%args = \@_;\n\n";
						$p =~ s/,$/]/;
#						print $f '$self->{template}->{params} = '.$p.';'."\n";
						print $f Dumper($self->{template}->{params});
					
						#print $f '$self->t_code( \'$self->{template}->{params} = '.$p.';\'."\n" );'."\n";
				}
				print $f '$self->t_code( \'$templatename = \\\''.$attrs{name}.'\\\';\'."\n" );'."\n";
				print $f '$self->{template}->{name} = \''.$attrs{name}."';\n";

		} elsif ( $tag eq 'ENDTEMPLATE' ){ 
				$self->{template}->{name} = '';
				if ( $self->{tagopen} ){
						$self->{tagopen} = 0;
						print $f '$self->t_output( ">\n" );'."\n";
						print $f '$self->t_code( \'$templatename = "";\'."\n" );'."\n";
						#print $f '$self->t_code( \'$self->{template}->{name} = "";\'."\n" );'."\n";
						print $f '$self->{template}->{params} = {};'."\n";
						#print $f '$self->t_code( \'$self->{template}->{params} = [];\'."\n" );'."\n";

						delete $self->{template}->{params};
				}
				print $f "}\n\n"; # close the sub in s
		} elsif ( $self->{template}->{name} ){ # We are within a TEMPLATE section
				if ( $self->{tagopen} ){
						print $f '$self->t_output(">\n");'."\n";
						$self->{tagopen} = 0;
				}
				if ( $tag eq 'TMPL_IF' ){
						#		my @a;
						#push @a, "$key=>\"$self->{template}->{params}->{$attrs{$key}}\"" foreach my $key ( keys(%attrs) );
												
						#print $f '$self->start_tag_if( '.join(', ', @a).' );'."\n";
						print $f '$self->start_tag_if( value=>$args{'.($attrs{value}||'_').'}, 
											expr=>$args{'.($attrs{expr}||'_').'}, params=>$args{'.($attrs{params}||'_').'} );'."\n";
						return;
				}

				if ( $tag eq 'TMPL_ELSE' ){
						print $f '$self->start_tag_else();'."\n";
						return;
				}

				if ( $tag eq 'TMPL_LOOP' ){
						print $f '$self->start_tag_loop( loopname=>$args{'.($attrs{loopname}||'_').'} );'."\n";
						return;
				}

				print $f '$self->t_output( "<'.$tag.'");'."\n";

				my $h;
				if ( exists($attrs{attribs}) ){ # <input name="t1" attribs="attr1,attr2:ATTR,"> im stylesheettemplate
						foreach my $value ( split(',',$attrs{attribs}) ){
								my $v = $value;
								if ( $value =~ /(.*):(.*)/ ){
#										print "MATCH: $1   s2: $2\n";
										$h->{$1} = $2;
								} else {
#										print "attrib: $v\n";
										$h->{$v} = $v;
								}
						}
						delete $attrs{attribs};
				}

				foreach my $attrib ( keys(%attrs) ){
						if ( exists( $h->{$attrib} ) ){ # variable
#								print "Variable:  $attrib    xx: $h->{$attrib}   yy: $attrs{$attrib}\n";
								$self->t_if_attrib( $attrib, $h->{$attrib}, $attrs{$attrib} ); # param->{$1}, attribute, defaultvalue
								delete $h->{$attrib};
						} else {
								my $s = esq($attrs{$attrib});
								print $f '$self->t_output( \' '.$attrib.'="'.$s.'"\');'."\n"; # fester wert
						}
				}
				foreach my $attrib ( keys(%{$h}) ){ # No defaultvalues in these attribs
						#$self->s_print( " $attrib=\"\$params->{'.\$args{$h->{$attrib}}.'}\"" );
						$self->t_if_attrib( $attrib, $h->{$attrib} );
				}

#				print $f ">\\'.\"\\n\";';\n";
				$self->{tagopen} = 1;
		}



}

sub handle_end{
		my $self = shift;
		my $expat = shift;
		my $tag = shift;
		my %attrs = @_;

		if ( $self->{char} ){
				$self->char_output();
		}


#		print "end, element: $tag\n";
#		print Dumper( %attrs );

		if ($tag eq 'TEMPLATE'){
				return;
		}

		if ($tag eq 'GLOBAL'){
				return;
		}
			
		if ($tag eq 'ENDTEMPLATE') {
				$self->{template}->{name} = '';
				return;
		}

		if ( !$self->{template}->{name} ){
				return;
		}
		my $f = $self->{handle};

#		my $f = $self->{handle};
#		print $f "\$s .= 'print \"</$tag>\\n\"\\'';\n";
		if ( $self->{tagopen} ){
				print $f '$self->t_output( " />\n" );'."\n";
				$self->{tagopen} = 0;
		} elsif ( $tag eq 'TMPL_IF' ){
						print $f '$self->end_tag_if();'."\n";
		} elsif ( $tag eq 'TMPL_LOOP' ){
						print $f '$self->end_tag_loop();'."\n";
		} elsif ( $tag eq 'TMPL_ELSE' ){
						print $f '$self->end_tag_else();'."\n";
		}	else {
				print $f '$self->t_output( "</'.$tag.'>\n");'."\n";
		}


}


sub handle_char{
		my $self = shift;
		my $parser = shift;
		my $char = shift;

#		print "last: $parser->{testing}\n";
		if ( !$self->{template}->{name} ){
				return;
		}


		if ( $char =~ /\S+/ ){
				$self->{char}.= $char;
		}
}

sub handle_final{
		my $self = shift;
		my $parser = shift;

#		print "final:\n$parser->{testing}\n";
#		return $parser->{testing};
}


## Compiles a stylesheet
## args: -stylesheet (the source file)
##			 -language	the language shortcut
##			 -tmpfilepath	the path to output the file
##			 -stylesheetpath	the directory where the stylesheets live
sub compile{
		my $self = shift;
		my %args = @_;

		$self->{language} = $args{language} || 'de';

		$self->open_stylesheethandle(%args);

		$self->{currenttemplate} = 0;
		$self->{template}->{name} = '';
		$self->{template}->{tagopen} = 0;
		$self->{char} = '';

		my $p = new XML::Parser( Handlers => {Init => sub{ $self->handle_init(@_) },
																		 Start => sub{ $self->handle_start(@_) },
                                     End   => sub{ $self->handle_end(@_) },
                                     Char  => sub{ $self->handle_char(@_) },
																 		 Final => sub{ $self->handle_final(@_)} });

		$self->{stylesheetfilename} = "$args{stylesheetpath}/$args{stylesheet}.xml";
		if ( !eval { 	$p->parsefile("$args{stylesheetpath}/$args{stylesheet}.xml"); } ) {
				my $ret = $@;
				$ret =~ s/(.*column.*)at.*/$1/;
				$self->error( "$args{stylesheetpath}/$args{stylesheet}.xml: Problems while parsing:\n$ret" );
		}


		$self->close_stylesheethandle();

#		print "\n\ntmpl:\n\n$self->{tmpl}\n";
#		return $c;
}

sub open_stylesheethandle{
		my $self = shift;
		my %args = @_;


		open F, "<", $self->{mainstylesheettemplate}
				or $self->error("Couldn't open MainStylesheetTemplate for reading ! Check the permissions, please !");

		open O, ">", "$args{tmpfilepath}/$args{stylesheet}_$args{language}.pm" 
				or $self->error("Couldn't open the stylesheet for writing: $args{tmpfilepath}/$args{stylesheet}_$args{language}.pm");
	
		my $line = <F>; # Discard the first package line
		print O "package XMLStylesheet::$args{stylesheet}_$args{language};\n\n";
		$line = <F>;
		my $lastline = '';
		do {
				print O $lastline;
				$lastline = $line;
		} while ( $line = <F> );
		# Discard the last line ( '1;' ) !
		if ( $lastline !~ /^1;/ ){
				$self->error( "The last line of MainStylesheetTemplate.pm must be '1;' !" );
		}
		close F;
		$self->{handle} = \*O;

}

sub close_stylesheethandle{
		my $self = shift;
		my $f = $self->{handle};
#		print "hhh";
		print $f "\n1;";
		close $f or die;
}

1;
