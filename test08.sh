#!/bin/bash

#Test 9 - Testing rm - no flags 1 for conflict, one no conflict
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > a #same as repo

#Add files and commit normally

./legit.pl add a

./legit.pl commit -m "initial" > /dev/null 2>&1

echo 11 >> a

output=$(perl legit.pl rm a 2>&1)


if [[ $output == "legit.pl: error: 'a' in repository is different to working file" ]]
then
	echo "${green}Successful - rm (with conflict) works${reset}"
else
	echo "${red}Failed - rm (with conflict) doesn't work${reset}"
	exit 1
fi

./legit.pl add a
./legit.pl commit -m "second" > /dev/null 2>&1
./legit.pl rm a > /dev/null 2>&1


if [[ $? == 0 ]]
then
	echo "${green}Successful - rm (no conflict) works${reset}"
else
	echo "${red}Failed - rm (no conflict) doesn't work${reset}"
	exit 1
fi