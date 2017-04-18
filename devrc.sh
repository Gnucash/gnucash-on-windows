# devrc.sh: Sets the paths for building and running programs with the
# gnucash-on-windows environment.
# Copyright 2014 John Ralls <jralls@ceridwen.fremont.ca.us
# This is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, see <http://www.gnu.org/licenses/>.
#
# Usage: In a MinGW shell
# . /c/gcdev/gnucash-on-windows.git/devrc.sh
# To restore the environment
# export PATH=$OLDPATH
# unset PKG_CONFIG_PATH
# unset CPPFLAGS
# unset LDFLAGS
# unset GIT_CMD
# Do NOT try to run install.sh or dist.sh within the devrc.sh environment.

export OLDPATH=$PATH

_currdir=`pwd`
_dirname=`basename $_currdir`
if [ $(expr $_dirname : gnucash-on-windows.*) -ne 0 ]; then
    GLOBAL_UDIR=`dirname $_currdir`
else
    echo "Source me in gnucash-on-windows so that I can set the right directory."
    return
fi
AQBANKING_UDIR=$GLOBAL_UDIR/aqbanking
CMAKE_UDIR=$GLOBAL_UDIR/cmake
GWENHYWFAR_UDIR=$GLOBAL_UDIR/gwenhywfar
ENCHANT_UDIR=$GLOBAL_UDIR/enchant
GNOME_UDIR=$GLOBAL_UDIR/gnome
GNUCASH_UDIR=$GLOBAL_UDIR/gnucash/inst
GNUTLS_UDIR=$GLOBAL_UDIR/gnutls
GOFFICE_UDIR=$GLOBAL_UDIR/goffice
GUILE_UDIR=$GLOBAL_UDIR/guile
LIBDBI_UDIR=$GLOBAL_UDIR/libdbi
LIBGSF_UDIR=$GLOBAL_UDIR/libgsf
LIBOFX_UDIR=$GLOBAL_UDIR/libofx
LIBSOUP_UDIR=$GLOBAL_UDIR/libsoup
LIBXSLT_UDIR=$GLOBAL_UDIR/libxslt
MYSQL_UDIR=$GLOBAL_UDIR/mysql
NINJA_UDIR=$GLOBAL_UDIR/ninja
OPENSP_UDIR=$GLOBAL_UDIR/opensp
PCRE_UDIR=$GLOBAL_UDIR/pcre
PGSQL_UDIR=$GLOBAL_UDIR/pgsql
REGEX_UDIR=$GLOBAL_UDIR/regex
SQLITE3_UDIR=$GLOBAL_UDIR/sqlite3
SWIG_UDIR=$GLOBAL_UDIR/swig
WEBKIT_UDIR=$GLOBAL_UDIR/webkit
BOOST_UDIR=$GLOBAL_UDIR/boost

PATH=$AQBANKING_UDIR/bin:$CMAKE_UDIR/bin:$GWENHYWFAR_UDIR/bin:$ENCHANT_UDIR/bin:$GNOME_UDIR/bin:$GNUCASH_UDIR/bin:$GNUCASH_UDIR/lib:$GNUTLS_UDIR/bin:$GOFFICE_UDIR/bin:$GUILE_UDIR/bin:$LIBDBI_UDIR/bin:$LIBGSF_UDIR/bin:$LIBOFX_UDIR/bin:$LIBSOUP_UDIR/bin:$LIBXSLT_UDIR/bin:$MYSQL_UDIR/bin:$MYSQL_UDIR/lib:$NINJA_UDIR:$OPENSP_UDIR/bin:$PCRE_UDIR/bin:$PGSQL_UDIR/bin:$PGSQL_UDIR/lib:$REGEX_UDIR/bin:$SQLITE3_UDIR/bin:$SWIG_UDIR:$WEBKIT_UDIR/bin:$BOOST_UDIR/lib

PATH=$PATH:$OLDPATH

export PATH

export LTDL_LIBRARY_PATH=$GNUCASH_UDIR/lib
export GNOME2_PATH=$GNOME_UDIR
export ACLOCAL_FLAGS="-I $GNOME_UDIR/share/aclocal -I $GUILE_UDIR/share/aclocal"

export PKG_CONFIG_PATH="$AQBANKING_UDIR/lib/pkgconfig:$ENCHANT_UDIR/lib/pkgconfig:$GOFFICE_UDIR/lib/pkgconfig:$GNOME_UDIR/lib/pkgconfig:$GNUTLS_UDIR/lib/pkgconfig:$GUILE_UDIR/lib/pkgconfig:$GWENHYWFAR_UDIR/lib/pkgconfig:$GLOBAL_UDIR/isocodes/share/pkgconfig:$LIBGSF_UDIR/lib/pkgconfig:$LIBOFX_UDIR/lib/pkgconfig:$LIBSOUP_UDIR/lib/pkgconfig:$LIBXSLT_UDIR/lib/pkgconfig:$PCRE_UDIR/lib/pkgconfig:$WEBKIT_UDIR/lib/pkgconfig"

export CPPFLAGS="-I$AQBANKING_UDIR/include -I$ENCHANT_UDIR/include -I$GOFFICE_UDIR/include -I$GNOME_UDIR/include -I$GNOME_UDIR/include/glib-2.0 -I$GNOME_UDIR/lib/glib-2.0/include -I$GNUTLS_UDIR/include -I$GUILE_UDIR/include -I$GWENHYWFAR_UDIR/include -I$GLOBAL_UDIR/isocodes/include -I$LIBGSF_UDIR/include -I$LIBOFX_UDIR/include -I$LIBSOUP_UDIR/include -I$LIBXSLT_UDIR/include -I$PCRE_UDIR/include -I$WEBKIT_UDIR/pkgconfig -I$LIBDBI_UDIR/include -D__USE_MINGW_ANSI_STDIO"

export LDFLAGS="-L$AQBANKING_UDIR/lib -L$ENCHANT_UDIR/lib -L$GOFFICE_UDIR/lib -L$GNOME_UDIR/lib -L$GNUTLS_UDIR/lib -L$GUILE_UDIR/lib -L$GWENHYWFAR_UDIR/lib -L$GLOBAL_UDIR/isocodes/lib  -L$LIBGSF_UDIR/lib -L$LIBOFX_UDIR/lib -L$LIBSOUP_UDIR/lib -L$LIBXSLT_UDIR/lib -L$PCRE_UDIR/lib -L$WEBKIT_UDIR/lib -L$LIBDBI_UDIR/lib -L$GLOBAL_UDIR/hh/lib -L$REGEX_UDIR/lib -L$BOOST_UDIR/lib"

export GIT_CMD=$GLOBAL_UDIR/git/git.exe
