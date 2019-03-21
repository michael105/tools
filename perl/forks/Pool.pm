package forks::Pool;
## Implements a thread pool using the forks module
##
## Please Note, that no threads will exit anymore.
## I implemented the module this way, because there are some memory leaks within the threads implementation of perl,
## as well as in the forks module.




#use forks;
#use forks::shared;
use threads;
use threads::shared;


## Creates a new Pool object
## args: (named)
## -startthreads: the threads number created on startup
## -maxthreads: maximum number of threads
## -maxpending: maximum number of pending jobs, if this number is reached, calls of enqueue will block
sub new{
		my $class = shift;
		my %args = @_;
		print join("\n",@_);

		my $self = {};
		bless $self;

		share $self->{maxthreads};
		$self->{maxthreads} = $args{maxthreads};

		share @{$self->{pool}};
		@{$self->{pool}} = ();
		share $self->{pool};

		share $self->{poollock};


		share $self->{busythreads}; # holds how many threads are busy now
		$self->{busythreads} = 0;

		share $self->{threads}; # holds how many threads are created
		$self->{threads} = 0;

		share $self->{pending};
		$self->{pending} = 0;

		share $self->{pending_decreased};

		share $self->{maxpending};
		$self->{maxpending} = $args{maxpending};


		share $self->{morework};

		for ( 1..$args{startthreads} ){
				$self->new_thread();
		}
		return $self;
}

## Internal function
sub new_thread{
		my $self = shift;
		my $t = threads->create("thread", $self );
		$t->detach();
}

## Internal
sub thread{
		my $self = shift;

		{
				lock $self->{threads};
				$self->{threads}++;
		}

		do {
				my $ref = $self->i_dequeue();
				print "thread, dequeued\n";
				if ( defined( $ref ) ){
						{ 
								lock $self->{busythreads};
								$self->{busythreads}++;
						}
						#print "executing: $ref->{func}\n ";
						&{$ref{func}}(@{$ref{args}});
						{ 
								lock $self->{busythreads};
								$self->{busythreads}--;
						}
				}	
		} while ( 1 );
}

sub i_dequeue{
		my $self = shift;

		my $ref;
		do {
				{
						lock $self->{poollock};
						$ref = shift @{$self->{pool}};
				}

				if ( !defined($ref)){
						lock $self->{morework};
						cond_wait $self->{morework};
						print "morework..\n";
				}
				#print "shifted2: $ref->{func}\n";
		} while ( !defined( $ref ) );
		{
				lock $self->{pending_decreased};
				lock $self->{pending};
				$self->{pending} --;
				cond_signal $self->{pending_decreased};
		}
		print "$ref{func}\n";
		return $ref;
}

sub i_enqueue{
		my $self = shift;

		my $func = shift;
		my @args = @_;

		my $pending;
		my $maxpending;

		{ 
				lock $self->{pending_decreased};
				{
				lock $self->{poollock};
				lock $self->{pending};
				$self->{pending} ++;
				$pending = $self->{pending};
				lock $self->{maxpending};
				$maxpending = $self->{maxpending};
				my %ref;
				print "func: $func\n";
				$ref{func} = $func;
				print "enqueuing: $ref{func}\n";
				share $ref{func};
				print "enqueuing: $ref{func}\n";
				$ref{args} = @args;
				print "enqueuing: $ref{func}\n";
				share $ref{args};
				print "enqueuing: $ref{func}\n";
				#share %{$ref};
				print "enqueuing: $ref{func}\n";
				share $ref;
				print "enqueuing: $ref{func}\n";
				push @{$self->{pool}}, %ref;
				{ lock $self->{morework};
				cond_signal $self->{morework};
				}
				}
				if ( $pending>=$maxpending ){
						cond_wait $self->{pending_decreased};
				}

		}
}


## enqueue a new job.
## blocks, if maxpending is reached.
sub enqueue{
		my $self = shift;
		my $func = shift;
		my @args = @_;

		$self->i_enqueue( $func, @args );
}




1;

