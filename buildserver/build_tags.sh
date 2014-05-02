#!/bin/sh
#
# Notes:
# 1. for this script to work, git must have been setup before
#    in a way that doesn't conflict with the GnuCash build.
#    The easiest way to do so is to run the build once manually
#    with a properly set up custom.sh.
#
# 2. Should this script change in the source repository, then the
#    git pull below will fail due to a limitation in Windows that
#    won't allow to change a file that is "in use". So in the rare
#    situation this script needs to be updated, you will need to
#    run the git pull once yourself.

set -e

function qpushd() { pushd "$@" >/dev/null; }
function qpopd() { popd >/dev/null; }
function unix_path() { echo "$*" | sed 's,^\([A-Za-z]\):,/\1,;s,\\,/,g'; }

################################################################
# Setup our environment  (we need the DOWNLOAD_DIR)

_BUILDSERVER_UDIR="$(dirname $(unix_path "$0"))"
qpushd "$_BUILDSERVER_UDIR/.."
pkgdir="`pwd`"
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
. ./functions.sh
. ./defaults.sh
qpopd


################################################################
# determine if there are any new tags since the last time we ran
#
_REPOS_UDIR=`unix_path $REPOS_DIR`
qpushd "$_REPOS_UDIR"

# Update the gnucash repository
$GIT_CMD fetch -t

# If we don't have a tagfile then start from 'now'
tagfile=$_GC_WIN_REPOS_UDIR/tags
if [ ! -f ${tagfile} ] ; then
  for one_tag in $($GIT_CMD tag)
  do
    tag_hash=$($GIT_CMD rev-parse ${one_tag})
    echo ${tag_hash}/${one_tag} >> ${tagfile}
  done
fi

# Figure out the new set of tags
rm -f ${tagfile}.new
for one_tag in $($GIT_CMD tag)
do
  tag_hash=$($GIT_CMD rev-parse ${one_tag})
  echo ${tag_hash}/${one_tag} >> ${tagfile}.new
done
tags="`diff --suppress-common-lines ${tagfile} ${tagfile}.new | grep '^> ' | sed -e 's/^> //g'`"
qpopd

# move the new file into place
mv -f ${tagfile}.new ${tagfile}

qpopd # return to directory the script was invoked from (not necessarily the directory this script resides in)

################################################################
# Now iterate over all the new tags (if any) and build a package

for tag_rev in $tags ; do
  tag=${tag_rev#*/}
  tag=${tag%/*}
  
  # Git builds are only supported from 2.5 up
  tag_major=${tag%%.*}
  tag_tmp=${tag#*.}
  tag_minor=${tag_tmp%%.*}
  major_minor=$(( $tag_major*100 + $tag_minor ))
  if (( $major_minor < 205 ))
  then
     continue
  fi
  
  TAG_GLOBAL_DIR="c:\\gcdev\\gnucash-${tag}"
  _TAG_GLOBAL_UDIR=$(unix_path "$TAG_GLOBAL_DIR")
  rm -fr $_TAG_GLOBAL_UDIR
  
  # Set up a clean build environment for this tag
  # This will automatically create a custom.sh with
  # several parameters correctly pre-set like
  # GLOBAL_DIR, DOWNLOAD_DIR,...
  $_GC_WIN_REPOS_UDIR/bootstrap_win_dev.vbs /s /GLOBAL_DIR:$TAG_GLOBAL_DIR /DOWNLOAD_DIR:$DOWNLOAD_DIR

  # Check out the tag and setup custom.sh
  TAG_REPOS_DIR="${TAG_GLOBAL_DIR}\\gnucash.git"
  _TAG_REPOS_UDIR=$(unix_path "$TAG_REPOS_DIR")
  qpushd $TAG_REPOS_DIR
  $GIT_CMD checkout $tag
  qpopd
  
  $TAG_WIN_REPOS_DIR="${TAG_GLOBAL_DIR}\\gnucash-on-windows.git"
  $_TAG_WIN_REPOS_UDIR=$(unix_path "$TAG_WIN_REPOS_DIR")
  #cp -p "${pkgdir}/custom.sh" ${_TAG_WIN_REPOS_UDIR}/custom.sh

  # BUILD_FROM_TARBALL is special:
  # in install.sh place we check !=yes, in defaults.sh =yes, in dist.sh =no
  # We want it to look like 'no' in install and defaults, but yes in dist
  # so this hack works!
  echo "BUILD_FROM_TARBALL=maybe" >> ${_TAG_WIN_REPOS_UDIR}/custom.sh

  # Point HH_DIR at the global installation because we don't need to redo it
  echo -n "HH_DIR=" >> ${_TAG_WIN_REPOS_UDIR}/custom.sh
  echo "${GLOBAL_DIR}\\hh" | sed -e 's/\\/\\\\/g' >> ${_TAG_WIN_REPOS_UDIR}/custom.sh

  # Now build the tag!  (this will upload it too)
  # Use the build_package script from master (cwd), not from the tag
  qpushd ${_TAG_WIN_REPOS_UDIR}
    ${pkgdir}/build_package.sh ${tag}
  qpopd
done
