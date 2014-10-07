#!/bin/sh

set -e

GC_WIN_DIR="$(dirname "$0")"
. "$GC_WIN_DIR/functions.sh"

qpushd "$GC_WIN_DIR"
. defaults.sh
reset_steps
. install.sh
qpopd

prepare
_INSTALL_WFSDIR=`win_fs_path $INSTALL_DIR`
_INSTALL_UDIR=`unix_path $INSTALL_DIR`

make_install "$@"
