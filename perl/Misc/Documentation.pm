package Misc::Documentation;
## Extracts documentation from a script
## usage:
## There are two styles of writing documentation in files.
## All documentation which should be presented are commented with ##, tags are presented by ## tag:
## or documentation to show is commented with one #, but each docu block starts with a tag, formed by #*tag.
##
## the documentation which starts in line 2 of a file is always handled as description of the script.
## If there's a usage tag present in the first block of documentation, this will show up if the script uses arguments.pm and is invoked with --help.
##
## All documentation written immediately before the declaration of variables and functions is handled as documentation of the following function/variable.
## Variables descriptions are put into the description of the file.
## 
## The following tags are global and should possibly be written at the start:
## -author
## -email
## -license
## -year
## -version
## -webpage
## These tags have also default values, defined in documentation.pm.
## 
## These tags describe the script/function/variables:
## -desc / description
## -usage
## -params /args   The parameters of the script/function
## if the tag args is followed by (named): named parameters.
## list the parameters by -
## if the line starts with + (e.g. ## + -desc ) the parameter is neccessary.
## -returns
## 
#use strict;

use Misc::Snippets;
use Misc::TemplateLoop;

#use File::Basename;

use Data::Dumper;

use Switch;
use HTML::Template;
use Term::ANSIColor qw(:constants);
# Convert the exported color functions into vars, containing the escape sequences
foreach my $c ( @{$Term::ANSIColor::EXPORT_TAGS{constants}} ){
	$$c = &$c('');
}


use File::Spec;

# if I'd knew xml bettter, I'd used xml to store the data..
# On the other hand, writing this has also been quite informative.
# I also believe, this implementation is faster and uses less memory then a full fledged xml engine.


## Default settings
## They are used, if the documentation in the script doesn't contain the appropriate tags
our $author = 'Michael (misc) Myer';
##
our $email = 'misc.myer@zoho.com';
## 
our $license = 'GPL';
## 
our $year = '2007';
##
our $version = '0.1';
## 
our $webpage = 'http://www.github.com/michael105';
## 
our $description = "";
#our $description = "Not written yet.";
## 
our $usage = "";
##
our $name = "Defaults to the script's/module's filename, if not supplied";


## Holds some info about different license
## NAME will be replaced with the script's name
our $licenseinfo = {
		GPL=><<'ENDGPL'
NAME comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute it
under certain conditions; type 'NAME --license' for details.
ENDGPL
};

## Holds the licenses
our $licenses={ GPL=><<'ENDGPL'
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
ENDGPL
};


## The linebreak string
our $linebreak = "\n";

our @defaultinfotags = qw/author email license year version webpage description usage name/;

our @allowedtags=@defaultinfotags;
push @allowedtags, qw/params args returns desc/;
our $translatetags = { desc=>'description', params=>'args' };
our %tags;

## constructor
sub new{
				my $self = {};
				bless $self;
				$self->setdefaults();

				foreach my $tag ( @allowedtags ){
								$tags{$tag} = 1;
				}
				$name = $0;

				$name =~ s/.*\///;


				return $self;
}

## Inits the default settings of this instance.
## callen by new
sub setdefaults{
				my $self = shift;

				foreach my $tag ( @defaultinfotags ){
								$self->set_element_content( tag=>$tag, content=>[$$tag] );
								$self->set_element_attribute( tag=>$tag, attribute=>'default', value=>'1' );
				}
}	

## Sets the content of a element.
## overwrites the old content !
## params: (named)
## -function: <string> inserts the tag into the description of the function named by this argument
## + -tag: <string> the tag
## + -content: <arrayref> the content
## 
sub set_element_content{
				my $self = shift;
				my %args = @_;

				#print "args:\n",Dumper %args;

				$self->delete_element_content( %args );

				if ( (!exists($args{function} ) || ( $args{function} eq '-')) && ($args{tag} eq 'description') ){ # Script info section, tag description

					my $c = ${$args{content}}[0];
					if ( $c !~ /,\n/ ){
#						${$args{content}}[0]='';

						$self->set_element_content( tag=>'shortdescription', content=>[ $c ] );
#						return if ( scalar( @{$args{content}} ) <2 );
					}
				}


				$self->append_element_content( %args );
				if ( !exists($args{function} ) || ( $args{function} eq '-') ){
						$self->delete_element_attribute( tag=>$args{tag}, attribute=>'default' );
				}
				

						
						# delete the default attribute of the script's main desription,
						# if we've just changed a tag of the script's desc.
}

#*desc
# Deletes a element's content
# Must be overwritten by subclasses
#*args (named)
# -function: <string> deletes the tag of the description of the function, if specified
# + -tag: <string> the tag
sub delete_element_content{ 
				my $self = shift;
				my %args = @_;

				#print Dumper %args;
				if ( exists( $args{function} ) && $args{function} ne '-' ){
								undef $self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{content};
				} else { # delete info about the script/module itself
								undef $self->{doc}->{info}->{$args{tag}}->{content};
				}
}


## Appends content to a tag.
## Creates tag, if content doesn't exist
## To be overwritten by subclasses
## params: (named)
## -function: <string>  appends the tag into the description of the function named by this argument
## + -tag: <string> the tag
## + -content: <arrayref> the content has "\n"'s at the end of each line
## 
sub append_element_content{
				my $self = shift;
				my %args = @_;

				chomp @{$args{content}};
				if ( (!exists($args{function} ) || ( $args{function} eq '-')) && ($args{tag} eq 'description') ){ # Script info section, tag description

					my $c = ${$args{content}}[0];
					if ( ($c !~ /,\n/) && (length($c)>1) ){
#						${$args{content}}[0]='';

						$self->set_element_content( tag=>'shortdescription', content=>[ $c ] );
#						return if ( scalar( @{$args{content}} ) <2 );
					}
				}



				if ( exists( $args{function} ) && $args{function} ne '-' ){
								if ( Misc::Snippets::strexist($self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{content})){
												$self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{content} .= 
													$linebreak.join( $linebreak, @{$args{content}} );
								} else {
												$self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{content} = 
													join( $linebreak, @{$args{content}} );
								}

				} else {
								if ( Misc::Snippets::strexist($self->{doc}->{info}->{$args{tag}}->{content}) ){
												$self->{doc}->{info}->{$args{tag}}->{content} .=
													$linebreak .join( $linebreak, @{$args{content}} );
								} else {
												$self->{doc}->{info}->{$args{tag}}->{content} =
													join( $linebreak, @{$args{content}} );
								}	

				}
}





# returns with the content af an element
#*args (named)
# -function: if defined, returns looks in the description of the function, otherwise in the description of the script
# -tag:	the tag for which to look, defaults to description
#*returns
# The elements content or 0
sub get_element_content{
		my $self = shift;
		my %args = @_;

		if ( exists( $args{function} ) ){
				if ( strexist($self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{content}) ){
						return ( $self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{content});
				} else {
						return 0;
				}
		} else {
				if ( strexist($self->{doc}->{info}->{$args{tag}}->{content}) ) {
						return ($self->{doc}->{info}->{$args{tag}}->{content});
				} else {
						return 0;
				}
		}
}

## Returns all elements of either the info section or the functions
## params: (named) 
##	-functions: if 1, returns all function names
sub get_elements{
	my $self = shift;
	my %args = @_;

	if ( exists( $args{functions}) && $args{functions} ){
		return keys( %{$self->{doc}->{functions}} );

	} else {
		if ( strexist( $args{function} ) ){
			return keys( %{$self->{doc}->{functions}->{$args{function}}} );
		} else {
			return keys( %{$self->{doc}->{info}} );
		}
	}
}
## Returns all atributes of an element
## params: (named)
## -function: <string>  function named by this argument, if empty reads the info section
## + -tag: <string> the tag
## + -attribute: <string> the attribute
## 
## returns:
## An array containing all attribute names
sub get_attributes{
	my $self = shift;
	my %args = @_;

		if ( exists( $args{function} ) && $args{function} ne '-' ){
			return keys( %{$self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{attributes}} );
		} else {
			return keys( %{$self->{doc}->{info}->{$args{tag}}->{attributes}} );
		}


}




## Sets the attribute of an element
## Creates tag, if content doesn't exist
## To be overwritten by subclasses
## params: (named)
## -function: <string>  appends the tag into the description of the function named by this argument
## + -tag: <string> the tag
## + -attribute: <string> the attribute
## + -value: <string> the value
## 
sub set_element_attribute{
				my $self = shift;
				my %args = @_;


				if ( exists( $args{function} ) && $args{function} ne '-' ){
										$self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{attributes}->{$args{attribute}} = $args{value};
				} else {
								$self->{doc}->{info}->{$args{tag}}->{attributes}->{$args{attribute}} = $args{value};
				}
}

## Returns with the attribute of an element, or undef of the attribute doesn't exist
## params: (named)
## -function: <string>  function named by this argument, if empty reads the info section
## + -tag: <string> the tag
## + -attribute: <string> the attribute
## 
## returns:
## The attribute's value, or undef if the attribute doesn't exist
sub get_element_attribute{
		my $self = shift;
		my %args = @_;
		#print "args:\n",Dumper @_;
		#print caller();

		my $attributes;
		if ( exists( $args{function} ) && $args{function} ne '-' ){
						$attributes = $self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{attributes};
		} else {
				$attributes = $self->{doc}->{info}->{$args{tag}}->{attributes};
		}


		if ( exists( $attributes->{$args{attribute}} ) ){
				return $attributes->{$args{attribute}};
		} else {
				return undef;
		}
}

## Delete's the attribute of an element
## params: (named)
## -function: <string>  appends the tag into the description of the function named by this argument
## + -tag: <string> the tag
## + -attribute: <string> the attribute
## 
sub delete_element_attribute{
		my $self = shift;
		my %args = @_;

		my $attributes;
		if ( exists( $args{function} ) && $args{function} ne '-' ){
						$attributes = $self->{doc}->{functions}->{$args{function}}->{$args{tag}}->{attributes};
		} else {
				$attributes = $self->{doc}->{info}->{$args{tag}}->{attributes};
		}

		delete( $attributes->{$args{attribute}} ) if ( defined($attributes) );
}




## calls parsefile for the perl script itself
sub parsescript{
				my $self = shift;

				$self->parsefile( $0 );
}



sub process_info{ # Processes an info block with #* tags
				my $self = shift;
				my @doc = @_;
#				my %info;

				#my $lastline = pop @doc;
				#
#				while ( my $l = shift @doc ){
#								if ( $l =~ /^#\* *(.*)/ ){
#												$tag  = $1;
#												#print "found tag: $tag\n";
#								} else {
#												$l =~ s/^# *//;
#												next if ( length( $l ) <2 );
#												#		print "$l";
#												push @{$info{$tag}}, $l;
#								}
#				}
#				return \%info;

				my $function = '-';
				my $lastline = pop @doc;
				$lastline =~ /sub (\w*)/;
				if ( defined($1) ){
								$function = $1;
				}
#				print "FUNCTION: $function\n";

				my $actualtag = 'description';
				my @tagcontent;
				while ( my $l = shift @doc ){
#							print "      actualtag 1: $actualtag line: $l";
								$l =~ s/^\s*//;
								my $tag;
								$tag = $1 if ( $l =~ /^\* *(\w*):*/);
								#$tag = $1 if ( $l =~ /(\w*):/);
#								print "tag: $tag\n" if ( defined($tag));
								if ( defined($tag) && exists($tags{$tag}) ){ # found a tag
												my $tag = $1;
												if ( scalar( @tagcontent ) >0 ){
																$self->process_tag( tag=>$actualtag, content=>\@tagcontent, function=>$function );
																undef @tagcontent;
												}
												if ( $l =~ /\* *$tag *:* *\w?/ ){ # text comes direct after the tag..
																$l =~ s/\* *$tag *:* *//;
																push @tagcontent, $l if (length($l) >1);
												}

												$actualtag = $tag;
								} else {
#									print "actualtag: $actualtag line: $l";
												push @tagcontent, $l;
								}
				}
				$self->process_tag( tag=>$actualtag, content=>\@tagcontent, function=>$function );



}

sub process_info_slash{ # Processes an info block with '##' tags
				my $self = shift;
				my @doc = @_;

				#print "processinfoslash\n";
				my $function = '-';
				my $lastline = pop @doc;
				$lastline =~ /sub (\w*)/;
				if ( defined($1) ){
								$function = $1;
				}

				my $actualtag = 'description';
				my @tagcontent;
				while ( my $l = shift @doc ){
					#	print "      actualtag 1: $actualtag line: $l";
#								$l =~ s/^\s*//;
								my $tag;
								$tag = $1 if ( $l =~ /(\w*):/);
								#print "tag: $tag\n" if ( defined($tag));
								if ( defined($tag) && exists($tags{$tag}) ){ # found a tag
												my $tag = $1;
												if ( scalar( @tagcontent ) >0 ){
																$self->process_tag( tag=>$actualtag, content=>\@tagcontent, function=>$function );
																undef @tagcontent;
												}
												if ( $l =~ /\w*: *\w?/ ){ # text comes direct after the tag..
																$l =~ s/\w*: *//;
																push @tagcontent, $l if (length($l) > 1 );
												}

												$actualtag = $tag;
								} else {
										#print "actualtag: $actualtag line: $l";
												push @tagcontent, $l;
								}
				}
				$self->process_tag( tag=>$actualtag, content=>\@tagcontent, function=>$function );
}

## processes a tag with it's content.
sub process_tag{
				my $self = shift;
				my %args = @_;
				#print "args: ", join(" - " ,@{$args{content}} );


				my $function = '-';
				$function = $args{function} if ( exists($args{function}) );

				#				print "\nprocess_tag: function: $function\ntag: $args{tag}\n content:".join("",@{$args{content}});
			 $args{tag} = $translatetags->{$args{tag}} if ( exists( $translatetags->{$args{tag}} ) );

			 if ( $args{tag} eq 'args' ){
							 if ( $args{content}->[0] =~ /\(named\)/ ){
											 $args{content}->[0] =~ s/\s*\(named\)\s*//;
											 $self->set_element_attribute( function=>$function, tag=>$args{tag}, attribute=>'named', value=>'1' );
							 }
							 #foreach my $param ( @{$args{content}} ){
							 #			 next if ( ! ( $param =~ /\w?/ ) ); # next when no chars



							 $self->append_element_content( tag=>$args{tag}, content=>$args{content}, function=>$function );
			 } else {
							 $self->append_element_content( tag=>$args{tag}, content=>$args{content}, function=>$function );
			 }
}


## parses the file arg1, sets the variables
sub parsefile{
				my $self = shift;
				my $file = shift;

				#print @f;
				#	print "------\n";

				my ($volume,$path,$fn) = File::Spec->splitpath( $file );
#				print "parsefile: $volume, $path, $fn\n"; 
#				if ( !-e $file ){
#						$file=$fn
				my @f = Misc::Snippets::readfile( filename=>$file );

				$self->set_element_content( tag=>'name', content=>[ $fn ] );


				$self->set_element_attribute( tag=>'location', attribute=>'filename', value=>$fn );
				# Get the absolute path
				if ( !File::Spec->file_name_is_absolute( $volume.$path ) ){
					my $p = File::Spec->rel2abs( $volume.$path );
					# Fix: Remove constructs like /home/micha/prog/perl/test/../modules
					$p =~ s/\/[^\/]*\/\.\.//g;
					$self->set_element_content( tag=>'location', content=>[ $p.'/'.$fn ] );
					$self->set_element_attribute( tag=>'location', attribute=>'path', value=>$p );

				} else {
					$self->set_element_content( tag=>'location', content=>[ $volume.$path.$fn ] );
					$self->set_element_attribute( tag=>'location', attribute=>'path', value=>$volume.$path );
				}

				if ( $f[0] =~ /perl/ ){
					$self->set_element_attribute( tag=>'name', attribute=>'script', value=>1 );
#					$self->set_element_attribute( tag=>'name', attribute=>'module', value=>'' );
				} elsif ( $f[0] =~ /^package (.*);/ ){
#					$self->set_element_attribute( tag=>'name', attribute=>'script', value=>'' );
					$self->set_element_attribute( tag=>'name', attribute=>'module', value=>1 );
					$self->set_element_content( tag=>'name', content=>[$1] );
				}



				my $ln = 1; # linenumber
				# Process the script description, located at the head of the file
				if ( ($f[1] =~ /^##/ ) && !($f[1]=~/^#\*/) ){
								#print "$f[1]";
#								$f[1] =~ /^##\s*(.*)/;
								#			$self->set_element_content( tag=>'shortdescription', content=>[$1] );
								my @doc;
								while ( $f[$ln] =~ /^#/ ){ # '##' style for the description -
																					 # Let's also display the first comment lines as description, if they are 
																					 # commented with '#' only.
												$f[$ln] =~ s/^#* *//;
												#	print "$f[$ln]\n";
												push @doc, $f[$ln];
												$ln++;
								}
								push @doc, "";
								$self->process_info_slash( @doc );
								#$self->append_element_content( tag=>'description', content=>[$f[$ln]]);
				} elsif ($f[1] =~ /^#\*/ )  { # '#* tag found.
					#$f[1] =~ /^#\*\s*(.*)/;
					#			$self->set_element_content( tag=>'shortdescription', content=>[$1] );
								my @doc;
								while ( $f[$ln] =~ /^#/ ){
												$f[$ln] =~ s/^#* *//;
												push @doc, $f[$ln];
												$ln++;
								}
								push @doc, $f[$ln]; # Append also the next line which isn't commented anymore
								$self->process_info( @doc );
				} else {
					print "Found $file\n";
					print "This doesn't look like a documented file.\n";
					exit 1;
				}

				while ( scalar( @f ) > $ln ){
								 if ( $f[$ln] =~ /^##/ ){ 
								 				# ## style description
												my @doc;
												push @doc, " \n" if ( !($f[$ln-2] =~ /##/) );
												while ( $f[$ln] =~ /##/){
																$f[$ln] =~ s/.*##//;
																$f[$ln] =~ s/^ *//;
																push @doc, $f[$ln] if ( length( $f[$ln] ) > 1 );
																$ln++;
												}
												if ( $f[$ln] =~ /^sub / ){ # The extracted doc section belongs to a sub
																push @doc, $f[$ln];
																$self->process_info_slash( @doc );
												} else {
																#push @{$self->{info}->{description}}, "\n";
																#push @{$self->{info}->{description}}, @doc;
																#push @{$self->{info}->{description}}, $f[$ln];
																$self->append_element_content( tag=>'globals', content=>[ @doc, $f[$ln] ] ); # TODO
												}
								} elsif ( $f[$ln] =~ /^#\*/ ){# Taginfo
												my @doc;
												#push @doc, " \n" if ( !($f[$ln-2] =~ /#/) );
												my $c = $ln - 1;

#													print "C:$f[$c]  $c\n";
												while ( $f[$c] =~ /#/){
#													print "C:$f[$c]  $c\n";
													$f[$c] =~ s/^#//;
													$f[$c] =~ s/^ *//;
													unshift @doc, $f[$c] if ( length( $f[$c] ) > 1 );
													$c--;
												}


												while ( $f[$ln] =~ /#/){
																$f[$ln] =~ s/^#//;
																$f[$ln] =~ s/^ *//;
																push @doc, $f[$ln] if ( length( $f[$ln] ) > 1 );
																$ln++;
												}
												if ( $f[$ln] =~ /^sub / ){ # The extracted doc section belongs to a sub
																push @doc, $f[$ln];
																$self->process_info( @doc );
												} else {
																#push @{$self->{info}->{description}}, "\n";
																#push @{$self->{info}->{description}}, @doc;
																#push @{$self->{info}->{description}}, $f[$ln];
																$self->append_element_content( tag=>'globals', content=>[ @doc, $f[$ln] ] ); # TODO
												}
								
								}								
								$ln++;
				}

				#	print "Dump:\n", Dumper( $self->{doc} ),"\n";
				#print "description: \n";
				#print @{$self->{info}->{description}->{content}};
}


## Returns info about the script ( name, version, author, Copyright ) as string
sub script_info{
		my $self = shift;
		return $self->get_element_content(tag=>'name')." Version ".$self->get_element_content(tag=>'version').
						", (C) ".$self->get_element_content(tag=>'year')." ".$self->get_element_content(tag=>'author');
}

## Returns info about the license, formatted with \n
sub license_info{
		my $self = shift;

		if ( exists($licenseinfo->{$self->get_element_content( tag=>'license' )}) ){
				my $l = $licenseinfo->{$self->get_element_content( tag=>'license' )};
				$l =~ s/NAME/$name/g;
				return $l;
		} else {
				return "License: ",$self->get_element_content( tag=>'license' ),"\n";
		}
}

## Prints the script's version and exits the script.
sub print_version{
				my $self = new();
				$self->parsescript(); 
				
				print $self->script_info(),"\n\n";
				print $self->license_info(),"\n";

				exit 0;

}
				
## Print's the scripts description and usage, exits.
sub print_help{
				my $self = new();
				$self->parsescript(); 

				print $self->script_info(),"\n";
				print $self->license_info();
				print "\n";
				print $self->get_element_content(tag=>'description')."\n";
				print "Usage:\n".$self->get_element_content(tag=>'usage')."\n" if ( !$self->get_element_attribute( tag=>'usage', attribute=>'default' ) );
				print "Arguments:\n".$self->get_element_content(tag=>'args')."\n" if ( !$self->get_element_attribute( tag=>'args', attribute=>'default' ) );

				exit 0;
}

##
sub print_license{
		my $self = new();
		$self->parsescript();

		print $self->script_info(),"\n\n";
		
		my $l = $self->get_element_content( tag=>'license' );
		chomp $l;
		if ( exists( $licenses->{$l} ) ){
				print $licenses->{$l},"\n";
		} else {
				print "No info about this license stored.\nPlease visit (someurl) for more info..\n\n";
		}

		exit 0;
}


## Returns with a string containing the documentation of a script or package
## params: (named)
## 	-filename
##	-type: one of:  plain (plain text output)			
##					ansicolor (plain with ansi color codes)
##					html
##					pod
##					compactcolor
## 					desc (short description)	
##          adoc (asciidoc)
##	-noextradoc:	if true, won't display website, author and license					
sub documentation{
	my %args = @_;


	if ( !strexist( $args{filename} ) ){
		print "Error! No filename supplied in documentation::get_script_docu\n";
		exit 1;
	}
	if ( ! -e $args{filename} ){
		die "Error! $args{filename} doesn't exist in documentation::get_script_docu\n";
	}
	my $doc = new();
	$doc->parsefile( $args{filename} );

	my $tmplname = "TMPL_$args{type}";
	my $tmpl = HTML::Template->new( scalarref=> \$$tmplname, die_on_bad_params=>0 );

	foreach my $tag ( $doc->get_elements() ){
		$tmpl->param( $tag, parsevalue($doc->get_element_content( tag=>$tag ), $args{type}) );
		foreach my $attribute ( $doc->get_attributes( tag=>$tag ) ){
			$tmpl->param( $tag.'_'.$attribute, parsevalue($doc->get_element_attribute( tag=>$tag, attribute=>$attribute ), $args{type}) );
		}

	}

	my $l = $doc->get_element_content( tag=>'license' );
	chomp $l;

	if ( exists( $licenses->{$l} ) ){
		$tmpl->param('licensetext', parsevalue($licenses->{$l}, $args{type} ));
	}


	my $loop = Misc::TemplateLoop->new();
	foreach my $function ( $doc->get_elements( functions=>1 ) ){
		my %values;
		$values{functionname} = $function;

		foreach my $element ( $doc->get_elements( function=>$function ) ){
#			print "element: $element\n";
			$values{$element} = parsevalue($doc->get_element_content( function=>$function, tag=>$element ),$args{type}, 4);
#			print $doc->get_element_content( function=>$function, tag=>$element ),"\n";
		}
		$loop->add( %values );
	}
	$loop->sort( 'functionname' );
	$tmpl->param( 'functionloop', $loop->arrayref() );

	$tmpl->param( 'noextradoc', 1 ) if ( exists($args{noextradoc}) && $args{noextradoc} );

	return $tmpl->output();
}

#
sub parsevalue{
	my $value = shift;
	my $type = shift;
	my $i = shift || 0;

	$value =~ s/^\n//;
	switch ( $type ){
		case 'plain'	{ $value =~ s/\n/\n  /g; for (0..$i){ $value =~ s/^/ /; $value =~ s/\n/\n /g;} }
		case 'ansicolor'	{ $value =~ s/\n/\n  /g; for (0..$i){ $value =~ s/^/ /; $value =~ s/\n/\n /g;} }
		case 'pod'	{ $value =~ s/\n/\n /g; $value=~s/^/ /; }
	}
	
	return $value;
}
our $TMPL_desc = '<TMPL_IF name=shortdescription><TMPL_VAR name=shortdescription><TMPL_ELSE><TMPL_VAR name=description></TMPL_IF>'."\n";

# shameless copied from pod2html..
our $TMPL_html = << "END_TMPL";
<html>
	<head>
		<title><TMPL_VAR name=name></title>
	</head>
	<body>

<body style="background-color: white">
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="block" style="background-color: #cccccc" valign="middle">
<big><strong><span class="block"><TMPL_VAR name=name></span></strong></big>
</td></tr>
</table>


<p><a name="__index__"></a></p>

<ul>

	<li><a href="#name">NAME</a></li>
	<li><a href="#synopsis">SYNOPSIS</a></li>
	<li><a href="#description">DESCRIPTION</a></li>
	<li><a href="#methods">METHODS</a></li>
	<li><a href="#author">AUTHOR</a></li>
	<li><a href="#copyright">COPYRIGHT</a></li>
</ul>



<hr />
<p>
</p>
<h1><a name="name">NAME</a></h1>
<p> <TMPL_VAR name=name> <TMPL_IF name=shortdescription>- <TMPL_VAR name=shortdescription></TMPL_IF></p>
<p>Version: <TMPL_VAR name=version><br/> 
  Location: <TMPL_VAR name=location>
</p>

<p><a href="#__index__"><small>Top</small></a></p><hr />

<TMPL_UNLESS name=usage_default>
<TMPL_IF name=name_script>
<h1><a name="usage">USAGE</a></h1>
<TMPL_ELSE>
<h1><a name="synopsis">SYNOPSIS</a></h1>
</TMPL_IF>

<pre>
<TMPL_VAR name=usage>
</pre>

<p><a href="#__index__"><small>Top</small></a></p><hr />

</TMPL_UNLESS>


<h1><a name="description">DESCRIPTION</a></h1>

<pre>
  <TMPL_VAR name=description>
</pre>


<p><a href="#__index__"><small>Top</small></a></p><hr />


<TMPL_IF name=name_script>

<h1><a name="arguments">ARGUMENTS</a></h1>

<pre>

  <TMPL_VAR name=args>

</pre>


<p><a href="#__index__"><small>Top</small></a></p><hr />


</TMPL_IF>

<TMPL_IF name=globals>

<h1><a name="globals">GLOBAL VARS</a></h1>

<pre>

  <TMPL_VAR name=globals>

</pre>


<p><a href="#__index__"><small>Top</small></a></p><hr />


</TMPL_IF>

<TMPL_UNLESS name=name_script>


<h1><a name="methods">METHODS</a></h1>

<dl>

<TMPL_LOOP name=functionloop>

<strong><a name="item_command"><TMPL_VAR name=functionname></a></strong>
<dd><pre><TMPL_IF name=description><TMPL_VAR name=description>

</TMPL_IF><TMPL_IF name=usage>Usage:

<TMPL_VAR name=usage>
</TMPL_IF><TMPL_IF name=args>Arguments:

<TMPL_VAR name=args>

</TMPL_IF><TMPL_IF name=returns>Returns:

<TMPL_VAR name=returns>

</TMPL_IF>
</pre></dd>
</TMPL_LOOP>


<p><a href="#__index__"><small>Top</small></a></p><hr />

</TMPL_UNLESS>



<TMPL_UNLESS name=noextradoc>

<h1><a name="website">WEBSITE</a></h1>

<p>

  <a href="<TMPL_VAR name=webpage>"><TMPL_VAR name=webpage></a>

</p>


<p><a href="#__index__"><small>Top</small></a></p><hr />

<h1><a name="author">AUTHOR</a></h1>

<p>

	<TMPL_VAR name=author>

</p>

<p>

	<a href="mailto:<TMPL_VAR name=email>"><TMPL_VAR name=email></a>

</p>

<p><a href="#__index__"><small>Top</small></a></p><hr />


<h1><a name="license">LICENSE</a></h1>

<p>
<pre>
<TMPL_VAR name=license>
<TMPL_IF name=licensetext><TMPL_VAR name=licensetext><TMPL_ELSE><TMPL_VAR name=license>  </TMPL_IF>

</pre>
</p>


<p><a href="#__index__"><small>Top</small></a></p><hr />

</TMPL_UNLESS>

	</body>
</html>

END_TMPL



our $TMPL_pod = << "END_TMPL";

=head1 NAME

 <TMPL_VAR name=name> <TMPL_IF name=shortdescription>- <TMPL_VAR name=shortdescription></TMPL_IF>
  Version: <TMPL_VAR name=version> 
  Location: <TMPL_VAR name=location>

=head1 DESCRIPTION

  <TMPL_VAR name=description>

<TMPL_UNLESS name=usage_default>=head1 <TMPL_IF name=name_script>USAGE<TMPL_ELSE>SYNOPSIS</TMPL_IF>

<TMPL_VAR name=usage>
</TMPL_UNLESS><TMPL_IF name=name_script>=head1 ARGUMENTS
 
 <TMPL_VAR name=args>
</TMPL_IF><TMPL_IF name=globals>
=head1 GLOBAL VARS

<TMPL_VAR name=globals>
</TMPL_IF><TMPL_UNLESS name=name_script>
=head1 METHODS

<TMPL_LOOP name=functionloop>
=head2 <TMPL_VAR name=functionname>

=over
<TMPL_IF name=description><TMPL_VAR name=description>

</TMPL_IF><TMPL_IF name=usage>Usage:
<TMPL_VAR name=usage>

</TMPL_IF><TMPL_IF name=args>Arguments:


<TMPL_VAR name=args>


</TMPL_IF><TMPL_IF name=returns>Returns:

<TMPL_VAR name=returns>

</TMPL_IF>
=back
</TMPL_LOOP>
</TMPL_UNLESS>

<TMPL_UNLESS name=noextradoc>
=head1 WEBSITE
 
<TMPL_VAR name=webpage>

=head1 AUTHOR

<TMPL_VAR name=author> <TMPL_VAR name=email>

=head1 LICENSE

<TMPL_IF name=licensetext>
<TMPL_VAR name=licensetext>
  <TMPL_ELSE>
  <TMPL_VAR name=license>
  </TMPL_IF>

  <TMPL_VAR name=website>
</TMPL_UNLESS>
END_TMPL


#$BOLD $BLUE<TMPL_VAR name=location_filename>
our $TMPL_plain = << "END_TMPL";
NAME
 <TMPL_VAR name=name> <TMPL_IF name=shortdescription>- <TMPL_VAR name=shortdescription></TMPL_IF>
  Version: <TMPL_VAR name=version> 
  Location: <TMPL_VAR name=location>


DESCRIPTION
  <TMPL_VAR name=description>

<TMPL_UNLESS name=usage_default><TMPL_IF name=name_script>USAGE<TMPL_ELSE>SYNOPSIS</TMPL_IF>
  <TMPL_VAR name=usage>
</TMPL_UNLESS><TMPL_IF name=name_script>ARGUMENTS
  <TMPL_VAR name=args>
</TMPL_IF><TMPL_IF name=globals>
GLOBAL VARS
  <TMPL_VAR name=globals>
</TMPL_IF><TMPL_UNLESS name=name_script>
METHODS
<TMPL_LOOP name=functionloop>
<TMPL_VAR name=functionname>
<TMPL_IF name=description>  <TMPL_VAR name=description>

</TMPL_IF><TMPL_IF name=usage>    Usage:

    <TMPL_VAR name=usage>

</TMPL_IF><TMPL_IF name=args>    Arguments:

    <TMPL_VAR name=args>

</TMPL_IF><TMPL_IF name=returns>    Returns:

    <TMPL_VAR name=returns>

</TMPL_IF></TMPL_LOOP>
</TMPL_UNLESS>
<TMPL_UNLESS name=noextradoc>
WEBSITE
  <TMPL_VAR name=webpage>

AUTHOR
  <TMPL_VAR name=author> <TMPL_VAR name=email>

LICENSE
  <TMPL_IF name=licensetext>
  <TMPL_VAR name=licensetext>
  <TMPL_ELSE>
  <TMPL_VAR name=license>
  </TMPL_IF>

  <TMPL_VAR name=website>
</TMPL_UNLESS>
END_TMPL

#$BOLD $BLUE<TMPL_VAR name=location_filename>$RESET
our $TMPL_ansicolor = << "END_TMPL";
$GREEN<TMPL_VAR name=nope>NAME$RESET
 <TMPL_VAR name=name> <TMPL_IF name=shortdescription>- <TMPL_VAR name=shortdescription></TMPL_IF>
  Version: <TMPL_VAR name=version> 
  Location: <TMPL_VAR name=location>


$GREEN<TMPL_VAR name=nope>DESCRIPTION$RESET
  <TMPL_VAR name=description>

<TMPL_UNLESS name=usage_default><TMPL_IF name=name_script>$GREEN<TMPL_VAR name=nope>USAGE$RESET<TMPL_ELSE>$GREEN<TMPL_VAR name=nope>SYNOPSIS$RESET</TMPL_IF>
  <TMPL_VAR name=usage>
</TMPL_UNLESS><TMPL_IF name=name_script>$GREEN<TMPL_VAR name=nope>ARGUMENTS$RESET
  <TMPL_VAR name=args>
</TMPL_IF><TMPL_IF name=globals>
$GREEN<TMPL_VAR name=nope>GLOBAL VARS$RESET
  <TMPL_VAR name=globals>
</TMPL_IF><TMPL_UNLESS name=name_script>
$GREEN<TMPL_VAR name=nope>METHODS$RESET
<TMPL_LOOP name=functionloop>
$BOLD $CYAN<TMPL_VAR name=functionname>$RESET
<TMPL_IF name=description>  <TMPL_VAR name=description>

</TMPL_IF><TMPL_IF name=usage>    Usage:

    <TMPL_VAR name=usage>

</TMPL_IF><TMPL_IF name=args>    Arguments:

    <TMPL_VAR name=args>

</TMPL_IF><TMPL_IF name=returns>    Returns:

    <TMPL_VAR name=returns>

</TMPL_IF></TMPL_LOOP>
</TMPL_UNLESS>
<TMPL_UNLESS name=noextradoc>
$GREEN<TMPL_VAR name=nope>WEBSITE$RESET
  <TMPL_VAR name=webpage>

$GREEN<TMPL_VAR name=nope>AUTHOR$RESET
  <TMPL_VAR name=author> <TMPL_VAR name=email>

$GREEN<TMPL_VAR name=nope>LICENSE$RESET
  <TMPL_IF name=licensetext>
  <TMPL_VAR name=licensetext>
  <TMPL_ELSE>
  <TMPL_VAR name=license>
  </TMPL_IF>

  <TMPL_VAR name=website>
</TMPL_UNLESS>
END_TMPL


our $TMPL_compactcolor = << "END_TMPL";
$GREEN<TMPL_VAR name=nope>NAME$RESET
 <TMPL_VAR name=name> <TMPL_IF name=shortdescription>- <TMPL_VAR name=shortdescription></TMPL_IF>
  Version: <TMPL_VAR name=version> 
  Location: <TMPL_VAR name=location>
$GREEN<TMPL_VAR name=nope>DESCRIPTION$RESET
  <TMPL_VAR name=description>
<TMPL_UNLESS name=usage_default><TMPL_IF name=name_script>$GREEN<TMPL_VAR name=nope>USAGE$RESET<TMPL_ELSE>$GREEN<TMPL_VAR name=nope>SYNOPSIS$RESET</TMPL_IF>
  <TMPL_VAR name=usage>
</TMPL_UNLESS><TMPL_IF name=name_script>$GREEN<TMPL_VAR name=nope>ARGUMENTS$RESET
  <TMPL_VAR name=args>
</TMPL_IF><TMPL_IF name=globals>
$GREEN<TMPL_VAR name=nope>GLOBAL VARS$RESET
  <TMPL_VAR name=globals>
</TMPL_IF><TMPL_UNLESS name=name_script>
$GREEN<TMPL_VAR name=nope>METHODS$RESET
<TMPL_LOOP name=functionloop>
$BOLD $CYAN<TMPL_VAR name=functionname>$RESET<TMPL_IF name=description>
<TMPL_VAR name=description></TMPL_IF><TMPL_IF name=usage>
  Usage:
    <TMPL_VAR name=usage>
</TMPL_IF><TMPL_IF name=args>    
Arguments:
    <TMPL_VAR name=args>
</TMPL_IF><TMPL_IF name=returns>    
Returns:
    <TMPL_VAR name=returns>
</TMPL_IF>
</TMPL_LOOP>
</TMPL_UNLESS>
<TMPL_UNLESS name=noextradoc>
$GREEN<TMPL_VAR name=nope>WEBSITE$RESET
  <TMPL_VAR name=webpage>

$GREEN<TMPL_VAR name=nope>AUTHOR$RESET
  <TMPL_VAR name=author> <TMPL_VAR name=email>

$GREEN<TMPL_VAR name=nope>LICENSE$RESET
  <TMPL_IF name=licensetext>
  <TMPL_VAR name=licensetext>
  <TMPL_ELSE>
  <TMPL_VAR name=license>
  </TMPL_IF>

  <TMPL_VAR name=website>
</TMPL_UNLESS>
END_TMPL


our $TMPL_adoc = << "END_TMPL";

== <TMPL_VAR name=name> 

=== NAME
 <TMPL_VAR name=name> <TMPL_IF name=shortdescription>- <TMPL_VAR name=shortdescription></TMPL_IF>
  Version: <TMPL_VAR name=version> 
  Location: <TMPL_VAR name=location>


=== DESCRIPTION
  <TMPL_VAR name=description>

<TMPL_UNLESS name=usage_default><TMPL_IF name=name_script>USAGE<TMPL_ELSE>SYNOPSIS</TMPL_IF>
  <TMPL_VAR name=usage>
</TMPL_UNLESS><TMPL_IF name=name_script>ARGUMENTS
  <TMPL_VAR name=args>
</TMPL_IF><TMPL_IF name=globals>
=== GLOBAL VARS
  <TMPL_VAR name=globals>
</TMPL_IF><TMPL_UNLESS name=name_script>
=== METHODS
<TMPL_LOOP name=functionloop>
<TMPL_VAR name=functionname>::
<TMPL_IF name=description>  <TMPL_VAR name=description>

</TMPL_IF><TMPL_IF name=usage>    Usage:

    <TMPL_VAR name=usage>

</TMPL_IF><TMPL_IF name=args>    - Arguments:

    <TMPL_VAR name=args>

</TMPL_IF><TMPL_IF name=returns>   - Returns:

    <TMPL_VAR name=returns>

</TMPL_IF></TMPL_LOOP>
</TMPL_UNLESS>
<TMPL_UNLESS name=noextradoc>
=== WEBSITE
  <TMPL_VAR name=webpage>

=== AUTHOR
  <TMPL_VAR name=author> <TMPL_VAR name=email>

=== LICENSE
  <TMPL_IF name=licensetext>
  <TMPL_VAR name=licensetext>
  <TMPL_ELSE>
  <TMPL_VAR name=license>
  </TMPL_IF>

  <TMPL_VAR name=website>
</TMPL_UNLESS>
END_TMPL









1;
