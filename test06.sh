#!/bin/bash

#Test 7 - Testing Status - untracked, added to index, same as repo
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > a #same as repo
seq 11 20 > b #Added to index
seq 21 30 > c #Untracked

#Add files and commit normally

./legit.pl add a

./legit.pl commit -m "initial" > /dev/null 2>&1

./legit.pl add b 2>&1

output=$(perl legit.pl status 2>&1)


if [[ $output == "a - same as repo\nb - added to index\nc - untracked" ]]
then
	echo "${green}Successful - Status - 1 -> 3 works${reset}"
else
	echo "${red}Failed - Status - 1 -> 3 not working${reset}"
	exit 1
fi
