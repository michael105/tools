package Misc::ReadKey;
## provides readkey functions
##
## readkey( wait seconds )
## readkey_usecs( wait seconds, wait usecs )
## waitkey_dots( wait seconds, dots per seconbd )

use Inline C;

BEGIN{
				use Exporter;
				@EXPORT = qw/readkey readkey_usecs readkey_dots/;
				our @ISA = qw/Exporter/;
}



1;


__DATA__
__C__

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>


#define debug

// Read a key, wait for wait seconds, usecs microseconds.
// returns: -1 on error
// 					0 on timeout
// 					otherwise the scancode of the key
char readkey_usecs( int wait, int usecs ){

		struct termios oldSettings, newSettings;

		tcgetattr( fileno( stdin ), &oldSettings );
		newSettings = oldSettings;
		newSettings.c_lflag &= (~ICANON & ~ECHO);
		tcsetattr( fileno( stdin ), TCSANOW, &newSettings );


		struct timeval tv;
		void *p = &tv;
		fd_set set;
		char c;

		tv.tv_sec = wait;
		tv.tv_usec = usecs;


		FD_ZERO( &set );
		FD_SET( fileno( stdin ), &set );


		if ( wait == -1 ) 
				p = NULL;

		int res = select( fileno( stdin )+1, &set, NULL, NULL, p );

		if ( res > 0 ){
				read( fileno( stdin ), &c, 1 );

				tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );
				return c;
		}
//	printf("res: %d\n",res);

		tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );
		if ( res == 0 ) // timeout
				return 0;

		perror( "select error" );
		return -1;
}
// Read a key, wait for wait seconds.
// returns: -1 on error
// 					0 on timeout
// 					otherwise the scancode of the key
char readkey( int wait ){
		return readkey_usecs( wait, 0 );
}


// read a key, show dots dots per second
char readkey_dots( int wait, int dots ){

		struct termios oldSettings, newSettings;

		tcgetattr( fileno( stdin ), &oldSettings );
		newSettings = oldSettings;
		newSettings.c_lflag &= (~ICANON & ~ECHO);
		tcsetattr( fileno( stdin ), TCSANOW, &newSettings );


		int a;
		int usecs = 0;
		int res = 0;
		int loops = wait;

		wait = 1;

		if ( dots > 1 ){ // more dots per second..
				wait = 0;
				usecs = 1000000 / dots;
				loops *= dots;
				//printf("usecs: %d\n", usecs );
		}

		for ( a = 0; a < loops; a++ ){
				fprintf( stderr, "." );
				res = readkey_usecs( wait, usecs );
				if ( res != 0 ){ // got a result, could also be -1 (means error)
						fprintf( stderr, "\n" );
						return( res );
				}
		}
		fprintf( stderr, "\n" );

		tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );
		return( res );
}


int read_the_key( int argc, char *argv[])
{
		struct termios oldSettings, newSettings;

		tcgetattr( fileno( stdin ), &oldSettings );
		newSettings = oldSettings;
		newSettings.c_lflag &= (~ICANON & ~ECHO);
		tcsetattr( fileno( stdin ), TCSANOW, &newSettings );

		int wait = 0;
		int dots = 0;

		// Parse Arguments
		int a;
		int b = 1;
		for ( a=1; a < argc; a++) {
				if ( strcmp(argv[a], "-b" )==0 )  {
						b = 0;
						wait = -1;
				}  
						
				if ( b && (strcmp(argv[a], "-w")==0) ){
						if ( (a+1 < argc ) && ( atoi(argv[a+1]) >0 ) ){
								wait = atoi(argv[a+1]);
//								printf("wait: %d\n",wait);
								a++;
								b = 0;
						}
				} 

				if ( strcmp(argv[a], "-d" )==0 )  {
						dots = 1;
						if ( (a+1 < argc ) && ( atoi(argv[a+1]) >0 ) ){
								dots = atoi(argv[a+1]);
								//printf("dots: %d\n",dots);
								a++;
						}

				}  
	

							
		}

		// Show usage
		if ( b ) {
				printf("\
Usage: term_readkey [-b] [-w secs] [-d [dotrate]]\n\
-b           : block until a key is pressed.\n\
-w secs      : wait for secs seconds for input.\n\
-d [dotrate] : show 1 dot per second waiting, optional [dotrate] dots per second\n\
\n\
Returns -1 on error, 0 on timeout.\n\
\n\
Example: key=`term_readkey -w 5`\n\
echo $key\n\n");
				tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );
				return 0;
		}
	

		char c;


		if ( dots ) {
				c = readkey_dots( wait, dots );
		} else {
				c = readkey( wait );
		}


		switch ( c )
		{
				case 0 : printf("0\n");tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );return 0;break; // timeout
				case -1 : printf("-1\n");tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );return -1;break; // select error
				case 9 : printf("TAB"); break;
				case 10 :	printf("RET"); break;
				case 127 : printf("BACKSPACE"); break;
				case 27 : {
											c = readkey(0);

											if ( c == 0 ){
													printf("ESC");
													break;
											}  
//											printf( "E: %d  %c",c,c );
											switch ( c ){
													case 79 : { //F1..F4
																				c = readkey(0);
																				switch ( c ){
																						case 0 : printf("?");break;
																						case 80 : printf("F1"); break;
																						case 81 : printf("F2"); break;
																						case 82 : printf("F3"); break;
																						case 83 : printf("F4"); break;
#ifdef debug
																						default: printf( "79: %d  %c",c,c ); 
#else
																						default: printf( "?" ); 
#endif
																				}

																				break;
																		}
													case 91 : {	
																				c = readkey(0);
																				switch ( c ){
																						case 51 :{
																												 c = readkey(0);
																												 switch ( c ){
																														 case 126 : printf("DEL"); break;
#ifdef debug
																														 default: printf( "91: %d  %c",c,c ); 
#else
																														 default: printf( "?" ); 
#endif
																												 }
																												 break;
																										 }
																						case 53 : printf("PGUP");break;
																						case 54 : printf("PGDOWN");break;
																						case 70 : printf("END");break;
																						case 72 : printf("POS1");break;
																						case 65 : printf("UP");break;
																						case 66 : printf("DOWN");break;
																						case 67 : printf("RIGHT");break;
																						case 68 : printf("LEFT");break;
#ifdef debug
																						default: printf( "91: %d  %c",c,c ); 
#else
																						default: printf( "?" ); 
#endif

																				}
																				break;
																		}
#ifdef debug
													default : printf( "E: %d  %c",c,c );
#else
													default: printf( "?" ); 
#endif

											}

											break;
									}


				default: {
										 if ( (c>0) && (c < 27) ){
												 c = c+64;
												 printf("CTRL+%c",c);
												 break;
										 }
										 printf( "%c",c );
								 }
		}

		tcsetattr( fileno( stdin ), TCSANOW, &oldSettings );
		return 1;
}


