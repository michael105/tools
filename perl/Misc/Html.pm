package Misc::Html;
## Some helper subs related to html 
## Needs use utf8; in the calling module !!

our @EXPORT = qw/umlautstohtml/;
use Exporter;
our @ISA = qw(Exporter);
use utf8;




my $umlaute = { 

'ä'=>'auml',
'Ä'=>'Auml',
'ö'=>'ouml',
'Ö'=>'Ouml',
'ü'=>'uuml',
'Ü'=>'Uuml',
'ß'=>'szlig'
};
my $u = '&';

##
sub umlautstohtml{
	my $html = shift;
	$html =~ s/([äüöÄÜÖß])/\x26$umlaute->{$1};/g;
	return $html;
}


1;





