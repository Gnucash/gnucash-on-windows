#!/bin/sh
#
# Notes:
# 1. for this script to work, git must have been setup before
#    in a way that doesn't conflict with the GnuCash build.
#    If you set up the build environment using the bootstrap script
#    this should have been taken care of automatically.
#
# 2. Should this script change in the source repository, then the
#    git pull below will fail due to a limitation in Windows that
#    won't allow to change a file that is "in use". So in the rare
#    situation this script needs to be updated, you will need to
#    run the git pull once yourself.

set -e

# Determine how frequently to run this script
# Currently only 'weekly' restricts the run frequency
# Any other periodicity will just run the script regardless of how long it has
# been since the last run.
# As this script is meant to be called from build_periodic.bat the frequency
# that script is run will effectively determine how regularly this script is run.
periodicity=$1
if [ x$periodicity = xweekly ]
  ## Only run this script on Monday night (first day of the week)
  if [ `date +%u` != 1 ]
  then 
    exit
  fi
fi

function qpushd() { pushd "$@" >/dev/null; }
function qpopd() { popd >/dev/null; }
function unix_path() { echo "$*" | sed 's,^\([A-Za-z]\):,/\1,;s,\\,/,g'; }

_BUILDSERVER_UDIR="$(dirname $(unix_path "$0"))"
qpushd "$_BUILDSERVER_UDIR/.."
. ./functions.sh
. ./defaults.sh

# Variables
_GIT_UDIR=`unix_path $GIT_DIR`
set_env "$_GIT_UDIR/bin/git" GIT_CMD
export GIT_CMD

# Update the gnucash-on-windows build scripts
_GC_WIN_REPOS_UDIR=`unix_path $GC_WIN_REPOS_DIR`
qpushd "$_GC_WIN_REPOS_UDIR"
$GIT_CMD pull
qpopd

################################################################
# determine if there are any new commits since the last time we ran
#
_REPOS_UDIR=`unix_path $REPOS_DIR`
qpushd "$_REPOS_UDIR"

# Update the gnucash repository
$GIT_CMD pull
# If we don't have a rev file then start from 'now' and force a build
revfile=$_GC_WIN_REPOS_UDIR/last_rev_periodic
if [ ! -f ${revfile} ] ; then
  oldrev=a   # definitely an invalid, so non-existing git rev
else
  oldrev=$(cat ${revfile})
fi
newrev=$($GIT_CMD rev-parse HEAD)
qpopd # leave gnucash repository

if [[ "${oldrev}" != "${newrev}" ]]; then
  $_BUILDSERVER_UDIR/build_package.sh
fi

# move the new file into place, will only happen if the build was successful
echo ${newrev} > ${revfile}

qpopd # return to directory the script was invoked from (not necessarily the directory this script resides in)
