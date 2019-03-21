package Misc::Debug;
## debug functions
## 


use Carp;
use Time::HiRes qw/gettimeofday tv_interval/;

BEGIN{
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(debug dbg initdebug setdebuglevel starttimer printtimer enable_debug disable_debug print_context);
}



## This Global var enables (or disables by default) all debug messages, no matter of  the debug level and debug enabled.
## Change via $Misc::Debug::debug_everything = 1;
our $debug_everything = 0;

## Enable debug messages of all levels
## debug_level is a number between 0 and 9
our $debug_level = 9;

##
our $debug_facility = 1;


## Overwrite this locally via our $debug_enabled = 0 ( 1 ),
## to enable or disable debugging within a package.
our $debug_enabled = 1;


## Set this global var by enable_debug and disable_debug
our $global_debug_enabled = 1;

##
our $print_timer = 0;

##
our $print_context = 0;




our $timer = [gettimeofday];

&initdebug();

$starttime = [gettimeofday];


## Enable debugging globally (On by default)
sub enable_debug{
	$global_debug_enabled = 1;
}

## Disable debugging globally (On by default)
sub disable_debug{
	$global_debug_enabled = 0;
}


## Starts the timer
sub starttimer{
				$timer = [gettimeofday];
}

## debugs the elapsed time since starttimer
sub printtimer{
				my $s = shift;
				$s = '' if ( !defined($s) );
				debug( "Timer: $s ".tv_interval( $timer )*100 );
#				$timer = [gettimeofday];
				
}


## an alias for debug
sub dbg{ 
	goto &debug; # Just call the real debug function..
}




## logs to debuglog, if [Debuglevel] is < the global debuglevel
## params: [int Debuglevel], string message	
## DebugLevel is only recognized, if the first param is a number between 0 and 9
## else this parameter is omitted
sub debug{
	my $caller;

	if ( !$debug_everything ){
		return if ( !$global_debug_enabled );

		$caller = caller;
#		print "caller dbg: $caller\n";
#		$debug_enabled = 1; # Set the exported var to 1, for the case, that some package didn't change $debug_enabled locally via our
		my $e2 = "$caller\::debug_enabled";
		if ( defined( $$e2 ) && !( $$e2 ) ){
			return;
		}
	} else {
		$caller = caller;
	}


	my @callcontext = caller;
#	print "callcontext: @callcontext\n";

	do_debug($caller, @callcontext, @_);
}


## Do the debug. Called internally by dbg and debug.
sub do_debug{
	my $caller = shift;
	my $package = shift;
	my $filename = shift; 
	my $line = shift;
	my $f_debug_level = shift;

	my $p1 = '';
	if ( ! ( $f_debug_level =~ /^\d$/ ) ){
		$p1=$f_debug_level;
		$f_debug_level=0;
	}

	my $msg = join("", $p1, @_ );


	if ( !$debug_everything ){
		return if  ($f_debug_level > $debug_level);
		return if ( !$debug_enabled );
	}

	if ( $print_context ){
		$msg = $msg." ".join (" ",($package, $filename, $line) );
	}

	if ( $print_timer ){
		my $elapsed = tv_interval( $starttime );
		if ( $elapsed > 10 ) {
			$starttime = [gettimeofday];
			$elapsed = 0;
		}

		$msg = $elapsed." ".$msg;
	}

	if ( $debug_facility  == 2 ) {
		carp( $msg );				
	} else {								
		print STDERR $msg, "\n";
#								print STDERR "\n";# if ( $config{'debug_facility'} != 1 ); # Don't print \n if we log to the apache log
	}
}


## Sets the debuglevel
sub setdebuglevel{
	$debuglevel = shift;
}



## log to a file, pipe or device..
## args: filename
sub log_to_file{
	my $fn = shift || die;

	close STDERR;
	open( STDERR, ">>$fn" ) or die;
}



















###############################







## redirect all messages to stderr to the debug file, if we don't log into the apache error log
## Is callen by this package itself, since we need this only if redirecting under modcgi.
## Debugging to file doesn't work with modperl. yet.
sub initdebug{
				if ( defined( $pgdebug ) ) {
								return;
				}
				## The global debug instance, as an alternative to subclassing from debug
				our $pgdebug = 1;
				#bless( {}, 'pgroupware::api::debug' );
				if ( defined($config{'debug_facility'}) && ($config{'debug_facility'} == 0) && ( defined $cgirunning) ){
								close STDERR;
								open( STDERR, ">>debug_log" );
				}
}






1;
