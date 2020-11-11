1 NAME
======

  cl-release --- A simple release manager for Common Lisp projects


2 SYNOPSIS
==========

  ,----
  | $ release-prepare example 0.12
  | Preparing release example-0.12
  | Setting version...
  | Loading system and running tests...
  | Finished.
  | 
  | $ release-perform
  | Performing release for example-0.12
  | Tagging release...
  | Set development version to 0.13.0
  | Pushing repository...
  | Finished.
  `----


3 DESCRIPTION
=============

  Simple tool to make releases in Common Lisp projects. This somewhat
  resembles the Maven Release Plugin.

  Making a release consists of two phases:

  1. Loading and compiling the sources and running the tests. If this
     succeeds then proceed with step;
  2. Perform the actual release by creating a git tag for this version
     and pushing the release to the repository.

  The second step also increments the version number for the next
  development release.


3.1 CLI
~~~~~~~

3.1.1 `release-prepare'
-----------------------

  ,----
  | Usage: release-prepare [options] SYSTEM VERSION
  | 
  | Options:
  |   -cl, --lisp-implementation            Specify the lisp implemntation. Defaults
  |                                         to sbcl --non-interactive.
  |   -f, --force                           Force running the script, regardless if a release is active.
  |   -v, --version                         Show version.
  |   -h, --help                            Show help.
  `----


3.1.2 `release-perform'
-----------------------

  ,----
  | Usage: release-perform [options]
  | 
  | Options:
  |   --no-push                              Don't push to remote repository
  |   -n, --next-dev-version                 Specify the next development version
  |   -v, --version                          Show version.
  |   -h, --help                             Show help.
  `----


4 AUTHORS
=========

  Sebastian Christ (<mailto:rudolfo.christ@gmail.com>)


5 COPYRIGHT
===========

  Copyright (c) 2020 Sebastian Christ (rudolfo.christ@gmail.com)


6 LICENSE
=========

  Released under the AGPL license.
