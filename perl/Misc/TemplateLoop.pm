package Misc::TemplateLoop;
## Eases Loops for templates


## Erstellt das neue Loop Objekt
sub new{
				my $class = shift;
				return bless( {}, $class );
}
## Adds a new loop with the content, supplied as hash
sub add{
				my $self = shift;
				my %hash = @_;
#				my @a = keys(%hash);
#				$self->debug(5, "add: ".join(" - ", @a ));

				push @{$self->{loop}}, \%hash;
}
## Sorts the loop after the values of the supplied key
## args: the key
sub sort{
				my $self = shift;
				my $key = shift;

				@{$self->{loop}} = sort { $a->{$key} cmp $b->{$key} } @{$self->{loop}};
}
				
				
## returns The array ref we need to parse into the loop_var
sub arrayref{
				my $self = shift;
				return $self->{loop} if ( defined $self->{loop});
				return [];								
}


				


1;

