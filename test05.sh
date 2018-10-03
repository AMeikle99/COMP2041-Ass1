#!/bin/bash

#Test 6 - Testing Commit -a
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > 10.txt
seq 11 20 > 20.txt
seq 21 30 > 30.txt

#Add files and commit normally

./legit.pl add 10.txt 20.txt 30.txt

./legit.pl commit -m "initial" > /dev/null 2>&1

echo 11 >> 10.txt;
echo 21 >> 20.txt;

output=$(perl legit.pl commit -a -m "second commit" 2>&1)

if [[ $output == "Committed as commit 1" ]]
then
	echo "${green}Successful - Commit -a Works${reset}"
else
	echo "${red}Failed - Commit -a not working${reset}"
	exit 1
fi