#!/bin/bash
# Author: Alberto García (@Tach80)
# This piece of simple code is written for a simple task: to gather
# data from a lot of servers at once. Of course, it could be used
# for evil purposes, but that's not the idea, and it wouldn't be
# easy in any case.
# This script connects to a server through SSH, using a predefined
# user. It would ask for the password if you don't have a ssh key
# (which you totally should). Then, it will ask your server for
# data about OS, kernel and architecture, and then it will dump it
# into a human readable form, something you could parse or reuse.

# REQUIREMENTS:
# A text file containing IPs and users to log in, separated by
# spaces. You can pass its route as a paramenter. Otherwise, the
# script will look for it in the current folder.
# User's password will be asked, if needed.

# PROLOGUE: routes and variables.
# Make changes here.
# 1.- Input/output files.
DEFAULT_INPUT=server_list.txt
DEFAULT_OUTPUT=server_data.txt
# 2.- Temporal files.
TEMP_FILE=temp.txt
BSD_TEMP_FILE=BSD_temp.txt


# Previous tests: search for servers data.
# What if a file is passed as a parameter?
if [ $# -eq 1 ]; then
  if [ -f $1 ]; then
		echo "Provided data file found, proceeding..."
		SERVER_LIST="$1"
	else
		echo "Data file does not exists."
		echo "Please check your file and try again."
		echo "Clue: Provide full file path."
		exit 1
	fi
else # What if no parameter is provided?
	if [ -f $DEFAULT_INPUT ]; then
		echo "Data file found, proceeding..."
		SERVER_LIST=$DEFAULT_INPUT
	else
		echo "Data file not found"
		echo "Please check your file and try again."
		exit 1
	fi
fi

# Main starts here.
while read line; do
        IP=$(echo $line | cut -d " " -f1)
        USER=$(echo $line | cut -d " " -f2)
#       PASSWORD=$(cut -f3)
        # Getting data to a temp file, to parse them.
        ssh $USER@$IP "lsb_release -a" >> $TEMP_FILE
        # Parsing data.
        if [ -s $TEMP_FILE ]; then # Usual procedure (Linux).
                SO=$(cat $TEMP_FILE | grep "[Dd]escription" | cut -f2 | cut -d " " -f1)
                VERSION=$(cat $TEMP_FILE | grep "[Rr]elease" | cut -f2)
		# This checks local machine, not remote. Solve it.
                KERNEL=$(ssh $USER@$IP "uname -r")
                ARCHITECTURE=$(ssh $USER@$IP "uname -m")
		rm $TEMP_FILE
        else # Probably a FreeBSD (need to check). Yet another parser.
                ssh $USER@$IP "uname -mrs" >> $BSD_TEMP_FILE
                SO=$(cat $BSD_TEMP_FILE | cut -f1)
                VERSION=$(cat $BSD_TEMP_FILE | cut -f2)
                # Still not sure about this:  KERNEL=$()
                ARCHITECTURE=$(cat $BSD_TEMP_FILE | cut -f3)
		rm $BSD_TEMP_FILE
        fi
	echo "$IP $SO $VERSION $KERNEL $ARCHITECTURE" >> $DEFAULT_OUTPUT
done < $SERVER_LIST
exit 0
