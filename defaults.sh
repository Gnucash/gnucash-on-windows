#!/bin/sh # for emacs
#
# Don't edit this file directly. Edit `custom.sh' in the same directory
# instead. That will be read in at the beginning of this script.
#
# You can use the full power of bash 2.04 scripting.  In particular, you can
# set any variable mentioned here to something non-empty and it will not be
# overridden later.  However, you must define all variables you make use of
# yourself.  Expressions registered with late_eval are executed at the end of
# the script.
#
# Note: All directories must be without spaces!
#

[ "$__SOURCED_DEFAULTS" ] && return
__SOURCED_DEFAULTS=1

[ -f "./custom.sh" ] && . ./custom.sh || true

set_default GLOBAL_DIR c:\\gcdev
set_default TMP_DIR $GLOBAL_DIR\\tmp
set_default DOWNLOAD_DIR $GLOBAL_DIR\\downloads

if [ -z "$BUILD_FROM_TARBALL" ]; then
    if [ -f "../../src/swig-runtime.h" ]; then
        BUILD_FROM_TARBALL=yes
    else
        BUILD_FROM_TARBALL=no
    fi
fi

set_default GC_WIN_REPOS_DIR $GLOBAL_DIR\\gnucash-on-windows.git
set_default REPOS_DIR $GLOBAL_DIR\\gnucash.git
if [ "$BUILD_FROM_TARBALL" = "yes" ]; then
    set_default GNUCASH_DIR $REPOS_DIR
    # keep this pointing from BUILD_DIR to REPOS_DIR
    set_default REL_REPOS_DIR ..
else
    set_default GNUCASH_DIR $GLOBAL_DIR\\gnucash
    # keep this pointing from BUILD_DIR to REPOS_DIR
    set_default REL_REPOS_DIR ..\\..\\gnucash.git

    set_default REPOS_TYPE "git"
    if [ "$REPOS_TYPE" = "git" ]; then
      set_default GNUCASH_SCM_REV "master"
      set_default REPOS_URL "git://github.com/Gnucash/gnucash.git"
    fi
fi
set_default BUILD_DIR $GNUCASH_DIR\\build
set_default INSTALL_DIR $GNUCASH_DIR\\inst
set_default DIST_DIR $GNUCASH_DIR\\dist

set_default WITH_CUTECASH no
set_default CUTECASH_BUILD_DIR $GNUCASH_DIR\\build-cutecash


####
# For cross-compiling, change this to "yes"
set_default CROSS_COMPILE "no"

# If "yes", build without optimizations (-O0) and ease debugging
set_default DISABLE_OPTIMIZATIONS no

set_default MINGW_DIR $GLOBAL_DIR\\mingw
set_default MSYS_DIR $MINGW_DIR\\msys

# tools here means binaries runnable without other DLLs or data files
set_default TOOLS_DIR $GLOBAL_DIR\\tools
set_default MSYS_BISON_VERSION "2.4.2-1"
set_default MSYS_FLEX_VERSION  "2.5.35-2"
set_default MSYS_M4_VERSION    "1.4.16-2"
set_default MSYS_PATCH_VERSION "2.6.1-1"
set_default MSYS_PERL_VERSION  "5.8.8-1"
set_default MSYS_UNZIP_VERSION "6.0-1"
set_default MSYS_WGET_VERSION  "1.12-1"

set_default SF_MIRROR "http://downloads.sf.net"
set_default GTK_MIRROR "ftp.gtk.org/pub"
set_default GNOME_MIRROR "ftp.gnome.org/pub/gnome"
set_default GNOME_WIN32_URL "$GNOME_MIRROR/binaries/win32"
set_default GNOME_WIN32_DEPS_URL "$GNOME_WIN32_URL/dependencies"
set_default GC_DEPS_URL "$SF_MIRROR/gnucash/Dependencies"


# Mingw toolchain

set_default MINGW_AUTOCONF_VERSION    "10-1"
set_default MINGW_AUTOCONF21_VERSION  "2.13-4"
set_default MINGW_AUTOCONF25_VERSION  "2.68-1"
set_default MINGW_AUTOMAKE111_VERSION "1.11.1-1"
set_default MINGW_AUTOMAKE110_VERSION "1.10.2-1"
set_default MINGW_AUTOMAKE19_VERSION  "1.9.6-3"
set_default MINGW_AUTOMAKE18_VERSION  "1.8.5-1"
set_default MINGW_AUTOMAKE17_VERSION  "1.7.9-1"
set_default MINGW_AUTOMAKE16_VERSION  "1.6.3-1"
set_default MINGW_AUTOMAKE15_VERSION  "1.5-1"
set_default MINGW_AUTOMAKE14_VERSION  "1.4p6-1"
set_default MINGW_AUTOMAKE_VERSION    "4-1"
set_default MINGW_BINUTILS_VERSION    "2.23.1-1"
set_default MINGW_BINUTILS_VERSION    "2.23.1-1"
set_default MINGW_GCC_VERSION         "4.8.1-3"
set_default MINGW_GETTEXT_VERSION     "0.18.1.1-2"
set_default MINGW_GMP_VERSION         "5.1.2-1"
set_default MINGW_LIBEXPAT_VERSION    "2.1.0-1"
set_default MINGW_LIBICONV_VERSION    "1.14-2"
set_default MINGW_LIBLTDL_VERSION     "2.4-1"
set_default MINGW_LIBTOOL_VERSION     "2.4-1"
set_default MINGW_MPC_VERSION         "1.0.1-2"
set_default MINGW_MPFR_VERSION        "3.1.2-2"
set_default MINGW_PEXPORTS_VERSION    "0.46"
set_default MINGW_PTHREAD_W32_VERSION "2.9.1-1"
set_default MINGW_RT_VERSION          "3.20-2"
set_default MINGW_ZLIB_VERSION        "1.2.8-1"
set_default MINGW_W32API_VERSION      "3.17-2"
set_default MINGW_MAKE_VERSION        "3.82-5"

if [ "$CROSS_COMPILE" != yes ]; then
    # Use native toolchain
    set_default LD ld
    set_default CC gcc
    set_default DLLTOOL dlltool
    set_default RANLIB ranlib

    # For native build on Windows we can use the precompiled binaries
    # defined above

else
    # What flavor of GCC cross-compiler are we building?
    set_default TARGET "mingw32"

    # Insert your cross-compiler mingw32 bin-directories here
    set_default HOST_XCOMPILE "--host=$TARGET"

    # Where does the cross-compiler go?
    # This should be the directory into which your cross-compiler
    # will be installed.  Remember that if you set this to a directory
    # that only root has write access to, you will need to run this
    # script as root.
    set_default PREFIX `unix_path $MINGW_DIR`

    # Use native toolchain
    set_default LD $TARGET-ld
    set_default CC $TARGET-gcc
    set_default DLLTOOL $TARGET-dlltool
    set_default RANLIB $TARGET-ranlib

    # For cross compilation we need to build our own toolchain
    set_default BINUTILS_SRC_URL "$SF_MIRROR/mingw/binutils-2.20.1-src.tar.gz"
    set_default GCC_CORE_SRC_URL "$SF_MIRROR/mingw/gcc-core-3.4.5-20060117-2-src.tar.gz"
    set_default GCC_GPP_SRC_URL "$SF_MIRROR/mingw/gcc-g++-3.4.5-20060117-2-src.tar.gz"
    # Not required for GnuCash
    set_default GCC_G77_SRC_URL "" #"$SF_MIRROR/mingw/gcc-g77-3.4.5-20060117-2-src.tar.gz"
    set_default GCC_OBJC_SRC_URL "" #"$SF_MIRROR/mingw/gcc-objc-3.4.5-20060117-2-src.tar.gz"
    set_default GCC_JAVA_SRC_URL "" #"$SF_MIRROR/mingw/gcc-java-3.4.5-20060117-2-src.tar.gz"
    set_default GCC_ADA_SRC_URL "" #"$SF_MIRROR/mingw/gcc-ada-3.4.5-20060117-2-src.tar.gz"

    # What directory will the cross-compiler be built in?
    # This is the directory into which source archives will
    # be downloaded, expanded, compiled, etc.  You need to
    # have write-access to this directory.  If you leave it
    # blank, it defaults to the current directory.
    set_default XC_BUILD_DIR `unix_path $TMP_DIR`

    # Purge anything and everything already in the $PREFIX
    #(also known as the destination or installation) directory?
    # Set to "yes" to purge, any other value omits the purge step.
    set_default PURGE_DIR "no"

    # If you wish to apply a patch to GCC, put it in the SRC_DIR
    # and add its filename here.
    set_default GCC_PATCH ""

    # These are the files from the SDL website
    # These are optional, set them to "" if you don't want them
    set_default SDL_URL "" #http://www.libsdl.org/extras/win32/common"
    set_default OPENGL_URL "" #"$SDL_URL/opengl-devel.tar.gz"
    set_default DIRECTX_URL "" #$SDL_URL/directx-devel.tar.gz"
fi

set_default CROSS_GCC_SRC_URL "$SF_MIRROR/mingw/gcc-4.4.0-src.tar.bz2"
set_default CROSS_GCC_SRC2_URL "$SF_MIRROR/mingw/gcc-4.4.0-mingw32-src-2.tar.gz"
#set_default CROSS_GCC_SRC_URL "$SF_MIRROR/mingw/gcc-4.5.0-1-mingw32-src.tar.lzma"
set_default CROSS_BINUTILS_SRC_URL "$SF_MIRROR/mingw/binutils-2.20.1-src.tar.gz"

# do not use regex-gnu or regex-spencer v3.8.g3, see bug #382852
set_default REGEX_URL "$GNOME_WIN32_DEPS_URL/libgnurx-2.5.zip"
set_default REGEX_DEV_URL "$GNOME_WIN32_DEPS_URL/libgnurx-dev-2.5.zip"
set_default REGEX_DIR $GLOBAL_DIR\\regex

set_default READLINE_BIN_URL "$SF_MIRROR/gnuwin32/readline-5.0-1-bin.zip"
set_default READLINE_LIB_URL "$SF_MIRROR/gnuwin32/readline-5.0-1-lib.zip"
set_default READLINE_DIR $GLOBAL_DIR\\readline

set_default GMP_URL "ftp://ftp.gnu.org/gnu/gmp/gmp-4.3.1.tar.bz2"
set_default GMP_ABI 32
set_default GMP_DIR $GLOBAL_DIR\\gmp
set_default GMP5_BIN_URL "$SF_MIRROR/mingw/libgmp-5.0.1-1-mingw32-dll-10.tar.lzma"
set_default GMP5_DEV_URL "$SF_MIRROR/mingw/gmp-5.0.1-1-mingw32-dev.tar.lzma"

GUILE_VERSION="1.8.8"
set_default GUILE_URL "http://ftp.gnu.org/pub/gnu/guile/guile-${GUILE_VERSION}.tar.gz"
set_default GUILE_DIR $GLOBAL_DIR\\guile
set_default GUILE_PATCH `pwd`/guile-1.8.patch

set_default OPENSSL_URL "http://www.openssl.org/source/openssl-0.9.8j.tar.gz"
set_default OPENSSL_DIR $GLOBAL_DIR\\openssl

GLIB_VERSION="2.38.2"
GNUTLS_VERSION="3.2.19"
set_default BUILD_GNUTLS_FROM_SOURCE "no"
set_default GNUTLS_URL  "$GC_DEPS_URL/gnutls-3.2.19-minGW.tgz"
set_default GNUTLS_DEV_URL  "$GC_DEPS_URL/gnutls-3.2.19-dev-minGW.tgz"
set_default GNUTLS_PKG_URL "ftp://ftp.gnutls.org/gcrypt/gnutls/w32/gnutls-${GNUTLS_VERSION}-w32.zip"
GCRYPT_VERSION="1.6.2"
set_default GCRYPT_SRC_URL "ftp://ftp.gnutls.org/gcrypt/libgcrypt/libgcrypt-${GCRYPT_VERSION}.tar.bz2"
GPG_ERROR_VERSION="1.17"
set_default GPG_ERROR_SRC_URL "ftp://ftp.gnutls.org/gcrypt/libgpg-error/libgpg-error-${GPG_ERROR_VERSION}.tar.bz2"
set_default GLIB_NETWORKING_SRC_URL "$GNOME_MIRROR/sources/glib-networking/2.38/glib-networking-${GLIB_VERSION}.tar.xz"
set_default GNUTLS_DIR $GLOBAL_DIR\\gnutls

set_default MINGW_UTILS_URL "$SF_MIRROR/mingw/mingw-utils-0.3.tar.gz"
set_default MINGW_UTILS_DIR $TOOLS_DIR

set_default EXETYPE_SCRIPT `pwd`/exetype.pl
set_default EXETYPE_DIR $TOOLS_DIR

XMLSOFT_URL="http://xmlsoft.org/sources/win32"
#XSLT_BASE_URL="http://ftp.acc.umu.se/pub/GNOME/sources/libxslt/1.1"
XML2_BASE_URL="ftp://xmlsoft.org/libxml2"
LIBXSLT_VERSION="1.1.28"
#LIBXSLT_VERSION=1.1.26
set_default LIBXSLT_SRC_URL "${XML2_BASE_URL}/libxslt-${LIBXSLT_VERSION}.tar.gz"
#set_default LIBXSLT_MAKEFILE_PATCH "`pwd`/libxslt-1.1.22.Makefile.in.patch"
LIBXML2_VERSION="2.9.0"
set_default LIBXML2_SRC_URL "${XML2_BASE_URL}/libxml2-${LIBXML2_VERSION}.tar.gz"
set_default LIBXSLT_ICONV_URL "${XMLSOFT_URL}/iconv-1.9.2.win32.zip"
set_default LIBXSLT_ZLIB_URL "${XMLSOFT_URL}/zlib-1.2.3.win32.zip"
set_default LIBXSLT_DIR $GLOBAL_DIR\\libxslt

set_default EXPAT_URL               "$GNOME_WIN32_DEPS_URL/expat_2.0.1-1_win32.zip"
set_default EXPAT_DEV_URL           "$GNOME_WIN32_DEPS_URL/expat-dev_2.0.1-1_win32.zip"
set_default FREETYPE_URL            "$GNOME_WIN32_DEPS_URL/freetype_2.4.4-1_win32.zip"
set_default FREETYPE_DEV_URL        "$GNOME_WIN32_DEPS_URL/freetype-dev_2.4.4-1_win32.zip"
set_default GAIL_URL                "$GNOME_WIN32_URL/gail/1.22/gail-1.22.0.zip"
set_default GAIL_DEV_URL            "$GNOME_WIN32_URL/gail/1.22/gail-dev-1.22.0.zip"
set_default GETTEXT_RUNTIME_URL     "$GNOME_WIN32_DEPS_URL/gettext-runtime_0.18.1.1-2_win32.zip"
set_default GETTEXT_RUNTIME_DEV_URL "$GNOME_WIN32_DEPS_URL/gettext-runtime-dev_0.18.1.1-2_win32.zip"
set_default GETTEXT_TOOLS_URL       "$GNOME_WIN32_DEPS_URL/gettext-tools-dev_0.18.1.1-2_win32.zip"
set_default GTK_DOC_URL             "$GNOME_MIRROR/sources/gtk-doc/1.13/gtk-doc-1.13.tar.bz2"
set_default GTK_PREFS_URL           "$SF_MIRROR/gtk-win/gtk2_prefs-0.4.1.bin-gtk2.10-win32.zip"
set_default GTK_THEME_URL           "$SF_MIRROR/gtk-win/gtk2-themes-2009-09-07-win32_bin.zip"
set_default INTLTOOL_URL            "$GNOME_WIN32_URL/intltool/0.40/intltool_0.40.4-1_win32.zip"
set_default LIBART_LGPL_URL         "$GNOME_WIN32_URL/libart_lgpl/2.3/libart-lgpl_2.3.21-1_win32.zip"
set_default LIBART_LGPL_DEV_URL     "$GNOME_WIN32_URL/libart_lgpl/2.3/libart-lgpl-dev_2.3.21-1_win32.zip"
set_default LIBGNOMECANVAS_URL      "$GNOME_WIN32_URL/libgnomecanvas/2.30/libgnomecanvas_2.30.1-1_win32.zip"
set_default LIBGNOMECANVAS_DEV_URL  "$GNOME_WIN32_URL/libgnomecanvas/2.30/libgnomecanvas-dev_2.30.1-1_win32.zip"
set_default LIBICONV_URL            "$GNOME_WIN32_DEPS_URL/libiconv-1.9.1.bin.woe32.zip"
set_default LIBPNG_URL              "$GNOME_WIN32_DEPS_URL/libpng_1.4.3-1_win32.zip"
set_default LIBPNG_DEV_URL          "$GNOME_WIN32_DEPS_URL/libpng-dev_1.4.3-1_win32.zip"
set_default LIBTIFF_URL             "$GC_DEPS_URL/tiff-4.0.3-mingw.tgz"
set_default LIBTIFF_DEV_URL         "$GC_DEPS_URL/tiff-4.0.3-dev-mingw.tgz"
set_default LIBXML2_URL             "$GNOME_WIN32_DEPS_URL/libxml2_2.7.7-1_win32.zip"
set_default LIBXML2_DEV_URL         "$GNOME_WIN32_DEPS_URL/libxml2-dev_2.7.7-1_win32.zip"
set_default PKG_CONFIG_URL          "$GNOME_WIN32_DEPS_URL/pkg-config_0.25-1_win32.zip"
set_default PKG_CONFIG_DEV_URL      "$GNOME_WIN32_DEPS_URL/pkg-config-dev_0.25-1_win32.zip"
set_default GLIB_URL                "$GC_DEPS_URL/glib-$GLIB_VERSION-minGW.tgz"
set_default GLIB_DEV_URL            "$GC_DEPS_URL/glib-$GLIB_VERSION-dev-minGW.tgz"
set_default CAIRO_VERSION="1.10.2"
set_default CAIRO_URL               "$GC_DEPS_URL/cairo-1.10.2-minGW.tgz"
set_default CAIRO_DEV_URL           "$GC_DEPS_URL/cairo-1.10.2-dev-minGW.tgz"
set_default GTK_VERSION="2.24.24"
set_default GTK_URL                 "$GC_DEPS_URL/gtk+-2.24.24-minGW.tgz"
set_default GTK_DEV_URL             "$GC_DEPS_URL/gtk+-2.24.24-dev-minGW.tgz"
set_default ZLIB_URL                "$GNOME_WIN32_DEPS_URL/zlib_1.2.5-2_win32.zip"
set_default ZLIB_DEV_URL            "$GNOME_WIN32_DEPS_URL/zlib-dev_1.2.5-2_win32.zip"

set_default GNOME_DIR $GLOBAL_DIR\\gnome

set_default SWIG_URL "$SF_MIRROR/swig/swigwin-2.0.11.zip"
set_default SWIG_DIR $GLOBAL_DIR\\swig

set_default PCRE_BIN_URL "$SF_MIRROR/gnuwin32/pcre-7.0-bin.zip"
set_default PCRE_LIB_URL "$SF_MIRROR/gnuwin32/pcre-7.0-lib.zip"
set_default PCRE_DIR $GLOBAL_DIR\\pcre

LIBGSF_VERSION="1.14.21"
set_default LIBGSF_URL "$GNOME_MIRROR/sources/libgsf/1.14/libgsf-${LIBGSF_VERSION}.tar.bz2"
set_default LIBGSF_DIR $GLOBAL_DIR\\libgsf

GOFFICE_VERSION="0.8.17"
set_default GOFFICE_URL "$GNOME_MIRROR/sources/goffice/0.8/goffice-${GOFFICE_VERSION}.tar.bz2"
set_default GOFFICE_DIR $GLOBAL_DIR\\goffice
#set_default GOFFICE_PATCH `pwd`/goffice-x.x.x.patch

set_default GLADE_URL "$GNOME_MIRROR/sources/glade3/3.0/glade3-3.1.2.tar.bz2"
set_default GLADE_DIR $GLOBAL_DIR\\glade

set_default INNO_URL "http://files.jrsoftware.org/is/5/isetup-5.3.9-unicode.exe"
set_default INNO_DIR $GLOBAL_DIR\\inno

set_default HH_URL "http://download.microsoft.com/download/0/a/9/0a939ef6-e31c-430f-a3df-dfae7960d564/htmlhelp.exe"
set_default HH_DIR $GLOBAL_DIR\\hh

set_default BUILD_WEBKIT_FROM_SOURCE no
set_default WEBKIT_VERSION "1.8.3"
set_default WEBKIT_URL "$SF_MIRROR/gnucash/webkit-${WEBKIT_VERSION}-minGW.tgz"
set_default WEBKIT_DEV_URL "$SF_MIRROR/gnucash/webkit-${WEBKIT_VERSION}-dev-minGW.tgz"
set_default WEBKIT_DIR $GLOBAL_DIR\\webkit
#NB: The Fedora project maintains a source version that has been patched for building in a Fedora-MinGW cross-compiler. This isn't quite good enough to build in MinGW itself, but it's a lot closer and less work than starting with a tarball direct from the WebKitGtk project.
set_default WEBKIT_SRC_URL "https://pkgs.fedoraproject.org/repo/pkgs/mingw-webkitgtk/webkit-1.8.3.tar.xz/dcbf9d5e2e6391f857c29a57528b32a6/webkit-1.8.3.tar.xz"
set_default WEBKIT_MINGW_PATCH_1=`pwd`/0001-Fix-various-issues-when-compiling-natively-on-MinGW.patch
set_default WEBKIT_MINGW_PATCH_2=`pwd`/0002-webkit-second-minGW.patch
set_default ENCHANT_VERSION "1.5.0"
set_default ENCHANT_URL "$GNOME_WIN32_URL/dependencies/enchant_${ENCHANT_VERSION}-2_win32.zip"
set_default ENCHANT_DEV_URL "$GNOME_WIN32_URL/dependencies/enchant-dev_${ENCHANT_VERSION}-2_win32.zip"
set_default ENCHANT_DIR $GLOBAL_DIR\\enchant
set_default BUILD_LIBSOUP_FROM_SOURCE no
set_default LIBSOUP_VERSION "2.48.0"
set_default LIBSOUP_URL "$SF_MIRROR/gnucash/libsoup-${LIBSOUP_VERSION}-minGW.tgz"
set_default LIBSOUP_DEV_URL "$SF_MIRROR/gnucash/libsoup-${LIBSOUP_VERSION}-dev-minGW.tgz"
set_default LIBSOUP_DIR $GLOBAL_DIR\\libsoup
set_default LIBSOUP_SRC_URL "$GNOME_MIRROR/sources/libsoup/2.48/libsoup-${LIBSOUP_VERSION}.tar.xz"
set_default LIBSOUP_BAD_SYMBOL_PATCH `pwd`/libsoup-2.48.0-bad-symbol.patch
set_default LIBSOUP_RESERVED_WORD_PATCH `pwd`/libsoup-2.48.0-soup-server-reserved-word.patch
set_default ICU4C_URL "http://download.icu-project.org/files/icu4c/4.4.1/icu4c-4_4_1-Win32-msvc9.zip"
set_default ICU4C_SRC_URL "http://download.icu-project.org/files/icu4c/4.4.1/icu4c-4_4_1-src.tgz"
set_default ICU4C_DIR $GLOBAL_DIR\\icu-mingw32
set_default ICU4C_PATCH `pwd`/icu-crossmingw.patch

set_default GIT_URL "https://github.com/msysgit/msysgit/releases/download/Git-1.9.4-preview20140611/Git-1.9.4-preview20140611.exe"
set_default GIT_DIR $GLOBAL_DIR\\git-1.9.4

# OFX import in gnucash and ofx directconnect support for aqbanking
set_default OPENSP_URL "$SF_MIRROR/openjade/OpenSP-1.5.2.tar.gz"
set_default OPENSP_DIR $GLOBAL_DIR\\opensp
set_default OPENSP_PATCH `pwd`/opensp-1.5.2.patch

LIBOFX_VERSION="0.9.9"
set_default LIBOFX_URL "$SF_MIRROR/libofx/libofx-${LIBOFX_VERSION}.tar.gz"
set_default LIBOFX_DIR $GLOBAL_DIR\\libofx
set_default LIBOFX_PATCH `pwd`/libofx-0.9.8.patch

## online banking: gwenhywfar+aqbanking
GWENHYWFAR_VERSION="4.11.1beta"
set_default GWENHYWFAR_URL "http://www2.aquamaniac.de/sites/download/download.php?package=01&release=75&file=01&dummy=gwenhywfar-${GWENHYWFAR_VERSION}.tar.gz"
set_default GWENHYWFAR_DIR $GLOBAL_DIR\\gwenhywfar

KTOBLZCHECK_VERSION="1.45"
set_default KTOBLZCHECK_URL "$SF_MIRROR/ktoblzcheck/ktoblzcheck-${KTOBLZCHECK_VERSION}.tar.gz"
# ktoblzcheck is being installed into GWENHYWFAR_DIR

AQBANKING_VERSION="5.4.2beta"
set_default AQBANKING_URL "http://www2.aquamaniac.de/sites/download/download.php?package=03&release=114&file=01&dummy=aqbanking-${AQBANKING_VERSION}.tar.gz"
set_default AQBANKING_DIR $GLOBAL_DIR\\aqbanking

set_default SQLITE3_URL "http://sqlite.org/sqlite-amalgamation-3.6.1.tar.gz"
set_default SQLITE3_DIR $GLOBAL_DIR\\sqlite3
set_default MYSQL_LIB_URL "http://mirror.csclub.uwaterloo.ca/mysql/Downloads/Connector-C/mysql-connector-c-noinstall-6.0.1-win32.zip"
set_default MYSQL_LIB_DIR $GLOBAL_DIR\\mysql
set_default LIBMYSQL_DEF `pwd`/libmysql.def
set_default PGSQL_LIB_URL "$SF_MIRROR/gnucash/pgsql-win32-2.tar.gz"
set_default PGSQL_DIR $GLOBAL_DIR\\pgsql
set_default LIBDBI_URL "$SF_MIRROR/libdbi/libdbi-0.8.4.tar.gz"
set_default LIBDBI_DIR $GLOBAL_DIR\\libdbi
set_default LIBDBI_PATCH `pwd`/libdbi-0.8.3.patch
set_default LIBDBI_DRIVERS_URL "$SF_MIRROR/libdbi-drivers/libdbi-drivers-0.8.3-1.tar.gz"
set_default LIBDBI_DRIVERS_DIR $GLOBAL_DIR\\libdbi-drivers
set_default LIBDBI_DRIVERS_PATCH `pwd`/libdbi-drivers-errno.patch

set_default CMAKE_URL "http://www.cmake.org/files/v2.8/cmake-2.8.0-win32-x86.zip"
set_default CMAKE_DIR $GLOBAL_DIR\\cmake

set_default DOCBOOK_XSL_URL "$SF_MIRROR/docbook/docbook-xsl-1.76.1.zip"
set_default DOCBOOK_DTD_URL "http://www.oasis-open.org/docbook/xml/4.1.2/docbkx412.zip"
if [ "$REPOS_TYPE" = "git" ]; then
  set_default DOCS_SCM_REV "master"
  set_default DOCS_URL "git://github.com/Gnucash/gnucash-docs.git"
fi
set_default UPDATE_DOCS yes
set_default DOCS_DIR $GLOBAL_DIR\\gnucash-docs
set_default XSLTPROCFLAGS ""

set_default ISOCODES_URL "http://pkg-isocodes.alioth.debian.org/downloads/iso-codes-3.49.tar.xz"
set_default ISOCODES_DIR $GLOBAL_DIR\\isocodes

set_default BOOST_URL "$SF_MIRROR/boost/boost/boost_1_55_0.tar.bz2"
set_default BOOST_DIR $GLOBAL_DIR\\boost

### Local Variables: ***
### sh-basic-offset: 4 ***
### indent-tabs-mode: nil ***
### End: ***
