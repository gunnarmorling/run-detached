#!/bin/bash
#
# Creates a separate git worktree of your project and runs a given command there,
# allowing you to continue other work in the main work area in between.
# A notification is sent upon completion of the command executed in the worktree,
# if your OS supports it:
# - on Mac OS X, Notification Center is used
# - on Linux, install send-notify
#
# Usage:
#
# $ run-detached.sh <command>
#
# Example:
#
# $ run-detached.sh mvn clean install
#
# To improve usability, it's recommended to add an alias and/or function for your
# commonly used build tools to .bashrc or similar:
#
# alias rd=run-detached.sh
# function mvnd()
# {
#    run-detached.sh mvn "$@";
# }
#
# This lets you run the tool like so:
#
# $ rd mvn clean install
# $ mvnd clean install
#
# Acknowledgements:
#
# This script is based on build.sh by Emmanuel Bernard (https://gist.github.com/emmanuelbernard/787631).
#
# Many thanks to David Gageot, Emmanuel Bernard and Sanne Grinovero for their work on the
# original script. The following changes have been applied:
#
# - using git worktree instead of clone
# - using Notification Center on OS X
# - allowing to run any command, not just Maven
# - allowing to run commands from within sub-directories of the git repo
# - aborting if the workarea is dirty
#
# Released under the WTFPL license version 2 http://sam.zoy.org/wtfpl/
#
# Copyright (c) 2010 David Gageot
# Copyright (c) 2010-2011 Emmanuel Bernard
# Copyright (c) 2011 Sanne Grinovero
# Copyright (c) 2018 Gunnar Morling

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

START_TIME=$SECONDS

if [[ $(git status -s) ]]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

# Constants and functions
DETACHED_BUILD_DIR_NAME="_detached_build"

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

function notify() {
    if [ `uname -s` == "Darwin" ]; then
        # On Mac OS, notify via Notification Center
        osascript -e "display notification \"$COMMAND\" with title \"$RESULT @ $REPO_NAME ($(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec) \" subtitle \" Branch: $BRANCH\""
    fi
    if [ `uname -s` == "Linux" ]; then
        # On Linux, notify via notify-send
        which notify-send && notify-send "$RESULT @ $REPO_NAME ($BRANCH, $(($ELAPSED_TIME/60)) min $(($ELAPSED_TIME%60)) sec)"
    fi
}

REPO_ROOT=`git rev-parse --show-toplevel`
DETACHED_BUILD_DIR="$REPO_ROOT/../$DETACHED_BUILD_DIR_NAME/"
mkdir -p "$DETACHED_BUILD_DIR"
DETACHED_BUILD_DIR=`cd "$DETACHED_BUILD_DIR" && pwd`

# Get the last part of the git repo root dir name
IFS="/"
SPLIT_DIR=($REPO_ROOT)
SIZE=${#SPLIT_DIR[@]}
let LAST_INDEX=$SIZE-1
REPO_NAME=${SPLIT_DIR[$LAST_INDEX]}
IFS=""

# The worktree will live in REPO_ROOT/../DETACHED_BUILD_DIR_NAME/REPO_NAME
WORKTREE_DIRECTORY="${DETACHED_BUILD_DIR}/${REPO_NAME}"

# Get the execution dir to go to; either the worktree dir itself or a sub-dir of it,
# when invoked from a sub-dir of the git repo
CURRENT_DIR=`pwd`
if [ $CURRENT_DIR = $REPO_ROOT ]; then
    EXECUTION_DIR=$WORKTREE_DIRECTORY
else
    EXECUTION_DIR=$WORKTREE_DIRECTORY`echo $CURRENT_DIR | sed 's|'$REPO_ROOT'/|/|'`
fi

BRANCH=`git branch | grep "*" | awk '{print $NF}'`
COMMAND=$@

echo ""
white "***** Detached Build *****"
echo "Branch  : $BRANCH"
echo "Work dir: $EXECUTION_DIR"
echo "Command : $COMMAND"
echo ""

# Check out worktree with current branch
rm -Rf $WORKTREE_DIRECTORY
git worktree prune
git worktree add --detach $WORKTREE_DIRECTORY $BRANCH

cd $EXECUTION_DIR

# Don't fail immediately upon return code <> 0, instead show the notification
set +e

# Execute the given command
eval $(printf "%q " "$@")
STATUS=$?
set -e

ELAPSED_TIME=$(($SECONDS - $START_TIME))

if [ $STATUS -eq 0 ]; then
    RESULT="SUCCESS"
    notify
    green "Detached Build - $RESULT"
else
    RESULT="FAILURE"
    notify
    red "Detached Build - $RESULT"
    exit $STATUS
fi
