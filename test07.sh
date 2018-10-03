#!/bin/bash

#Test 8 - Testing Status - all file changed possibilities
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
bell=`tput bel`

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

seq 1 10 > a #changed, not staged
seq 11 20 > b #changed, staged
seq 21 30 > c #changed, different to staged

#Add files and commit normally

./legit.pl add a b c

./legit.pl commit -m "initial" > /dev/null 2>&1

echo 11 >> a
echo 21 >> b
echo 31 >> c
./legit.pl add b c
echo 32 >> c

output=$(perl legit.pl status 2>&1)
echo $output

if [[ $output == "a - same as repo\nb - added to index\nc - untracked" ]]
then
	echo "${green}Successful - Status - 4 -> 6 works${reset}"
else
	echo "${red}Failed - Status - 4 -> 6 not working${reset}"
	exit 1
fi
