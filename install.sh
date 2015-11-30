#!/bin/sh
#
# Steps will be executed in the order they were added.  They can only be added
# at most once if they have not been blocked already (adding implies blocking).
# To add a custom step <s>, just implement "function <s>()".  Keep in mind that
# blocking or reordering may render install.sh & friends non-functional.


[ ! "$BASH" -a -x /bin/bash ] && exec /bin/bash "$0" "$@"

set -e

function on_error() {
  setup "An error occurred, exiting."
  restore_msys "$_PID"
}
trap on_error ERR

echo -n "Build Starting at "
date

GC_WIN_DIR="$(dirname "$0")"
. "$GC_WIN_DIR/functions.sh"

qpushd "$GC_WIN_DIR"
. ./defaults.sh
. ./install-impl.sh

# variables
register_env_var ACLOCAL_FLAGS " "
register_env_var ENCHANT_LDFLAGS " "
register_env_var GNOME_CPPFLAGS " "
register_env_var GNOME_LDFLAGS " "
register_env_var GNUTLS_CPPFLAGS " "
register_env_var GNUTLS_LDFLAGS " "
register_env_var GUILE_LOAD_PATH ";"
register_env_var GUILE_CPPFLAGS " "
register_env_var GUILE_LDFLAGS " "
register_env_var HH_CPPFLAGS " "
register_env_var HH_LDFLAGS " "
register_env_var INTLTOOL_PERL " "
register_env_var LIBDBI_CPPFLAGS " "
register_env_var LIBDBI_LDFLAGS " "
register_env_var LIBXSLT_LDFLAGS " "
register_env_var KTOBLZCHECK_CPPFLAGS " "
register_env_var KTOBLZCHECK_LDFLAGS " "
register_env_var PATH ":"
register_env_var PCRE_CPPFLAGS " "
register_env_var PCRE_LDFLAGS " "
register_env_var PKG_CONFIG " "
register_env_var PKG_CONFIG_PATH ":"
register_env_var READLINE_CPPFLAGS " "
register_env_var READLINE_LDFLAGS " "
register_env_var REGEX_CPPFLAGS " "
register_env_var REGEX_LDFLAGS " "
register_env_var SQLITE_CFLAGS " "
register_env_var SQLITE_LIBS " "

# steps
# There is no reason to ever need to comment these out!
# * commented out glade, as it is not needed to run gnucash
add_step inst_prepare
if [ "$CROSS_COMPILE" != "yes" ]; then
 add_step inst_msys
fi
add_step inst_mingw
# Install html help as soon as possible.
# It's the only step requiring human
# interaction, so better do it at the beginning
# so the user doesn't need to wait all the time.
if [ "$CROSS_COMPILE" != "yes" ]; then
 add_step inst_hh
fi
add_step inst_regex
add_step inst_readline
add_step inst_exetype
add_step inst_gnome
add_step inst_guile
if [ "$CROSS_COMPILE" != "yes" ]; then
 add_step inst_git
fi
add_step inst_gnutls
add_step inst_libxslt
add_step inst_isocodes
add_step inst_swig
add_step inst_pcre
add_step inst_libgsf
add_step inst_goffice
#add_step inst_glade
add_step inst_opensp
add_step inst_libofx
## Online banking:
add_step inst_gwenhywfar
add_step inst_ktoblzcheck
add_step inst_aqbanking
add_step inst_libdbi

# libsoup and enchant needed by webkit
add_step inst_libsoup
add_step inst_enchant
add_step inst_webkit
#boost now needed for C++ on master only
add_step inst_boost

##
if [ "$WITH_CUTECASH" = "yes" ]; then
 add_step inst_cmake
 add_step inst_cutecash
fi

if [ "$WITH_CMAKE" = "yes" ]; then
	add_step inst_cmake
	CMAKE_GENERATOR="MSYS Makefiles"
	if [ "$WITH_NINJA" = "yes" ]; then
		add_step inst_ninja
		CMAKE_GENERATOR="Ninja"
	fi
	add_step inst_gnucash_using_cmake
else	
    add_step inst_gnucash
fi

if [ "$CROSS_COMPILE" != "yes" ]; then
 add_step inst_inno
fi
add_step inst_docs
add_step inst_finish

# run commands registered with late_eval
eval_now

for step in "${steps[@]}" ; do
    eval $step
done

setup Restore MSYS
restore_msys "$_PID"

qpopd

echo -n "Build Finished at "
date

### Local Variables: ***
### sh-basic-offset: 4 ***
### indent-tabs-mode: nil ***
### End: ***
