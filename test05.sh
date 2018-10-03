#!/bin/bash

#Test 4 - Testing Show
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > 10.txt
seq 11 20 > 20.txt
seq 21 30 > 30.txt

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
#Show - Non Existent Branch & Real File

output=$(perl legit.pl show 1:10.txt 2>&1)
if [[ $output == "legit.pl: error: unknown commit '1'" ]]
then
	echo "${green}Successful - Show Non Existent Branch & Real File${reset}"
else
	echo "${red}Failed - Show Non Existent Branch & Real File${reset}"
	exit 1
fi

#Show - Real Branch & Real File

output=$(perl legit.pl show 0:10.txt 2>&1)
if [[ $? == 0 ]]
then
	echo "${green}Successful - Show Real Branch & Real File${reset}"
else
	echo "${red}Failed - Show Real Branch & Real File${reset}"
	exit 1
fi