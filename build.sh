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

#the cloned repo will live in ../DIRECTORY_ROOT/REPO_DIRECTORY
DIRECTORY_ROOT="../privatebuild/"

#get the lastest part of the directory name
IFS="/"
SPLIT_DIR=(`pwd`)
SIZE=${#SPLIT_DIR[@]}
let LAST_INDEX=$SIZE-1
DIRECTORY_SUFFIX=${SPLIT_DIR[$LAST_INDEX]}
IFS=""

DIRECTORY="${DIRECTORY_ROOT}${DIRECTORY_SUFFIX}"

BRANCH=`git branch | grep "*" | awk '{print $NF}'`

#fresh clone
rm -Rf $DIRECTORY
git clone -slb "$BRANCH" . $DIRECTORY
cd $DIRECTORY

echo ""
echo "***** Working on branch $BRANCH *****"
echo ""

say() {
    if [ `uname -s` == "Darwin" ]; then
        # On Mac OS, notify via Notification Center
        osascript -e "display notification \"Build finished\" with title \"Maven - Branch $BRANCH - $RESULT\""
    fi
    if [ `uname -s` == "Linux" ]; then
        # On Linux, notify via notify-send
        which notify-send && notify-send "Maven - branch $BRANCH" "$RESULT"
    fi
}

if [ -e "pom.xml" ]; then
  if [[ $# -eq 0 ]]; then
    mvn clean install
  else
    mvn "$@"
  fi

  if [ $? -eq 0 ]; then
    RESULT="Build SUCCESS"
    echo $RESULT
    say
  else
    RESULT="Build FAILURE"
    echo $RESULT
    say
    exit $?
  fi
fi
