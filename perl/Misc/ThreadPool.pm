package Misc::ThreadPool;
## A test implementation of a pool of threads,
# Storing the results of the threads' jobs in a queue
# this is work in progress, please comment

# Usage: my $pool = threadpool::new( OPTIONS )
# $pool->enqueue("main::functiontorun", @arguments_for_the_function );
# my $resultid = $pool->renqueue("main::functiontorun", @arguments_for_the_function );
# print $pool->waitforresult( $resultid );
# $pool->wait(); # Waits until all jobs are done
# $pool->shutdown(); # Destroys all threads


use threads;
use threads::shared;
#use forks;
#use forks::shared;





#use Storable;



## Inititializes the threadpool
## args: (named)
## -maxthreads: maximum number of threads (default:10)
## -maxpending: How many jobs may be enqueued, if you try to enqeue more jobs enqueue will block until a job has been done (default:20)
## -startthreads: Threads to start on startup (default:5)
sub new{
		my %args = @_;

		my $self = {};
		bless $self;
		share %{$self};

		foreach my $k ( qw/maxthreads maxpending threads freethreads workingthreads threadstart poollock poolcount morework freeresultidslock nextresultid shutdown resultslock/ ){
				share my $s;
				$self->{$k} = \$s;
		}


		${$self->{maxthreads}} = 10;
		${$self->{maxpending}} = 20;
		${$self->{threads}} = 0;
		${$self->{freethreads}} = 0;
		${$self->{workingthreads}} = 0;
		${$self->{nextresultid}} = 1;
		${$self->{shutdown}} = 0;
		${$self->{poolcount}} = 0;


		share my @pool;
		$self->{pool} = \@pool;
		share my %results;
		$self->{results} = \%results;
		share my @freeresultids;
		$self->{freeresultids} = \@freeresultids;



		if ( defined( $args{maxthreads} ) ){
				${$self->{maxthreads}} = $args{maxthreads};
		}
		if ( defined( $args{maxpending} ) ){
				${$self->{maxpending}} = $args{maxpending};
		}
		if (! defined( $args{startthreads} ) ){
				$args{startthreads} = 5;
		}

		if ( ${$self->{maxthreads}} < $args{startthreads} ){
				$args{startthreads} = ${$self->{maxthreads}};
		}

		lock ${$self->{threadstart}};
		for ( 1.. $args{startthreads}){
				my $t = threads->create("T_thread", $self, 1);
				$t->detach();
		}

		my $threads;
		do { # Wait until all threads have been started and are waiting for jobs
				cond_wait ${$self->{threadstart}};				
				{ 
						lock ${$self->{threads}};
						$threads = ${$self->{threads}};
				}
		} while ( $threads < $args{startthreads} );

		return $self;
}


## Waits for all threads to finish their jobs and ends them
## sleeps for 1 second after doing his job, in the hope, that all threads will have cleaned up.
## Is, however, just for the cosmetic of not beeing warned that threads were running while exiting the script.
sub shutdown{
		my $self = shift;
		$self->wait();
		print "thr_waiting\n";
		{
				lock ${$self->{shutdown}};
				${$self->{shutdown}} = 1;
		}

		my $t;
		do {
				{ 
				lock ${$self->{morework}};
				cond_broadcast ${$self->{morework}};
				}

				print "loop\n";
				#{
				lock ${$self->{threads}};
				$t = ${$self->{threads}};
				#}
				if ( $t > 0 ){
						print "waiting, threads: ${$self->{threads}}\n";
						select undef,undef,undef,0.1;
						#cond_wait ${$self->{threads}};
				}
		} while ( $t > 0 );
		select undef,undef,undef,0.25;
}



# A worker thread
sub T_thread{
		my $self = shift;
		my $count = shift;

		my $init = 1;
		my $tn;
		{ 
				lock ${$self->{threads}};
				$tn = ${$self->{threads}};
		}


		if ( $count ){ 
				lock ${$self->{threads}};
				${$self->{threads}}++;
				$tn = ${$self->{threads}};
		}

		print "Thread number $tn started.\n";
		while ( 1 ){
				{ 
						lock ${$self->{freethreads}};
						${$self->{freethreads}}++;
				}

				my $job;
				{
				do {
						lock ${$self->{morework}};
						#$dolock = 1;
						{ 
								lock ${$self->{poollock}};
								$job = shift @{$self->{pool}};
						}
						if ( !defined( $job )){
								if ( $init ){
										lock ${$self->{threadstart}};
										cond_signal ${$self->{threadstart}};
										$init = 0;
								}
								#print "morework\n";
								threads->yield();

								cond_wait ${$self->{morework}};
								{ 
										#print "lock shutdown\n";
										lock ${$self->{shutdown}};
										if ( ${$self->{shutdown}} ){
												#print "shutting down.\n";
												lock ${$self->{freethreads}};
												lock ${$self->{threads}};
												${$self->{freethreads}} --;
												${$self->{threads}} --;
												#cond_signal ${$self->{threads}};
												#print "thread exit\n";
												return;
										}
								}
						}
				} while ( !defined( $job ) );
						lock ${$self->{poolcount}};						
						lock ${$self->{freethreads}};
						${$self->{freethreads}}--;
						${$self->{poolcount}} --;

						cond_signal ${$self->{poolcount}};
				}
				# Test if there are still enough freethreads..
				{ 
						lock ${$self->{freethreads}};
#						${$self->{freethreads}}--;
						
						#print "thread: freethreads ${$self->{freethreads}}\n";
						if ( ${$self->{freethreads}} == 0 ){ # No threads left for the work
								lock ${$self->{maxthreads}};
								lock ${$self->{threads}};

								if ( ${$self->{maxthreads}} > ${$self->{threads}} ){ 

										lock ${$self->{threads}};
										${$self->{threads}}++;

										my $thread = threads->create("T_thread", $self, 0);
										$thread->detach();
								}
						}
				}


				{ 
						lock ${$self->{workingthreads}};
						${$self->{workingthreads}}++;
				}

				my $result = &{$job->{function}}(@{$job->{args}},"\n",$tn);		

				if ( $job->{result} ){
						#share $result;
						lock ${$self->{resultslock}};
						my $r = $self->{results}->{$job->{resultid}};
						lock $r;
						#my $r = $T_results{$job->{resultid}};
						$r->{state} = 1;
						$r->{result} = $result;
						cond_signal $r;
				}

				{
						lock ${$self->{workingthreads}};
						${$self->{workingthreads}}--;
						cond_signal ${$self->{workingthreads}};
				}

		}
}

## returns the result of the supplied resultid, 
## waits until the result is there.
## returns undef if there is no such resultid.
sub waitforresult{
		my $self = shift;
		my $resultid = shift;
		my $r;
		{ 
				lock ${$self->{resultslock}};
				$r = $self->{results}->{$resultid};
		}
		if ( !defined($r)){
				return; # No such resultid 
		}

		my $result;
		{	
				lock $r;
				while ( $r->{state} == 0 ){ # Wait for the result
						cond_wait $r;
				}
				$result = $r->{result};
				lock ${$self->{resultslock}};
				delete $self->{results}->{$resultid};
				lock ${$self->{freeresultidslock}};
				push @{$self->{freeresultids}}, $resultid;
		}

		return $result;
}


## Enqueues a new job.
## args:
## The function name, which will be callen in the current context e.g. "main::function"
## Args to be supplied to the function
sub enqueue{
		my $self = shift;
		$self->T_enqueue( shift, 0,  @_ );
}

## Enqueues a new job, and returns a resultid, which can be used to get the result of the function via threadpool_waitforresult or threadpool_getresult
## args:
## The function name, which will be callen in the current context. e.g. "main::function"
## Args to be supplied to the function
sub renqueue{
		my $self = shift;
		return $self->T_enqueue( shift, 1, @_ );
}


sub T_enqueue{
		my $self = shift;
		my $function = shift;
		my $result = shift;
		share my @args;
		@args = @_;

		my %hash;
		share %hash;

		share $function;
		$hash{function} = $function;
		$hash{args} = \@args;
		share $result;
		$hash{result} = $result;

		my $resultid = 0;
		if ( $result > 0 ){ # Want the result saved
				{
						lock ${$self->{freeresultidslock}};
						$resultid = shift @{$self->{freeresultids}};
				}
				if ( !defined( $resultid ) ){
						{
								lock ${$self->{nextresultid}};
								$resultid = ${$self->{nextresultid}};
								${$self->{nextresultid}} ++;		
						}
				}
				share $resultid;
				$hash{resultid} = $resultid;

				share my %h;		
				$h{state} = 0; # No result yet ...
				{
						lock ${$self->{resultslock}};
						$self->{results}->{$resultid} = \%h;
				}
		}


		#print "enqueued: ", @{$hash{args}},"\n","@args","\n";
		lock ${$self->{poolcount}};
		{
				lock ${$self->{morework}};
				lock ${$self->{poollock}};
				push @{$self->{pool}}, \%hash;
				cond_signal ${$self->{morework}};
		}
		${$self->{poolcount}} ++;
		if ( ${$self->{poolcount}} > ${$self->{maxpending}} ){
				print "Waiting, poolcount: ${$self->{poolcount}}\n";
				cond_wait ${$self->{poolcount}};
				print "Waited, poolcount: ${$self->{poolcount}}\n";
		}
			
		return $resultid;
}


## Returns the current number of working threads 
## There's to remark that some threads could be out of your function,
## but still have some work to do within this module
sub threadsworking{
		my $self = shift;
		lock ${$self->{workingthreads}};
		return ${$self->{workingthreads}};
}

## Returns the current number of jobs, in the queue and in work
## There's to remark that some threads could be out of your function,
## but still have some work to do within this module
sub jobs{
		my $self = shift;
		lock ${$self->{poolcount}};
		lock ${$self->{freethreads}};
		lock ${$self->{threads}};

		return ( ${$self->{poolcount}} + ( ${$self->{threads}} - ${$self->{freethreads}} ) );
}

## Returns the number of jobs currently in queue
sub pendingjobs{
		my $self = shift;
		lock ${$self->{poolcount}};
		return ${$self->{poolcount}};
}

## blocks until all jobs are done
sub wait{
		my $self = shift;

		while ( 1 ){
				{
						lock ${$self->{workingthreads}};
						my $pending;
						{ 
								lock ${$self->{poolcount}};
								$pending = ${$self->{poolcount}};
						}
						if ( ${$self->{workingthreads}} + $pending > 0 ){
								cond_wait ${$self->{workingthreads}};
						} else {
								return;
						}
				}
		}
}

# TEST CODE #######################################################################################

1;

