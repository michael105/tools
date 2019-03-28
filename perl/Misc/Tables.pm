package Misc::Tables;
## Dump out a table
## usage:
## use Misc::Tables;
## my $table = Misc::Tables->new( titles=>[ qw/col1 col2/ ], bordertype=>'normal' );
## $table->add_row( 'Value1', 'Value2' );
## $table->show();

#use Debug;
use Switch;
use warnings;

## Borders
# Contains the chars of the borders, order: normal, none, compact

#@{$border{titletl}} = ( 1, 0 ); # print titles top line
@{$border{titleth}} = ('=', '', ''); # titles top
@{$border{titletlc}} = ('+=', '', ''); # titles top left corner
@{$border{titletrc}} = ("=+\n", '',''); # titles top right corner
@{$border{titletc}} = ('=+=', '',''); # titles top crossings

#@{$border{titlebl}} = ( 1, 0 ); # print titles bottom line
@{$border{titlebh}} = ('=', '', '-'); # titles bottom
@{$border{titleblc}} = ('+-', '', ''); # titles bottom left corner
@{$border{titlebrc}} = ("=+\n", '', "\n"); # titles bottom right corner
@{$border{titlebc}} = ('=+=', '', '-+-'); # titles bottom crossings

@{$border{titlev}} = (' | ', ' ', '   '); # titles vertical
@{$border{titlelv}} = ('| ', '', ''); # titles left vertical
@{$border{titlerv}} = (" |\n", "\n", "\n"); # titles right vertical


@{$border{tablev}} = (' | ', ' ', '   '); # table vertical
@{$border{tablelv}} = ('| ', '', ''); # table left vertical
@{$border{tablerv}} = (" |\n", "\n", "\n"); # table right vertical

#@{$border{tablel}} = ( 1, 0); # print tables horizontal lines
@{$border{tableh}} = (' ', '', ''); # table horizontal
@{$border{tablec}} = (' + ', '', ''); # table crossings
@{$border{tablelc}} = ('+ ', '', ''); # table left crossings
@{$border{tablerc}} = (" +\n", '', ''); # table right crossings

#@{$border{tablebl}} = ('-', ' '); # print tables bottom horizontal line
@{$border{tablebh}} = ('-', '', ''); # table bottom horizontal
@{$border{tablebc}} = ('-+-', '', ''); # table bottom crossings
@{$border{tableblc}} = ('+-', '', ''); # table bottom left corner
@{$border{tablebrc}} = ("-+\n", '', ''); # table bottom right corner








use Term::ReadKey;
## Constructor
## params:
## -titles: Ref to an array with the colnames
## -widths:	Ref to an array with the cols' width in chars
## -maxwidths: Ref to an array containing the maximum colwidths in chars
## -bordertype: 'normal', 'none', 'compact'  - defaults to normal
## -align: 'left' (default), 'right'
## -termwidth: optional, otherwise tries to determine the size automatic..
sub new{
		my $class = shift;
		my %args = @_;

		my $self = {};
		bless $self, $class;

		$self->{data} = [];


		$self->set_titles( @{$args{titles}} ) if (defined($args{titles}));
		$self->set_widths( @{$args{widths}} ) if (defined($args{widths}));
		$self->set_maxwidths( @{$args{maxwidths}} ) if (defined($args{maxwidths}));
		$self->set_bordertype( $args{bordertype} || $args{border} || 'normal' );
		$self->set_alignment( $args{align} || 'left' );
		$self->set_termwidth( $args{termwidth} || 0 );



		return $self;
}

use Data::Dumper::Simple;
##
sub add_row{
		my $self = shift;
		my @data = @_;
#		print Dumper(@data);
#		print "Count: ",scalar(@data),"\n";

		push @{$self->{data}}, \@data;
		if ( !defined($self->{titles}) ){
			$self->{titles} = [];
		}
		for ( scalar(@{$self->{titles}}) .. (scalar(@data)-1) ){
#			print "PUSH";
			push @{$self->{titles}}, " ";
		}
}


## 
sub set_titles{
		my $self = shift;
		@{$self->{titles}} = @_;
}

## 
sub set_widths{
		my $self = shift;
		@{$self->{widths}} = @_;
}

## 
sub set_maxwidths{
		my $self = shift;
		@{$self->{maxwidths}} = @_;
}

## 
sub set_bordertype{
		my $self = shift;
		my $border = shift || 'normal';

		switch ($border){
			case 'normal' { $self->{border} = 0; }
			case 'none' { $self->{border} = 1; }
			case 'compact' { $self->{border} = 2; }

			else { $self->{border} = 0; }
		}
}


## 
sub set_alignment{
		my $self = shift;
		my $align = shift || 'left';
		$self->{align} = $align;
}

## 
sub set_termwidth{
		my $self = shift;
		my $tw = shift || 0;
		$self->{termwidth} = $tw;
}



# 
sub print_separator{
		my $self = shift;
		my $type = shift;


		my $c = '';
		print $border{$type.'lc'}[$self->{border}];
		foreach my $w ( @{$self->{widths}} ){
				print $c;
#				print $border{$type.'h'}[$self->{border}];
				print $border{$type.'h'}[$self->{border}] for (1..$w);
				$c = $border{$type.'c'}[$self->{border}];
		}
		print "$border{$type.'rc'}[$self->{border}]";
}	


# 
sub print_titles{
		my $self = shift;

#		print join("\n", @{$self->{titles}}),"\n";

		$self->print_row( type=>'title', cols=>$self->{titles} );
}

# 
sub print_row{
	my $self = shift;
	my %args = @_;
	my $type = $args{type};
	my @cols = @{$args{cols}};

#		print join("\n", @cols ),"\n";

	my @toprint;
	my $fine = 1;

	my @widths = @{$self->{widths}};

	my $vertical = $border{$type.'lv'}[$self->{border}];

	for my $c (0..@widths-1) {
		print $vertical;
		
		$cols[$c] = '' if ( !defined($cols[$c]) );
		my $content = $cols[$c];
#				print "\ncont: $content\nc: $c\n";
		if ( $cols[$c] =~ s/(.*)\n// ){
			$fine = 0;
			$content = $1;
		} else {
			$cols[$c] = '';
		}

		if ( length( $content ) > $widths[$c] ){
			my $c2 = $content;
			$content = substr( $content, 0, $widths[$c] );
			$cols[$c] = substr( $c2, $widths[$c] )."\n$cols[$c]";
			$fine = 0;
		}
		$self->print_cell_content( $c, $content );
		#print ' ';
		
		$vertical = $border{$type.'v'}[$self->{border}];
	}
	print $border{$type.'rv'}[$self->{border}];
	return if ( $fine );

	$self->print_row( type=>$type, cols=>\@cols );

}

#
sub print_cell_content{
		my $self = shift;
		my $col = shift;
		my $content = shift;

		if ( $self->{align} eq 'left' ){
				print $content;
				for ( 1..(${$self->{widths}}[$col] - length($content) ) ){
						print ' ';
				}
			} else {
				for ( 1..(${$self->{widths}}[$col] - length($content) ) ){
						print ' ';
				}
				print $content;
			}
}

# 
sub auto_widths{
		my $self = shift;
		my $max = shift;

		my $cols = @{$self->{titles}};
		#print "titles: ", join(" - ", @{$self->{titles}} ),"\n";
		my $ex = $cols * 3 + 3;
		$max -= $ex;

		my @w;
		my $c = 0;

		foreach my $col ( @{$self->{titles}} ){
			foreach my $cellline ( split("\n",$col ) ){
					if ( !defined($w[$c]) || length($cellline) > $w[$c] ){
							$w[$c] = length($cellline);
					}
			}
			$c++;
		}


		foreach my $col ( @{$self->{data}} ){
				for my $c ( 0..$cols-1){
					${$col}[$c] = '' if ( !defined(${$col}[$c]) );
						foreach my $cellline ( split("\n",${$col}[$c] ) ){
								if ( !defined($w[$c]) || length($cellline) > $w[$c] ){
										$w[$c] = length($cellline);
								}
						}
				}
		}

		if ( exists( $self->{maxwidths} ) ){
				my $a = 0;
				foreach ( @{$self->{maxwidths}} ){
						if ( $_ ) {
								$w[$a] = $_;
						}
						$a++;
				}
		}
				

		sub gw {
				my $max = shift;
				my @widths = @_;
				my $a = 0;
				foreach (@widths){
						$a+=$_;
				}
				return 1 if ( $a > $max );
				return 0;
		}
		
		while ( gw($max, @w) ){
				my $a = 0;
				my $b = 0;
				my $d = 0;
				foreach my $c ( @w ){
						if ( $c > $b ){
								$b = $c;
								$a = $d;
						}
#						print "a $a  b $b  c $c  d $c\n";
						$d++;
				}
				$b--;
				$w[$a] = $b;

		}
		
		$self->{widths} = \@w;


}

## Dumps out the table
sub show{
		my $self = shift;

		if ( !exists( $self->{widths} ) ){
			if ( $self->{termwidth} ){
					$self->auto_widths($self->{termwidth});
				} else {
				if ( defined( $ENV{COLUMNS} ) ) {
						$self->auto_widths($ENV{COLUMNS});
				} else {
						my @a = Term::ReadKey::GetTerminalSize;
#						print "a: $a[0]\n";
						if ( $a[0] ){
								$self->auto_widths($a[0]-1);
						} else {
								$self->auto_widths(80);
						}
				}
			}
		}
		#	print "Widths:", join(" - ", @{$self->{widths}}),"\n";


		$self->print_separator('titlet'); # titles top
		$self->print_titles;
#		$self->print_separator(1);


		my $b = 1;
		foreach my $cols ( @{$self->{data}} ){
				if ( $b ){
						$b = 0;
						$self->print_separator('titleb'); # titles bottom
				} else {
						$self->print_separator('table');
				}
				$self->print_row( type=>'table', cols=>$cols );
		}
		$self->print_separator('tableb');


#		foreach my $t ( @{$self->{titles}} ){
#				print '+-';
#				print 




}








1;




# test..
#		my $t = tables->new( #widths=>[20,40], 
#				titles=>[qw/Col1 Col2/] );
#
#		$t->add_row( "Hey ho.-.!", "sowas.." );
#		$t->add_row( "Umbrueche..\naha?", "cd" );
#		$t->add_row( "Umbrueche 2.\naha?", "\nasdf\nas" );
#		$t->add_row( "Eine sehr lange Zeile, sollte laenger sein.", "ss" );
#
#		$t->auto_widths(11);
#		$t->show();
#


