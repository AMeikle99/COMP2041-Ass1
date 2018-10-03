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

our $WORKING_DIRECTORY = getcwd();
our $CURRENT_BRANCH;
our $CURRENT_SNAPSHOT = -1;

our $MAX_COMMIT;
our %COMMIT_HISTORY;

######################

main();

######################


sub main{

	my @args = @ARGV;

	loadGlobals();
	#Parse the command arguments and check they are valid
	validateArguments(@ARGV);
	

	if($args[0] eq "init"){
		initLegit(@args);
	}else{
		#Checks that the .legit folder is actually present
		if(!(-d ".legit")){
			printf STDERR "legit.pl: error: no .legit directory containing legit repository exists\n";
			exit(1);
		}

		if($args[0] eq "add"){
			shift @args;
			addLegit(@args);
		}elsif($args[0] eq "commit"){
			commitLegit(@args);
		}elsif($args[0] eq "log"){
			logLegit();
		}elsif($args[0] eq "show"){
			showLegit(@args);
		}elsif($args[0] eq "status"){
			statusLegit();
		}elsif($args[0] eq "rm"){
			shift @args;
			#Check for additional parameters for the rm command
			#Pass 1 or 0 as a sort of boolean indicator
			my $isForce = 0;
			my $isCached = 0;
			if($args[0] eq "--force"){
				$isForce = 1;
				shift @args;
				if($args[0] eq "--cached"){
					$isCached = 1;
					shift @args;
				}
			}elsif($args[0] eq "--cached"){
				$isCached = 1;
				shift @args;
				if($args[0] eq "--force"){
					$isForce = 1;
					shift @args;
				}
			}
			rmLegit($isCached, $isForce, @args);
		}
	}


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
		}elsif($args[0] eq "commit"){
			if($#args < 2 || $#args > 3){
				printf STDERR "usage: legit.pl -m commit-message\n";
				exit(1);
			}

			if($#args == 2){
				if($args[1] ne "-m"){
					printf STDERR "usage: legit.pl -m commit-message\n";
					exit(1);
				}
			}elsif($#args == 3){
				if($args[1] ne "-a" && $args[2] ne "-m"){
					printf STDERR "usage: legit.pl -m commit-message\n";
					exit(1);
				}
			}
		}elsif($args[0] eq "log"){
			if($#args >0){
				printf STDERR "usage: legit.pl log\n";
				exit(1);
			}
		}elsif($args[0] eq "show"){
			if($#args != 1){
				printf STDERR "usage: legit.pl show <commit>:<filename>\n";
				exit(1);
			}elsif($args[1] !~ /:/){
				printf STDERR "legit.pl: error: invalid object $args[1]\n";
				exit(1);
			}
		}elsif($args[0] eq "status" && $#args == 0){
			if($CURRENT_SNAPSHOT eq -1){
				printf "legit.pl: error: your repository does not have any commits yet\n";
				exit(1);
			}
		}elsif($args[0] eq "rm"){
			if($CURRENT_SNAPSHOT eq -1){
				printf "legit.pl: error: your repository does not have any commits yet\n";
				exit(1);
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


#Deals with adding a copy of the files to the temporary index folder
sub addLegit{
	my @files = @_;

	#Copies each of the listed files into the index folder
	foreach my $file(@files){
		copy($file, "$ROOT_FOLDER/$INDEX_FOLDER/$file");
	}
}

#Deals with committing the files in the index to a snapshot in memory
#All files from current commit for the current branch are stored here
sub commitLegit{
	my @args = @_;

	my $commitMessage = $args[$#args];

	#If -a is specified then copy all the files into the index
	if($args[1] eq "-a"){
		#Get a list of index files and copy the corresponding ones from the Working Directory
		my @files = glob("$ROOT_FOLDER/$INDEX_FOLDER/*");
		foreach my $file(@files){
			$file =~ /\/([a-zA-Z0-9_.\-]+)$/;
			my $fileName = $1;
			copy($fileName, "$file");
		}
	}


	#Checks if this is the first commit (deleting the COMMIT_HISTORY will mess with the numbering though)
	if(!(-e "$ROOT_FOLDER/COMMIT_HISTORY")){
		my @allFiles = glob("$ROOT_FOLDER/$INDEX_FOLDER/*");
		if(!($#allFiles >= 0)){
			printf "nothing to commit\n";
			exit(0);
		}

		#Initialize globals
		$MAX_COMMIT = 0;
		$CURRENT_SNAPSHOT = ".S0";
		$CURRENT_BRANCH = "master";
		#Create all helper files
		open F, ">", "$ROOT_FOLDER/COMMIT_HISTORY" or die "Error initializing commit files";
		printf F "$MAX_COMMIT $commitMessage\n";
		close F;

		open F, ">", "$ROOT_FOLDER/COMMIT_MSG" or die "Error initializing commit files";
		printf F "$MAX_COMMIT $commitMessage\n";
		close F;

		open F, ">", "$ROOT_FOLDER/CURRENT_BRANCH" or die "Error initializing commit files";
		printf F "$CURRENT_BRANCH\n";
		close F;

		open F, ">", "$ROOT_FOLDER/$LOGS_FOLDER/$HEADS_FOLDER/$CURRENT_BRANCH" or die "Error initalizing commit files";
		printf F "commit (initial): $MAX_COMMIT $commitMessage\n";
		close F;

		open F, ">", "$ROOT_FOLDER/$LOGS_FOLDER/HISTORY" or die "Error initializing commit files";
		printf F "$CURRENT_BRANCH: commit (initial commit): $MAX_COMMIT $commitMessage\n";
		close F;

		open F, ">", "$ROOT_FOLDER/$HEADS_FOLDER/$CURRENT_BRANCH" or die "Error initializing commit files";
		printf F "snapshot: $CURRENT_SNAPSHOT\n";
		close F;

		#Save the current commit to the snapshot folder
		printf "Committed as commit $MAX_COMMIT\n";
		createSnapshot(@allFiles);
		exit(0);
	#Otherwise this will be a subsequent commit (1,2,3...etc)	
	}else{
		#Get a list of all the files in the index folder
		my @allFiles = glob("$ROOT_FOLDER/$INDEX_FOLDER/*");
		#Check that at least one file in the index is different from the most recent snapshot
		if(!commitCheckIndexFiles()){
			printf "nothing to commit\n";
			exit(0);
		}

		#Update globals
		$MAX_COMMIT += 1;
		$CURRENT_SNAPSHOT =~ s/([0-9]+)/$MAX_COMMIT/;

		printf "Committed as commit $MAX_COMMIT\n";
		createSnapshot(@allFiles);
		
		#Update all helper files
		#Updates the commit history file
		open F, ">>", "$ROOT_FOLDER/COMMIT_HISTORY" or die "Error reading commit files";
		printf F "$MAX_COMMIT $commitMessage\n";
		close F;

		#Stores the most recent Commit message
		open F, ">", "$ROOT_FOLDER/COMMIT_MSG" or die "Error reading commit files";
		printf F "$MAX_COMMIT $commitMessage\n";
		close F;

		#Updates the log file for the current branch
		open F, ">>", "$ROOT_FOLDER/$LOGS_FOLDER/$HEADS_FOLDER/$CURRENT_BRANCH" or die "Error reading commit files";
		printf F "commit: $MAX_COMMIT $commitMessage\n";
		close F;

		#Updates the whole repository history
		open F, ">>", "$ROOT_FOLDER/$LOGS_FOLDER/HISTORY" or die "Error reading commit files";
		printf F "$CURRENT_BRANCH: commit: $MAX_COMMIT $commitMessage\n";
		close F;

		#Stores the current most recent snapshot for the current branch
		open F, ">", "$ROOT_FOLDER/$HEADS_FOLDER/$CURRENT_BRANCH" or die "Error reading commit files";
		printf F "snapshot: $CURRENT_SNAPSHOT\n";
		close F;

		exit(0);
	}

}

#This reads in the commit history file and displays it in order from newest to oldest (i.e reversed on how it's stored)
sub logLegit{

	#If there are no commits yet, print error message
	if(!(-e "$ROOT_FOLDER/COMMIT_HISTORY")){
		printf STDERR "legit.pl: error: your repository does not have any commits yet\n";
		exit(1);
	}

	#Open the COMMIT_HISTORY file and read in the contents to the global hash
	open F, "<", "$ROOT_FOLDER/COMMIT_HISTORY" or die "Error finding the commit history file";
	while(my $line = <F>){
		$line =~ /([0-9]+)\s(.+)/;
		my $commit = $1;
		my $message = $2;
		$COMMIT_HISTORY{$commit} = $2;
	}
	close F;

	#Print out each commit message, newest first
	foreach my $commit(reverse sort keys %COMMIT_HISTORY){
		printf "$commit $COMMIT_HISTORY{$commit}\n";
	}

}

sub showLegit{
	my @args = @_;
	my $filePath = "";

	#Split apart the <commit>:<filename> argument
	my $arg2 = $args[1];
	$arg2 =~ /(.*):(.*)/;
	my $commitName = $1;
	my $filename = $2;

	#Check all cases of invalid input
	#Where no commit is given
	if($commitName eq ""){
		#Check the filename supplied is valid
		if(($filename eq "") || ($filename !~ /^[a-zA-Z0-9]/)){
			printf STDERR "legit.pl: error: invalid filename '$filename'\n";
			exit(1);
		#Check that the file exists in index
		}else{
			if(!(-e "$ROOT_FOLDER/$INDEX_FOLDER/$filename")){
				printf STDERR "legit.pl: error: '$filename' not found in index\n";
				exit(1);
			#File does exist so set filepath of file to open
			}else{
				$filePath = "$ROOT_FOLDER/$INDEX_FOLDER/$filename";
			}
		}
	#A commit number is supplied
	}else{
		#Check the commit number is valid
		if($commitName > $MAX_COMMIT){
			printf STDERR "legit.pl: error: unknown commit '$commitName'\n";
			exit(1);
		#Commit number is valid
		}else{
			#Checks the filename supplied is valid
			if(($filename eq "") || ($filename !~ /^[a-zA-Z0-9]/)){
				printf STDERR "legit.pl: error: invalid filename '$filename'\n";
				exit(1);
			#Check the file exists in the commit
			}else{
				if(!(-e "$ROOT_FOLDER/$SNAPSHOT_FOLDER/.S$commitName/$filename")){
				printf STDERR "legit.pl: error: '$filename' not found in commit $commitName\n";
				exit(1);
				#File does exist so set the filepath of file to open
				}else{
					$filePath = "$ROOT_FOLDER/$SNAPSHOT_FOLDER/.S$commitName/$filename";
				}
			}
		}
	}

	#Display the file
	open F, "<", $filePath or die "Unable to open file. Exiting";
	printf $_  while(<F>);
	close F;


}

#Shows the status of all the files in the CWD, Index & Repo
sub statusLegit{

	#A hash that maps the names of all the files present with a code that determines their state:
	#0 = Untracked, 1 = Added to Index, 2 = Same as repo, 3 = Changed, not staged
	#4 = Changed, Staged, 5 = Different changes staged for commit
	#6 = Deleted, #7 = File Deleted
	my %allFiles = ();

	#Get file names from the CWD
	my @folderFiles = glob("*");
	foreach my $file(@folderFiles){
		if(!defined $allFiles{$file}){
			#printf "CWD: Adding $file to hash\n";
			$allFiles{"$file"} = -1;
		}
	}

	#Get file names from index
	@folderFiles = glob("$ROOT_FOLDER/$INDEX_FOLDER/*");
	foreach my $file(@folderFiles){
		$file =~ /\/([a-zA-Z0-9_.\-]+)$/;
		my $fileName = $1;
		if(!defined $allFiles{$fileName}){
			#printf "Index: Adding $fileName to hash\n";
			$allFiles{"$fileName"} = -1;
		}
	}

	#Get file names from most recent snapshot
	@folderFiles = glob("$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/*");
	foreach my $file(@folderFiles){
		$file =~ /\/([a-zA-Z0-9_.\-]+)$/;
		my $fileName = $1;
		if(!defined $allFiles{$fileName}){
			#printf "Snapshot: Adding $fileName to hash\n";
			$allFiles{"$fileName"} = -1;
		}
	}

	#For each file check conditions to check for its status
	foreach my $file(sort keys %allFiles){
		#Check for untracked files
		if((-e $file) && !(-e "$ROOT_FOLDER/$INDEX_FOLDER/$file")){
			printf "$file - untracked\n";
			$allFiles{$file} = 0;
		}
		#Option 1 - File exists in index but not in snapshot
		if((-e "$ROOT_FOLDER/$INDEX_FOLDER/$file") && !(-e "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file")){
			printf "$file - added to index\n";
			$allFiles{$file} = 1;
		}
		#Check for options 2-5
		if((-e $file) && (-e "$ROOT_FOLDER/$INDEX_FOLDER/$file") && (-e "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file")){
			#Options 2-5
			#Option 2 - Same as repo
			if((compare("$file", "$ROOT_FOLDER/$INDEX_FOLDER/$file") == 0) && compare("$file", "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file")==0){
				printf "$file - same as repo\n";
				$allFiles{$file} = 2;
			#Option 3 - Changed, not staged (CWD file is different to index, but index hasn't changed from last commit)
			}elsif((compare("$file", "$ROOT_FOLDER/$INDEX_FOLDER/$file")!=0) && (compare("$ROOT_FOLDER/$INDEX_FOLDER/$file", "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file")==0)){
				printf "$file - file changed, changes not staged for commit\n";
				$allFiles{$file} = 3;
			#Option 4 - Changed and Staged
			}elsif((compare("$file", "$ROOT_FOLDER/$INDEX_FOLDER/$file")==0) && (compare("$ROOT_FOLDER/$INDEX_FOLDER/$file", "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file")!=0)){
				printf "$file - file changed, changes staged for commit\n";
				$allFiles{$file} = 4;
			#Option 5 - Different changes staged for commit
			}elsif((compare("$file", "$ROOT_FOLDER/$INDEX_FOLDER/$file")!=0) && (compare("$ROOT_FOLDER/$INDEX_FOLDER/$file", "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file")!=0)){
				printf "$file - file changed, different changes staged for commit\n";
				$allFiles{$file} = 5;
			}
		#Option 6 - File deleted from both index and CWD
		}elsif((-e "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file") && !(-e "$file") && !(-e "$ROOT_FOLDER/$INDEX_FOLDER/$file")){
			printf "$file - deleted";
			$allFiles{$file} = 6;
		#Option 7 - file delted from CWD only
		}elsif(!(-e "$file") && (-e "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file") && (-e "$ROOT_FOLDER/$INDEX_FOLDER/$file")){
			printf "$file - deleted";
			$allFiles{$file} = 7;
		}
	}
}

sub rmLegit{
	(my $isCached, my $isForce, my @files) = @_;

	if($isCached == 1){
		foreach my $file(@files){
			unlink "$ROOT_FOLDER/$INDEX_FOLDER/$file";
		}
	}elsif($isForce == 1){
		foreach my $file(@files){
			unlink $file;
			unlink "$ROOT_FOLDER/$INDEX_FOLDER/$file";
		}
	}else{
		foreach my $file(@files){
			if(!(-e "$ROOT_FOLDER/$INDEX_FOLDER/$file")){
				printf STDERR "legit.pl: error: '$file' is not in the legit repository\n";
				exit(1);
			}elsif(compare("$ROOT_FOLDER/$INDEX_FOLDER/$file", "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file") != 0){
				printf STDERR "legit.pl: error: '$file' has changes staged in the index\n";
				exit(1);
			}elsif(compare($file, "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$file") != 0){
				printf STDERR "legit.pl: error: '$file' in repository is different to working file\n";
				exit(1);
			}
		}

		foreach my $file(@files){
			unlink $file;
			unlink "$ROOT_FOLDER/$INDEX_FOLDER/$file";
		}
		
	}
}

#Copies all files in the index to a new snapshot folder
sub createSnapshot{
	my @files = @_;
	my $fileName;

	#Creates the new folder for the current snapshot
	mkdir("$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT");

	#Extracts the filename from the relative path and copies the file to the snapshot
	foreach my $file(@files){
		$file =~ /\/([a-zA-Z0-9_.\-]+)$/;
		$fileName = $1;
		copy($file, "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT/$fileName");
	}
	
}

#At the load of the program initialise all the global variables to store data like current branch, current max commit, current snapshot
sub loadGlobals{
	if(-e "$ROOT_FOLDER/COMMIT_HISTORY"){
		my $line;

		#Load Current Max Commit
		open F, "<", "$ROOT_FOLDER/COMMIT_MSG" or die "Legit has become corrupted, please reinitialise it";
		$line = <F>;
		$line =~ /^([0-9]+)/;
		$MAX_COMMIT = $1;
		close F;

		#Load Current branch name
		open F, "<", "$ROOT_FOLDER/CURRENT_BRANCH" or die "Legit has become corrupted, please reinitialise it";
		$CURRENT_BRANCH = <F>;
		chomp $CURRENT_BRANCH;
		close F;

		#Load what current snapshot is for the current branch
		open F, "<", "$ROOT_FOLDER/$HEADS_FOLDER/$CURRENT_BRANCH" or die "Legit has become corrupted, please reinitialise it";
		while($line = <F>){
			if($line =~ /(\.S[0-9]+)/){
				$CURRENT_SNAPSHOT = $1;
			}
		}


	}
}

#Helper function which checks if the files in index are different to their counter parts in the most recent commit snapshot
#If the file doesnt exist in the most recent commit then good to commit all
sub commitCheckIndexFiles{

	my $indexFolder = "$ROOT_FOLDER/$INDEX_FOLDER";
	my $snpshotFolder = "$ROOT_FOLDER/$SNAPSHOT_FOLDER/$CURRENT_SNAPSHOT";

	#Gets file lists for both the index and current snapshot
	chdir("$indexFolder");
	my @indexFiles = glob("*");
	chdir("$WORKING_DIRECTORY");
	chdir("$snpshotFolder");
	my @snapshotFiles = glob("*");
	chdir($WORKING_DIRECTORY);
	chdir($snpshotFolder);

	#Check if there are any files in index not in most recent snapshot (added file)
	foreach my $file(@indexFiles){
		#Does this index file exist in the snapshot folder
		if(!(-e $file)){
			chdir($WORKING_DIRECTORY);
			return 1;
		#File exists in both, are they the same?	
		}else{
			if(compare("$file", "$WORKING_DIRECTORY/$indexFolder/$file") != 0){
				chdir($WORKING_DIRECTORY);
				return 1;
			}
		}
	}

	#Goto index folder
	chdir("$WORKING_DIRECTORY/$indexFolder");
	#Check if there are any files in snapshot not in index folder (has been removed)
	foreach my $file(@snapshotFiles){
		#Does this index file exist in the snapshot folder
		if(!(-e $file)){
			chdir($WORKING_DIRECTORY);
			return 1;
		#File exists in both, are they the same?	
		}else{
			if(compare("$file", "$WORKING_DIRECTORY/$snpshotFolder/$file") != 0){
				chdir($WORKING_DIRECTORY);
				return 1;
			}
		}
	}


	return 0;
	
}

#My own function to copy files
sub copy_file{
	(my $oldFile, my $newFile) = @_;

	open OLD, "<", "$oldFile" or die "Cannot open $oldFile";
	open NEW, ">", "$newFile" or die "Cannot open $newFile";

	while(my $line = <OLD>){
		printf NEW "$line";
	}

	close OLD;
	close NEW;
}

#My own function to compare 2 files
sub compare_file{
	(my $file1, my $file2) = @_;

	open F1, "<", "$file1" or die "Cannot open $file1";
	open F2, "<", "$file2" or die "Cannot open $file2";

	my @fileText1 = <F1>;
	my @fileText2 = <F2>;

	printf "F1 Size: $#fileText1, F2 Size: $#fileText2\n";

	return 1;

}
