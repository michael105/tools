package Misc::AppConfig;
## Global Application Configuration
## TODO implement getpath ... (homedir, datadir, configdir, ...)

use Config::General;

use Misc::Debug;

use Data::Dumper::Simple;


BEGIN{
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw/$cfg/;
}




our $init = 0;

our $cfg;



our $appname;
our $configpath;
our $filename;
our $conf;

our %confighash;



## init the appconfig
## params (named):
# -appname (optional)
# -configpath (optional)
# -filename (optional)
# -defaults (optional) ref to a config hash
sub init_config{
	my %args=@_;

	dbg "init_config";
	return getconfig("main") if ( $init );
	$init = 1;

	dbg "init_config 2";
	my $appname = $args{appname} || $0;
	$appname =~ s/^\.\///;
	$configpath = $args{configpath} || "$ENV{HOME}/.$appname"; ## BAD! maybe File::HomeDir->my_dist_config( $dist [, \%params] );
	$configpath="/home/micha/.know.pl";
	$filename = $args{filename} || "config.cfg";

	my $defaults=$args{defaults} || {};

	dbg( "Appname: $appname \n $configpath" );


	if ( !-d $configpath ){
		mkdir( $configpath ) or die;
	}

	$conf = new Config::General( "$configpath/$filename" );
#		 '-ConfigFile'=>"$filename", 
#			'-ConfigPath'=>$configpath,
#			'-ConfigHash'=>\%confighash 
#			DefaultConfig=>$defaults } 
#	);
	
	dbg "Files:\n ";
#	$conf->_process();
	dbg $conf->files;
	%confighash = $conf->getall();
	dbg Dumper( %confighash );
	dbg $conf->files;

#	%confighash = %{$conf->getall()};


	return getconfig("main");

}



## return the config hash of the specified section ("main" by default)
## Optional: A hash with default values
sub getconfig{
	my $section = shift || 'main';
	dbg "getconfig\n", Dumper($confighash);


	if ( !defined($confighash{$section}) ){
		$confighash{$section} = shift || {};
	}

	return \%{$confighash{$section}};
}




## Save the config
sub saveconfig{
	dbg "saveconfig\n", Dumper(%confighash);
	$conf->save_file( "$configpath/$filename" );
}











1;

