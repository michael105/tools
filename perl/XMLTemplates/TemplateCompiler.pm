package XMLTemplates::TemplateCompiler;


use XML::Parser;

use Data::Dumper::Simple;
use Module::Locate;


use hashes;

sub error{
		my $self = shift;
		my $msg = shift;

		die join( " ", caller() )." $msg";
}


sub new{
		my $class = shift;

		my $self = {};

		$self = bless $self, $class;

		#$self->{maintemplatetemplate} = Module::Locate::locate('XMLTemplates::MainTemplateTemplate') 
		#		or $self->error("Couldn't find MainTemplateTemplate.pm in \@INC !");

		return $self;
}

sub handle_init{
		my $self = shift;
}




sub esq{
		my $s = shift;
		$s =~ s/'/\\\\\\'/g;
		return $s;
}





sub char_output{
		my $self = shift;

		print "char_output\n";

		my $s = $self->{char};



		$s = esq($s);


		$self->{char} = '';

}


sub handle_start{
		my $self = shift;
		my $expat = shift;

		my $tag = shift;

		if ( $tag eq 'xml' ){
				return;
		}

		if ( $self->{char} ){
				$self->char_output();
		}

#		print "start, element: $tag\n";
#		print Dumper( %attrs );


		$self->{stylesheet}->start_tag( $tag, @_ );

}

sub handle_end{
		my $self = shift;
		my $expat = shift;
		my $tag = shift;
#		my %attrs = @_;

		if ( $tag eq 'xml' ){
				return;
		}

		if ( $self->{char} ){
				$self->char_output();
		}

#		print "end, element: $tag\n";
#		print Dumper( %attrs );

		$self->{stylesheet}->end_tag( $tag, @_ );
}


sub handle_char{
		my $self = shift;
		my $parser = shift;
		my $char = shift;

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


## Compiles a template
## args: -stylesheet The compiled stylesheet instance
## 			 -stylesheetname the stylesheet name
##			 -language	the language shortcut
##			 -tmpfilepath	the path to output the file
##			 -templatepath	the directory where the templates live
##			 -template  the template's name, without extension (xml)
##			 -output: if eq 'print', the compiled template will printout while parsing, should be faster.
##								otherwise the template's output function will return the parsed template
#		
sub compile{
		my $self = shift;
		my %args = @_;

		$self->{language} = $args{language} || 'de';
		$self->{stylesheet} = $args{stylesheet};

		$self->{stylesheet}->start_compile( #outputfilename=>"$args{tmpfilepath}/TMPL_$args{template}_$args{stylesheetname}_$args{language}.pm",
				outputfilename=>$args{outputfilename},
				#namespace=>"TMPL_$args{template}_$args{stylesheetname}_$args{language}", output=>$args{output} );
			namespace=>"$args{namespace}", output=>$args{output} );
		
		$self->{char} = '';

		my $p = new XML::Parser( Handlers => {Init => sub{ $self->handle_init(@_) },
																		 Start => sub{ $self->handle_start(@_) },
                                     End   => sub{ $self->handle_end(@_) },
                                     Char  => sub{ $self->handle_char(@_) },
																 		 Final => sub{ $self->handle_final(@_)} });

		if ( !eval { $p->parsefile("$args{templatepath}/$args{template}.xml"); } ) {
				my $ret = $@;
				$ret =~ s/(.*column.*)at.*/$1/;
				$self->error( "$args{templatepath}/$args{template}.xml: Problems while parsing:\n$ret" );
		}


		$self->{stylesheet}->end_compile();

#		print "\n\ntmpl:\n\n$self->{tmpl}\n";
#		return $c;
}


1;
