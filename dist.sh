#!/bin/sh

set -e

function on_error() {
  setup "An error occurred, exiting."
  restore_msys "$_PID"
}
trap on_error ERR

echo -n "Build (dist) Starting at "
date

GC_WIN_DIR="$(dirname "$0")"
. "$GC_WIN_DIR/functions.sh"

qpushd "$GC_WIN_DIR"
. defaults.sh
. dist-impl.sh

# variables
register_env_var PATH ":"

# steps
add_step dist_prepare
add_step dist_mingw
add_step dist_regex
add_step dist_guile
add_step dist_gnome
add_step dist_isocodes
add_step dist_pcre
add_step dist_libgsf
add_step dist_goffice
add_step dist_libofx
add_step dist_gnutls
add_step dist_gwenhywfar
add_step dist_aqbanking
add_step dist_libdbi
add_step dist_webkit
add_step dist_icu4c
add_step dist_boost
add_step dist_gnucash
add_step dist_finish

# run commands registered with late_eval
eval_now

for step in "${steps[@]}" ; do
    eval $step
done

setup Restore MSYS
restore_msys "$_PID"

qpopd


echo -n "Build (dist) Finished at "
date

### Local Variables: ***
### sh-basic-offset: 4 ***
### indent-tabs-mode: nil ***
### End: ***
