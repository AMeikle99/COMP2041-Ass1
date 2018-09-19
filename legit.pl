#!/usr/bin/perl  -w

use strict;
use warnings;
use Cwd;


#Global Variables that can be accessed by all routines
#Commonly used values, mainly folder paths
our $ROOT_FOLDER = ".legit";
our $LOGS_FOLDER = "logs";
our $SNAPSHOT_FOLDER = "snapshots";
our $REFS_FOLDER = "refs";
our $HEADS_FOLDER = "refs/heads";

our $SNAPSHOT_FILE = ".S";

our $WORKING_DIRECTORY = getcwd();

######################

main();

######################


sub main{

	my @args = @ARGV;

	#Parse the command arguments and check they are valid
	validateArguments(@ARGV);

	if($args[0] eq "init"){
		initLegit(@args);
	}


	exit(0);

}


#Function which takes in the command line arguments, checks their validity and returns a list of all the components of the arguments
sub validateArguments{
	my @args = @_;
	my $command;

	#Check the supplied arguments are valid and sufficient parameters provided
	if($#args >= 0){
		#Check that the 'init' command has no extra arguments passed in
		if($args[0] eq "init"){
			if($#args >0){
				printf "Usage: $0 init\n";
				exit(1);
			}
		#The supplied command cannot be found, print error and exit
		}else{
			print "legit.pl: error: unknown command $args[0]\n";
			displayOptionsList();
			exit(1);
		}

	#If no arguments were provided then show possible options
	}else{
		displayOptionsList();
		exit(1);
	}
	
	return @args;
}

#Displays a list of all possible commands and a description of them if no command arguments were supplied or an invalid command
sub displayOptionsList{
	printf "Usage: $0: <command> [<args>]\n\n";
	printf "These are the legit commands:\n";
	printf "\tinit    \tCreate an empty legit repository\n";
	printf "\tadd     \tAdd file contents to the index\n";
	printf "\tcommit  \tRecord changes to the repository\n";
	printf "\tlog     \tShow commit log\n";
	printf "\trm      \tRemove files from the current directory and from the index\n";
	printf "\tstatus  \tShow the status of files in the current directory, index, and repository\n";
	printf "\tbranch  \tlist, create or delete a branch\n";
	printf "\tcheckout\tSwitch branches or restore current directory files\n";
	printf "\tmerge   \tJoin two development histories together\n\n";

}

sub initLegit{

	#Check if the .legit folder already exists
	#Exits with error message if it does
	if(-d $ROOT_FOLDER){
		printf "$0: error: .legit already exists\n";
		exit(1);
	}

	#Create the .legit folder
	mkdir($ROOT_FOLDER) or die "Unable to create .legit folder";

	#Create all the subdirectories
	chdir($ROOT_FOLDER);
	mkdir($LOGS_FOLDER);
	mkdir($SNAPSHOT_FOLDER);
	mkdir($REFS_FOLDER);
	mkdir($HEADS_FOLDER);

	mkdir("$LOGS_FOLDER/$REFS_FOLDER");
	mkdir("$LOGS_FOLDER/$HEADS_FOLDER");


	#Print success message
	printf "Initialized empty legit repository in .legit\n";


}