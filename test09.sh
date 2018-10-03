#!/bin/bash

#Test 10 - Testing rm - with flags 1 for --cached, one for --force, both with exit status 0 to test for.
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


./legit.pl rm --cached a 2>&1


if [[ $? == 0  && ! -e ".legit/index/a" ]]
then
	echo "${green}Successful - rm (with --cached) works${reset}"
else
	echo "${red}Failed - rm (with --cached) doesn't work${reset}"
	exit 1
fi

./legit.pl add a
echo 11 >> a
./legit.pl add a
echo 12 >> a
./legit.pl rm --force a > /dev/null 2>&1


if [[ $? == 0 && ! -e a ]]
then
	echo "${green}Successful - rm (with --force) works${reset}"
else
	echo "${red}Failed - rm (with -- force) doesn't work${reset}"
	exit 1
fi