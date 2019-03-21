package Misc::Signals::Baseclass;
## Virtual Baseclass for Misc::Signals


use Misc::Signals;

use Misc::Debug;
#local $debug_enabled = 1;
use Data::Dumper::Simple;

## connect a signal to a slot.
## args: the signal name
## 	 ref to a slot
sub connect_signal{
	my $self = shift;
	my $signal = shift;
	my $coderef = shift;

	$self->{connected_signals}->{$signal} = 1;
	Misc::Signals::connect_signal( $self, $signal, $coderef );
}

## disconnect a signal-slot connection
## args: signalname
sub disconnect_signal{
	my $self = shift;
	my $signal = shift;

	Misc::Signals::disconnect_signal( $self, $signal );
}

## connect all functions of the current instance $self,
## named SLOT_signalname to the corresponding signalnames.
## args: (optional) the packagename to parse. Needed for inherited classes.
sub connect_slots{
	my $self = shift;
	my $classname = shift || ref($self);

#	foreach my $classname ( $class, @{"$class\::ISA"} ){
	#dbg "classname: $classname";
	#dbg Dumper( %{"$classname\::"}  );
	foreach (  keys(%{"$classname\::"}) ){
		/SLOT_(.*)/ or next;
		#dbg "signal: $1";
		$self->{connected_signals}->{$1} = 1;
		Misc::Signals::connect_signal( $self, $1, *{"$classname\::$_"} );
	}
#}

}

## Must be callen before the module can be deleted. 
## otherwise the module simply will be kept in memory!!
sub release{
	my $self = shift;
	#print "release in Misc::Signals::Receiver\n";
	foreach ( keys(%{$self->{connected_signals}}) ) {
		Misc::Signals::disconnect_signal( $self, $_ );
		delete $self->{connected_signals}->{$_};
	}
}

## send the signal arg1, with the data arg2
sub emit{
	my $self = shift;
	my $signal = shift;
	#my $dataref = shift;
	dbg "Misc::Signals::Baseclass::emit $signal";
	if ( $self->{disable_signals} || 0 ){
		dbg "Signalling disabled";
		return undef;
	}

	$self->{signals_sent} = $self->{signals_sent} || 0;
	$self->{signals_sent}++;
	dbg "self->{signals_sent}: $self->{signals_sent}";

	my @ret = Misc::Signals::send_signal( $self, $signal, @_ );

	$self->{signals_sent}--;
	return @ret;
}

## returns the number of times your instance sent a signal and didn't return out of emit yet.
sub signals_sent{
	my $self = shift;
	return ($self->{signals_sent} || 0);
}

## Enables and disables the sending of signals, depending on arg1
sub send_signals{
	my $self = shift;
	$self->{disable_signals} = !(shift);
}


1;


