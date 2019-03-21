package Misc::ThreadPool::TcpServer;
## An implementation of a threaded tcp server module
## Due to memory leaks with threads the threads will not be destroyed, 
## instead they are just waiting for connections
##
## Usage:
##


use threads;
use threads::shared;

use IO::Socket;

## Creates a new threadpool to handle incoming connections on a socket.
## args: (named)
## -maxthreads	The maximum of concurrent connections (default:50)
## -startthreads	The threads to initially start (default:5)
## -minfreethreads The minimum of free threads to handle new connections (default:2)
## -handle	The function name to handle the request, e.g. "main::handle".
##					Will be supplied with the new client ( IO::Socket::accept() ) as argument
## -localport	The port to bind to
## -localaddr The address to bind to
sub new{
		my %args = @_;

		my $self = {};
		bless $self;
		share %{$self};

		foreach my $k ( qw/maxthreads threads startthreads serverlock freethreads handle minfreethreads/ ){
				share my $s;
				$self->{$k} = \$s;
		}
		${$self->{maxthreads}} = $args{maxthreads} || 50;
		${$self->{startthreads}} = $args{startthreads} || 5;
		${$self->{minfreethreads}} = $args{minfreethreads} || 2;
		${$self->{handle}} = $args{handle} || "testhandle";
		${$self->{threads}} = 0;
		${$self->{freethreads}} = 0;

		$SIG{PIPE} = &sigpipe;

		my $server = IO::Socket::INET->new( Proto     => 'tcp',
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1,
																	LocalAddr => "$args{localaddr}:$args{localport}"
															);
		die "Couldn't start server" if ( !defined( $server )) ;


		for ( 1..${$self->{startthreads}} ){
				threads->create( "thread", $self, $server )->detach();
		}

		return $self;
}

# Waits for incoming connections, calls the handle
# Creates new threads, if needed
sub thread{
		my $self = shift;
		my $server = shift;
		{ lock ${$self->{threads}}; ${$self->{threads}} ++ };
		{ lock ${$self->{freethreads}}; ${$self->{freethreads}} ++ };

		while (1){
				my $client;
				do {
						lock ${$self->{serverlock}};
						print "Accepting connection..\n";
						$client = $server->accept();
				} while ( !defined($client) );

				{ 
						lock ${$self->{freethreads}};
						lock ${$self->{minfreethreads}};
						lock ${$self->{threads}};
						lock ${$self->{startthreads}};
						print $client "threads: ${$self->{threads}}; ${$self->{freethreads}};\n";

						${$self->{freethreads}} --;
						if ( 
								((${$self->{freethreads}} - 
										${$self->{minfreethreads}}) < 0 ) && 
								( ${$self->{threads}} < 
								${$self->{maxthreads}} ) ){
								threads->create( "thread", $self, $server )->detach();
								print $client "New thread started..\n";
						}
				}
				my $f = ${$self->{handle}};
				&$f($client);
				{
						lock ${$self->{freethreads}};
						${$self->{freethreads}}++;
				}
		}


}

	

sub testhandle{
		my $client = shift;

		print $client "Testing..\n";
	while(my $s = <$client> ){
#				my $s = <$client>;
				sleep 4;
				$client ? print $client ($s*2),"\n" : print "undefined!\n";
				print $client "...\n";
		}
}


sub sigpipe{
		print "Broken Pipe..\n";
}


1;

