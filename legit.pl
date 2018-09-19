#!/usr/bin/perl  -w

use strict;
use warnings;
use Cwd;
use File::Copy;
use File::Compare;


#Global Variables that can be accessed by all routines
#Commonly used values, mainly folder paths
our $ROOT_FOLDER = ".legit";
our $LOGS_FOLDER = "logs";
our $SNAPSHOT_FOLDER = "snapshots";
our $INDEX_FOLDER = "index";
our $REFS_FOLDER = "refs";
our $HEADS_FOLDER = "refs/heads";

our $SNAPSHOT_FILE = ".S";

our $WORKING_DIRECTORY = getcwd();
our $CURRENT_BRANCH;
our $CURRENT_SNAPSHOT;

our $MAX_COMMIT;

######################

main();

######################


sub main{

	my @args = @ARGV;

	#Parse the command arguments and check they are valid
	validateArguments(@ARGV);

	if($args[0] eq "init"){
		initLegit(@args);
	}elsif($args[0] eq "add"){
		shift @args;
		addLegit(@args);
	}


	#changedFiles();

	exit(0);

}


#Function which takes in the command line arguments, checks their validity and returns a list of all the components of the arguments
sub validateArguments{
	my @args = @_;
	my $command;

	chdir($WORKING_DIRECTORY);

	#Check the supplied arguments are valid and sufficient parameters provided
	if($#args >= 0){
		#Check that the 'init' command has no extra arguments passed in
		if($args[0] eq "init"){
			if($#args >0){
				printf STDERR "Usage: $0 init\n";
				exit(1);
			}
		#The supplied command cannot be found, print error and exit
		}elsif($args[0] eq "add"){
			if($#args < 1){
				printf STDERR "legit.pl: error: internal error Nothing specified, nothing added.\n";
				exit(1);
			}else{
				foreach my $file(@args[1..$#args]){
					if($file =~ /^[\.|\/]/){
						printf STDERR "legit.pl: error: invalid filename '$file'\n";
						exit(1);
					}elsif($file =~ /^-/){
						printf STDERR "Usage: legit.pl <filenames>\n";
						exit(1);
					}elsif(!(-f $file)){
						printf STDERR "legit.pl: error: can not open '$file'\n";
						exit(1);
					}
				}
			}
		}else{
			print STDERR "legit.pl: error: unknown command $args[0]\n";
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

#Deals with initialising the .legit folder (if it doesn't already exist)
sub initLegit{

	#Check if the .legit folder already exists
	#Exits with error message if it does
	if(-d $ROOT_FOLDER){
		printf STDERR "legit.pl: error: .legit already exists\n";
		exit(1);
	}

	#Create the .legit folder
	mkdir($ROOT_FOLDER);

	#Create all the subdirectories
	chdir($ROOT_FOLDER);
	mkdir($LOGS_FOLDER);
	mkdir($SNAPSHOT_FOLDER);
	mkdir($REFS_FOLDER);
	mkdir($HEADS_FOLDER);
	mkdir($INDEX_FOLDER);

	mkdir("$LOGS_FOLDER/$REFS_FOLDER");
	mkdir("$LOGS_FOLDER/$HEADS_FOLDER");


	#Print success message
	printf "Initialized empty legit repository in .legit\n";

}

sub changedFiles{
	if(compare("10.txt", ".legit/index/10.txt")==0){
		printf "The files are equal\n";
	}else{
		printf "The files aren't equal\n";
	}
}

#Deals with adding a copy of the files to the temporary index folder
sub addLegit{
	my @files = @_;

	#Checks that the .legit folder is actually present
	if(!(-d ".legit")){
		printf STDERR "legit.pl: error: no .legit directory containing legit repository exists\n";
		exit(1);
	}

	#Copies each of the listed files into the index folder
	foreach my $file(@files){
		copy($file, ".legit/index/$file");
	}
}