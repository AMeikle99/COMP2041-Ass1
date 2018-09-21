#!/bin/bash

#Test 2 - Testing the add functionality
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > 10.txt
seq 11 20 > 20.txt
seq 21 30 > 30.txt

#Add non-existent file
output=$(perl legit.pl add 40.txt 2>&1)

if [[ "$output" == "legit.pl: error: can not open '40.txt'" ]]
then
	echo "${green}Success - Failed to Add 40.txt${reset}"
else
	echo "${red}Failure - Error with adding fake files${reset}"
	exit 1
fi

#Add one real file
./legit.pl add 10.txt > /dev/null 2>&1

if [[ -f ".legit/index/10.txt" ]]
then
	echo "${green}Success - 10.txt added to index${reset}"
else
	echo "${red}Failure - 10.txt not added to index${reset}"
	exit 1
fi

#Add multiple real files
./legit.pl add 20.txt 30.txt > /dev/null 2>&1

if [[ -f ".legit/index/20.txt" && -f ".legit/index/30.txt" ]]
then
	echo "${green}Success - both files added${reset}"
else
	echo "${red}${bell}Failure - files not added${reset}"
	exit 1
fi

exit 0