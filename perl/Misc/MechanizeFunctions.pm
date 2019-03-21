package Misc::MechanizeFunctions;
## Some  helper functions for WWW::Mechanize;

use Debug;

our @EXPORT = qw/mechsave mechload find_link_by_attr follow_link_by_attr pdump clear_log/;
use Exporter;
our @ISA = qw(Exporter);


use WWW::Mechanize;

use tables;


use Unicode::UTF8simple;

use Data::Dumper::Simple;


our $unic =  new Unicode::UTF8simple;



# converts the given string from utf8
sub utf{
		my $s = shift;
		return $unic->fromUTF8('iso-8859-1', $s);
}


# Returns the given string, or '' if the string is not defined
sub s{
		my $s = shift;
		return $s if defined($s);
		return '';
}




# saves the html content into the file page.html
sub mechsave{
		my $m = shift;
		my $fn = shift || 'page.html';
		open F, ">$fn";
		print F $m->content;
		close F;
}

# Loads a file into the Mechanize instance
# params: 
# 	A ref to the mechanize instance
# 	The filename
sub mechload{
		my $m = shift;
		my $fn = shift;

		$m->{base} = 'http://localhost/';
		open F, "<$fn";
		$m->update_html( join('',<F>) );
		close F;
}
	


# finds a link by attribute, regular expression, 
# returns (linknumber, link_object),
# 	(0,undef) if not found 
sub find_link_by_attr{
		my $m = shift;
		my $attribute = shift;
		my $expr = shift;

		#print 'sub find_link_by_attr{ ', "$attribute    $expr\n";
		my $b = 1;
		foreach ($m->links){
				my $a = $_->attrs;
				#print Dumper( $a );
				return ($b,$_) if ( exists( $a->{$attribute}) && ( utf($a->{$attribute}) =~ /$expr/ ) );
				$b++;
		}

		return (0,undef);
}


# Follows a link, specified by attribute, expression
# Returns 1 on success, otherwise 0
sub follow_link_by_attr{
		my $m = shift;
		my $attribute = shift;
		my $expr = shift;

		my ($nr,$l) = find_link_by_attr( $m, $attribute, $expr );

		#print "nr: $nr, text: ",$l->text,"\n";

		return 0 if ( !$nr );

		$m->follow_link(n=>$nr);

		return 1;
}

# Clears the log dir
sub clear_log{
		
		unlink "log/count" if ( -e "log/count" );
}

# Dumps out info about a page.
sub pdump{
		my $m = shift;

		debug "\n";

		my $c = 0;
		if ( open (F, "<log/count") ){
				$c = <F>;
				close F;
		}
		$c++;
		open F,">log/count";
		print F $c;
		close F;

		mechsave($m, "log/$c.html");
		mechsave($m, "log/lastpage.html" );
		

		my $uri = $m->uri;
#		my $u = $uri->path();
		debug "Url: ". ($uri||'')  ."\nLinks:\n";
		
#		my $t = tables->new( #widths=>[20,40], 
#				titles=>[qw/Col1 Col2/] );
#
#		$t->add_row( "Hey ho.-.!", "sowas.." );
#		$t->add_row( "Umbrüche..\naha?", "cd" );
#		$t->add_row( "Umbrueche 2.\naha?", "\nasdf\nas" );
#		$t->add_row( "Eine sehr lange Zeile, sollte laenger sein.", "ss" );
#
#		$t->auto_widths(11);
#		$t->show();
#
#		return;

		my $t = tables->new( titles=>[qw/text attrs url/],
				maxwidths=>[20,0,40]);
		map {
				#print " text: ".$_->text."    url: ".$_->url."\n";
				my $att = '';
				my $attrs = $_->attrs;
				foreach (keys %{$attrs} ){
#						print "key: $_ value: $attrs->{$_}\n";
						$att .= "$_=$attrs->{$_}\n";
				}
				$t->add_row( utf($_->text), utf($att), $_->url );
		}	$m->links;

		$t->show();




#		my $p = 0;
#		ShowTable( [qw/Text Attrs/],
#				[qw/text text/],
#				[50,50],
#				sub{
#						my $c = shift;
#						if ( $c ){
#								$p = 0;
#								return;
#						}
#						my @a = $m->links;
#						return if (!exists( $a[$p] ) );
#						my $r = $a[$p];
#						$p++;
#						my $att='';
#						my $attrs = $r->attrs;
#						foreach (keys %{$attrs} ){
#								$att .= "$_=$attrs->{$_} --- ";
#						}
#						return ( utf($r->text), $att );
#				}
##				sub {
##						my ( $value, $type, $max_width, $width, $precision, $showmode ) = @_;
##						$value;
##				}
#		);


		debug "Forms:\n";
		my $n = 1;
		map {
				debug "Form number: $n\n";
				$n++;

				#		my @rows;
				$t = tables->new( titles=>[qw/name value type possible_values/] );
				foreach ($_->inputs) {
						$t->add_row( utf(&s($_->name)),&s($_->value), &s($_->type), &s($_->possible_values) );
						#push @rows, [utf(&s($_->name)),&s($_->value), &s($_->type), &s($_->possible_values)];
#						print "  input name: ".&s($_->name).
#						"   value: ".&s($_->value).
#						"    possible values:".&s($_->possible_values).
#						"    type:".&s($_->type)."\n";
				};
				$t->show();
				debug "\n";


#				 $p = 0;
#				ShowBoxTable( [qw/Name Value Type Possible_Values/], #show_mode=>'Table', 
#						[qw/text text text text/],
#						[50,20,20,20],
#						
#						sub{
#								my $a = shift;
#								#print "a: $a\n";
#								if ( $a ){
#										$p = 0;
#										return;
#								}
#								#print "row $p : $rows[$p]\n";
#								return if ( !exists( $rows[$p]) );
#								my @ar = @{$rows[$p]};
#								$p++;
#								#print "ar[0] $ar[0]\n";
#								return @ar;
#						}
#				);

				#
#				$_->dump();
		} $m->forms;



		debug "\n";

}





