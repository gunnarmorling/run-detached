# run-detached.sh

Creates a separate git worktree of your project and runs a given command there,
allowing you to continue other work in the main work area in between.
A notification is sent upon completion of the command executed in the worktree,
if your OS supports it:

* on Mac OS, install Growl and grownnotifier
* on Linux, install send-notify

## Usage

    $ run-detached.sh <command>

Example:

    $ run-detached.sh mvn clean install

To improve usability, it's recommended to add an alias and/or function for your
commonly used build tools to .bashrc or similar:


    alias rd=run-detached.sh
    function mvnd()
    {
        run-detached.sh mvn "$@";
    }

This lets you run the tool like so:

    $ rd mvn clean install
    $ mvnd clean install

## Acknowledgements

This script is based on [build.sh](https://gist.github.com/emmanuelbernard/787631) by Emmanuel Bernard.

Many thanks to David Gageot, Emmanuel Bernard and Sanne Grinovero for their work on the
original script. The following changes have been applied:

* using git worktree instead of clone
* using Notification Center on OS X
* allowing to run any command, not just Maven
* allowing to run commands from within sub-directories of the git repo
* aborting if the workarea is dirty

Released under the [WTFPL license version 2](http://sam.zoy.org/wtfpl/)

Copyright (c) 2010 David Gageot, 2010-2011 Emmanuel Bernard, 2011 Sanne Grinovero, 2018 Gunnar Morling
