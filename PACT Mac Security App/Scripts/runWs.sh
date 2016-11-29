#!/bin/sh

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#  DO NOT DELETE THIS FILE  !
#  IT NEEDS TO BE HERE      !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#####################################################
# Note: this file is meant to be run from
#   AppleScript ('with administrator privileged')
#   within the Swift code.
#####################################################

if [ "$1" == "" ]; then
    echo "Usage: $0 file1.sh file2.sh file3.sh ..."
    exit 1
fi

# Iterate through all arguments
for scriptName in "$@"
do
    #echo "runWs-su: $SUDO_USER"
    echo "[runWs.sh] scriptName: $scriptName"
    /bin/sh $scriptName -w
done
