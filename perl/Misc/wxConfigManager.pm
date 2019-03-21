package Misc::wxConfigManager;
## 
use Config::General;
use Misc::AppConfig;
use Switch;

use Wx qw[:allclasses];
use Wx::Event qw/EVT_BUTTON/;

use Data::Dumper::Simple;
use Misc::Debug;

use globals;

BEGIN{
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw/ShowModalConfigDialog/;
}

## TODO: make this class nonstatic..
# make it possible via submitting a new derived AppConfig class to save the config in a sqlite db..



##
our	$cfg; #new Config::Simple(syntax=>'ini');
	#$self->{appconfig} = shift || Misc::AppConfig->new();
Misc::AppConfig::init_config(); # Shouldn't be callen here. (makes it possible impossible to use sessions) 
# so the cofig should get supplied to an instance of this as a instance/or simply a hashref

our $modified = 0;

our $defaults = 1;

##
sub LoadConfig{
#	my $filename = shift;

#	if ( ! -e $filename ){
#		print "Error: $filename not found !\n";
#		return 0;
#	}
#	$self->{cfg}->read($filename);
	$cfg = Misc::AppConfig::getconfig('wxConfigManager'); ## todo : wxStandardPaths::GetUserDataDir
#	dbg "LoadConfig\n", Dumper($cfg);
	$defaults = 0;
	return 1;
}



##
sub SaveConfig{
#	my $filename = shift || undef;

#	if ( defined ($filename) ) {
#		$self->{cfg}->save($filename);
#	} else {
#		$self->{cfg}->save();
#	}

	Misc::AppConfig::saveconfig();
	
	return 1;
}

##
sub ShowModalConfigDialog{

	my $dialog = shift;

	WidgetSet($dialog);


	my @buttons = qw/savebutton cancelbutton okbutton/;
	my @connections;
	foreach my $l ( @buttons ){
		my $w = Wx::Window::FindWindowByName(  $l, $dialog );
		if ( defined( $w ) ){
			$w->Connect( -1, -1,&Wx::wxEVT_COMMAND_BUTTON_CLICKED , 
				sub { dbg "Button: $l\n"; 
					HandleButtonEvent( $dialog, $l );
					if ( $l eq "okbutton" ){
						$dialog->EndModal( 1 );
					} elsif ( $l eq "cancelbutton" ){
						$dialog->EndModal(0);
					}
				} );
			push @connections, $w;
		}
	}

	$dialog->ShowModal();

	foreach (@connections){
		$_->Disconnect(-1,-1, &Wx::wxEVT_COMMAND_BUTTON_CLICKED );
	}

	dbg "cfg:\n", Dumper($cfg);
}

##
sub HandleButtonEvent{
	my $widget = shift;
	my $button = shift;

	dbg "Buttonevent: $button";

	switch ( $button ){
		case "cancelbutton" { WidgetSet($widget) }
		case "okbutton" { WidgetRead($widget) }
		case "savebutton" { WidgetRead($widget) }

		else {}
	}
}


##
sub WidgetRead{
	my $window = shift;

	$defaults = 0;

	my $name = $window->GetName();

	my $section = 0;
	my $p = \%{$cfg->{$name}};


	foreach my $i ( wxGetAllChildren($window) ){


		next if ( ! $i->can(GetName) );
		my $n = $i->GetName();
		dbg "Name: $n";
#		$self->ReadValue($i);
		if ( $n =~ /^section_(.*)/ ){ # Works.. useful for implementing "sections", that would be a list of settings grouped in sections..
										# Not implemented in widgetset yet.
#			dbg "XXXXXXXXXXXXXX";
			$p = \%{$cfg->{$name}->{$1}};
		}
	
	
		my $value;
		$p->{$n} = $value 
			if ( defined( $value = ReadValue($i) ) );

		
	}


}

##
sub WidgetSet{
	my $window = shift;

	my $name = $window->GetName();
	my %widgets;
	my @wl = wxGetAllChildren($window);

	foreach my $i ( @wl ){
		next if ( ! $i->can(GetName) );
		$widgets{$i->GetName()} = $i;
	}
	print Dumper(%widgets);

	return if ( $defaults ); # No Config file loaded yet, use the defaults defined in the xrc file
	print Dumper ($cfg);
	my $vars = $cfg->{$name} || {};
	#my $vars = $self->{cfg}->get_block("default");
	print Dumper($vars);
	foreach my $key ( keys(%{$vars}) ){
		print "Setting $key to ", $vars->{$key}||'',"\n";
		SetValue(\%widgets, $key, $vars->{$key}||'');
	}
}


sub SetValue{
	my $widget = shift;
	my $name = shift;
	my $value = shift;

	my $control = $widget->{$name} or return;


	if ( $control =~ /Wx::Choice|Wx::ListBox/ ) {
		return $control->SetStringSelection($value);
	}

	foreach my $method ( qw/SetValue SetPath/ ){
		if ( $control->can($method) ){
			print "$method\n";
			return $control->$method($value);
		}
	}

	return(undef);

}


sub ReadValue{
	my $control = shift;

	# Not implemented for ColourPickerCtrl (Method GetColour())

	if ( $control =~ /Wx::Choice|Wx::ListBox/ ) {
		return $control->GetStringSelection();
	}

	foreach my $method ( qw/GetValue GetPath/ ){
		if ( $control->can($method) ){
			print "$method: ", $control->$method() ,"\n";
			return $control->$method();
		}
	}


	return(undef);
}




1;



