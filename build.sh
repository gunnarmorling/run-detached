#!/bin/bash
# Clones your existing repo and run the maven tests off this clone
# Tests are run on the the current branch at the time of cloning
#
# Note that you can work on the next bug while this is going on as
# tests are run off a cloned repo.
#
# $ build.sh
# runs 'maven clean install'
#
# $ build.sh test -pl module1,module2
# runs 'maven test -pl module1,module2'
#
# A notification is sent upon build completion if your OS supports it:
# - on Mac OS, install Growl and grownnotifier
# - on Linux, install send-notify
#
# Many thanks to David Gageot (http://blog.javabien.net) for the inspiration and optimization of this script.
#
# Released under the WTFPL license version 2 http://sam.zoy.org/wtfpl/
#
# Copyright (c) 2010 David Gageot
# Copyright (c) 2010-2011 Emmanuel Bernard
# Copyright (c) 2011 Sanne Grinovero

# The cloned repo will live in ../DIRECTORY_ROOT/REPO_DIRECTORY
DIRECTORY_ROOT="../_background-build/"
START_TIME=$SECONDS

NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2; tput bold)
WHITE=$(tput setaf 7; tput bold)
RED=$(tput setaf 1)

function red() {
    echo -e "$RED$*$NORMAL"
}

function green() {
    echo -e "$GREEN$*$NORMAL"
}

function white() {
    echo -e "$WHITE$*$NORMAL"
}

# Get the lastest part of the directory name
IFS="/"
SPLIT_DIR=(`pwd`)
SIZE=${#SPLIT_DIR[@]}
let LAST_INDEX=$SIZE-1
DIRECTORY_SUFFIX=${SPLIT_DIR[$LAST_INDEX]}
IFS=""

DIRECTORY="${DIRECTORY_ROOT}${DIRECTORY_SUFFIX}"

BRANCH=`git branch | grep "*" | awk '{print $NF}'`
COMMAND=$@

echo ""
white "***** Detached Build *****"
echo "Branch  : $BRANCH"
echo "Work dir: $EXECUTION_DIR"
echo "Command : $COMMAND"
echo ""

# Check out worktree with current branch
rm -Rf $DIRECTORY
git worktree prune
git worktree add --detach $DIRECTORY $BRANCH

cd $DIRECTORY

eval $(printf "%q " "$@")
STATUS=$?

ELAPSED_TIME=$(($SECONDS - $START_TIME))

say() {
    if [ `uname -s` == "Darwin" ]; then
        # On Mac OS, notify via Notification Center
        osascript -e "display notification \"$COMMAND\" with title \"$RESULT @ $DIRECTORY_SUFFIX ($(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec) \" subtitle \" Branch: $BRANCH\""
    fi
    if [ `uname -s` == "Linux" ]; then
        # On Linux, notify via notify-send
        which notify-send && notify-send "$RESULT @ $DIRECTORY_SUFFIX ($BRANCH, $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec)"
    fi
}

if [ $STATUS -eq 0 ]; then
    RESULT="SUCCESS"
    say
    green "Detached build - $RESULT"
else
    RESULT="FAILURE"
    say
    red "Detached build - $RESULT"
    exit $STATUS
fi
