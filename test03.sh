#!/bin/bash

#Test 3 - Testing Commit
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > 10.txt
seq 11 20 > 20.txt
seq 21 30 > 30.txt

#Commit - No message
output=$(perl legit.pl commit 2>&1)
if [[ $output == "usage: legit.pl -m commit-message" ]]
then
	echo "${green}Successful - Commit No message${reset}"
else
	echo "${red}Failed - Commit No message${reset}"
	exit 1
fi

#Commit - No files
output=$(perl legit.pl commit -m "initial" 2>&1)
if [[ $output == "nothing to commit" ]]
then
	echo "${green}Successful - Commit No files${reset}"
else
	echo "${red}Failed - Commit No files${reset}"
	exit 1
fi

#Commit - Several Files
./legit.pl add 10.txt 20.txt

output=$(perl legit.pl commit -m "initial" 2>&1)
if [[ $output == "Committed as commit 0" ]]
then
	echo "${green}Successful - Commit Several Files${reset}"
else
	echo "${red}Failed - Commit Several Files${reset}"
	exit 1
fi


#Commit - No change to current index
./legit.pl add 10.txt 20.txt

output=$(perl legit.pl commit -m "second" 2>&1)
if [[ $output == "nothing to commit" ]]
then
	echo "${green}Successful - Commit No change to current index${reset}"
else
	echo "${red}Failed - Commit No change to current index${reset}"
	exit 1
fi




