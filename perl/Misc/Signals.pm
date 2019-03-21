package Misc::Signals;
## Class for managing the sending and receiving of signals.
## Only function, which can be callen directly, is emit.
##
## Instead inherit packages, which should be able to send or receive signals,
## from Misc::Signals::Sender and/or Misc::Signals::Receiver
##
## TODO Make somehow interprocess-communication possible
## Make something like a dump function, 
## dumping out all connected signals / slots wit the according packagenames
##


use Misc::Debug;
#local $debug_enabled = 0;
use Data::Dumper::Simple;

our %signals;


## emit a signal
## args: the sender object
##	the signal name
sub emit{
	&send_signal;
}

##
sub connect_signal{
	##dbg "connect_signal";
	##dbg Dumper(@_);
	my $receiver = shift;
	my $signal = shift;
	my $ref = shift;


	$signals{$signal}->{$receiver} = {receiver=>$receiver, coderef=>$ref};
	##dbg Dumper(%signals);
}
##
sub disconnect_signal{
	my $receiver = shift;
	my $signal = shift;

	delete $signals{$signal}->{$receiver};
}

##
sub send_signal{
	##dbg Dumper(@_);
	my $sender = shift;
	my $signal = shift;
	#my $data = shift;
	dbg "Misc::Signals::send_signal: $signal";
	##dbg Dumper(%signals);
	my @ret;

	foreach my $r ( keys(%{$signals{$signal}}) ){
		#next if ( $r eq $sender );
#		##dbg "inloop, $r, $sender, ",Dumper($signals{$signal}->{$r}->{receiver});
		push @ret, $signals{$signal}->{$r}->{coderef}( $signals{$signal}->{$r}->{receiver}, sender=>$sender , @_ );
	}
	return @ret;
}

1;

