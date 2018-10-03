#!/bin/bash

#Testing Init (Creates a new .legit successfully & Cannot reinit a .legit repo)

rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

if [[ -d .legit ]]
then
	echo "Init Successful"
else
	echo "Init Failed"
	exit 1
fi

output=$(perl legit.pl init 2>&1)

if [[ "$output" == "legit.pl: error: .legit already exists" ]] 
then
	echo "Success - Aborted Program"
else
	echo "Failure - Program Didn't abort"
	exit 1
fi

exit 0