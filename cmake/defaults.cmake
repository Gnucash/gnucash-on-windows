# Note: All directories must be without spaces!
#

set (GLOBAL_DIR c:/gcdev)
set (GLOBAL_BUILD_DIR c:/gcdev)
set (GLOBAL_DEP_BUILD_DIR ${GLOBAL_DIR}/dependencies)
set (TMP_DIR ${GLOBAL_DIR}/tmp)
set (DOWNLOAD_DIR ${GLOBAL_DIR}/downloads)

if ($ENV{BUILD_FROM_TARBALL})
    if (-f "../../src/swig-runtime.h")
        set (BUILD_FROM_TARBALL yes)
    else()
        set (BUILD_FROM_TARBALL no)
    endif()
endif()

set (GC_WIN_REPOS_DIR ${GLOBAL_DIR}/gnucash-on-windows.git)
set (REPOS_DIR ${GLOBAL_DIR}/gnucash.git)
if (${BUILD_FROM_TARBALL})
    set (GNUCASH_DIR ${REPOS_DIR})
    # keep this pointing from BUILD_DIR to REPOS_DIR
    set (REL_REPOS_DIR ..)
else()
    set (GNUCASH_DIR ${GLOBAL_DIR}/gnucash)
    # keep this pointing from BUILD_DIR to REPOS_DIR
    set (REL_REPOS_DIR ../../gnucash.git)

    set (REPOS_TYPE "git")
    set (GNUCASH_SCM_REV "master")
    set (REPOS_URL "git://github.com/Gnucash/gnucash.git")
endif()
set (BUILD_DIR ${GNUCASH_DIR}/build)
if (${WITH_CMAKE})
    set (BUILD_DIR ${GNUCASH_DIR}/cmake-build)
endif()
set (INSTALL_DIR ${GNUCASH_DIR}/inst)

set (DIST_DIR ${GNUCASH_DIR}/dist)

set (WITH_CUTECASH no)
set (WITH_CMAKE no)
set (WITH_NINJA no)
set (CUTECASH_BUILD_DIR ${GNUCASH_DIR}/build-cutecash)



####
# For cross-compiling, change this to "yes"
set (CROSS_COMPILE "no")

# If "yes", build without optimizations (-O0) and ease debugging
set (DISABLE_OPTIMIZATIONS no)

set (MINGW_DIR ${GLOBAL_DIR}/mingw)
set (MSYS_DIR ${MINGW_DIR}/msys)

# tools here means binaries runnable without other DLLs or data files
set (TOOLS_DIR ${GLOBAL_DIR}/tools)
set (MSYS_BISON_VERSION "2.4.2-1")
set (MSYS_FLEX_VERSION  "2.5.35-2")
set (MSYS_M4_VERSION    "1.4.16-2")
set (MSYS_PATCH_VERSION "2.6.1-1")
set (MSYS_PERL_VERSION  "5.8.8-1")
set (MSYS_UNZIP_VERSION "6.0-1")
set (MSYS_WGET_VERSION  "1.12-1")

set (SF_MIRROR "http://downloads.sf.net")
set (GTK_MIRROR "ftp.gtk.org/pub")
set (GNOME_MIRROR "http://ftp.gnome.org/pub/gnome")
set (FREEDESKTOP_MIRROR "http://www.freedesktop.org/software")
set (GNOME_SRC_MIRROR ${GNOME_MIRROR}/sources)
set (GNOME_WIN32_URL "${GNOME_MIRROR}/binaries/win32")
set (GNOME_WIN32_DEPS_URL "${GNOME_WIN32_URL}/dependencies")
set (GC_DEPS_URL "${SF_MIRROR}/gnucash/Dependencies")


# Mingw toolchain

set (MINGW_AUTOCONF_VERSION    "10-1")
set (MINGW_AUTOCONF21_VERSION  "2.13-4")
set (MINGW_AUTOCONF25_VERSION  "2.68-1")
set (MINGW_AUTOMAKE111_VERSION "1.11.1-1")
set (MINGW_AUTOMAKE110_VERSION "1.10.2-1")
set (MINGW_AUTOMAKE19_VERSION  "1.9.6-3")
set (MINGW_AUTOMAKE18_VERSION  "1.8.5-1")
set (MINGW_AUTOMAKE17_VERSION  "1.7.9-1")
set (MINGW_AUTOMAKE16_VERSION  "1.6.3-1")
set (MINGW_AUTOMAKE15_VERSION  "1.5-1")
set (MINGW_AUTOMAKE14_VERSION  "1.4p6-1")
set (MINGW_AUTOMAKE_VERSION    "4-1")
set (MINGW_BINUTILS_VERSION    "2.23.1-1")
set (MINGW_BINUTILS_VERSION    "2.23.1-1")
set (MINGW_GCC_VERSION         "4.8.1-3")
set (MINGW_GETTEXT_VERSION     "0.18.1.1-2")
set (MINGW_GMP_VERSION         "5.1.2-1")
set (MINGW_LIBEXPAT_VERSION    "2.1.0-1")
set (MINGW_LIBICONV_VERSION    "1.14-2")
set (MINGW_LIBLTDL_VERSION     "2.4-1")
set (MINGW_LIBTOOL_VERSION     "2.4-1")
set (MINGW_MPC_VERSION         "1.0.1-2")
set (MINGW_MPFR_VERSION        "3.1.2-2")
set (MINGW_PEXPORTS_VERSION    "0.46")
set (MINGW_PTHREAD_W32_VERSION "2.9.1-1")
set (MINGW_RT_VERSION          "3.21")
set (MINGW_ZLIB_VERSION        "1.2.8-1")
set (MINGW_W32API_VERSION      "3.17-2")
set (MINGW_MAKE_VERSION        "3.82-5")

if (${CROSS_COMPILE})
    # Use native toolchain
    set (LD ld)
    set (CC gcc)
    set (DLLTOOL dlltool)
    set (RANLIB ranlib)

    # For native build on Windows we can use the precompiled binaries
    # defined above

else()
    # What flavor of GCC cross-compiler are we building?
    set (TARGET "mingw32")

    # Insert your cross-compiler mingw32 bin-directories here
    set (HOST_XCOMPILE "--host=${TARGET}")

    # Where does the cross-compiler go?
    # This should be the directory into which your cross-compiler
    # will be installed.  Remember that if you set this to a directory
    # that only root has write access to, you will need to run this
    # script as root.
    set (PREFIX `unix_path ${MINGW_DIR}`)

    # Use native toolchain
    set (LD ${TARGET}-ld)
    set (CC ${TARGET}-gcc)
    set (DLLTOOL ${TARGET}-dlltool)
    set (RANLIB ${TARGET}-ranlib)

    # For cross compilation we need to build our own toolchain
    set (BINUTILS_SRC_URL "${SF_MIRROR}/mingw/binutils-2.20.1-src.tar.gz")
    set (GCC_CORE_SRC_URL "${SF_MIRROR}/mingw/gcc-core-3.4.5-20060117-2-src.tar.gz")
    set (GCC_GPP_SRC_URL "${SF_MIRROR}/mingw/gcc-g++-3.4.5-20060117-2-src.tar.gz")
    # Not required for GnuCash
    #set (GCC_G77_SRC_URL "${SF_MIRROR}/mingw/gcc-g77-3.4.5-20060117-2-src.tar.gz")
    #set (GCC_OBJC_SRC_URL "${SF_MIRROR}/mingw/gcc-objc-3.4.5-20060117-2-src.tar.gz")
    #set (GCC_JAVA_SRC_URL "${SF_MIRROR}/mingw/gcc-java-3.4.5-20060117-2-src.tar.gz")
    #set (GCC_ADA_SRC_URL "${SF_MIRROR}/mingw/gcc-ada-3.4.5-20060117-2-src.tar.gz")

    # What directory will the cross-compiler be built in?
    # This is the directory into which source archives will
    # be downloaded, expanded, compiled, etc.  You need to
    # have write-access to this directory.  If you leave it
    # blank, it defaults to the current directory.
    set (XC_BUILD_DIR `unix_path ${TMP_DIR}`)

    # Purge anything and everything already in the ${PREFIX}
    #(also known as the destination or installation) directory?
    # Set to "yes" to purge, any other value omits the purge step.
    set (PURGE_DIR "no")

    # If you wish to apply a patch to GCC, put it in the SRC_DIR
    # and add its filename here.
    set (GCC_PATCH "")

    # These are the files from the SDL website
    # These are optional, set them to "" if you don't want them
    #set (SDL_URL "http://www.libsdl.org/extras/win32/common")
    #set (OPENGL_URL "${SDL_URL}/opengl-devel.tar.gz")
    #set (DIRECTX_URL "${SDL_URL}/directx-devel.tar.gz")
endif()

set (CROSS_GCC_SRC_URL "${SF_MIRROR}/mingw/gcc-4.4.0-src.tar.bz2")
set (CROSS_GCC_SRC2_URL "${SF_MIRROR}/mingw/gcc-4.4.0-mingw32-src-2.tar.gz")
#set (CROSS_GCC_SRC_URL "${SF_MIRROR}/mingw/gcc-4.5.0-1-mingw32-src.tar.lzma")
set (CROSS_BINUTILS_SRC_URL "${SF_MIRROR}/mingw/binutils-2.20.1-src.tar.gz")

# do not use regex-gnu or regex-spencer v3.8.g3, see bug #382852
set (REGEX_URL "${GNOME_WIN32_DEPS_URL}/libgnurx-2.5.zip")
set (REGEX_DEV_URL "${GNOME_WIN32_DEPS_URL}/libgnurx-dev-2.5.zip")
set (REGEX_DIR ${GLOBAL_DIR}/regex)

set (READLINE_BIN_URL "${SF_MIRROR}/gnuwin32/readline-5.0-1-bin.zip")
set (READLINE_LIB_URL "${SF_MIRROR}/gnuwin32/readline-5.0-1-lib.zip")
set (READLINE_DIR ${GLOBAL_DIR}/readline)

set (GMP_URL "ftp://ftp.gnu.org/gnu/gmp/gmp-4.3.1.tar.bz2")
set (GMP_ABI 32)
set (GMP_DIR ${GLOBAL_DIR}/gmp)
set (GMP5_BIN_URL "${SF_MIRROR}/mingw/libgmp-5.0.1-1-mingw32-dll-10.tar.lzma")
set (GMP5_DEV_URL "${SF_MIRROR}/mingw/gmp-5.0.1-1-mingw32-dev.tar.lzma")

SET (GUILE_VERSION "1.8.8")
set (GUILE_URL "http://ftp.gnu.org/pub/gnu/guile/guile-${GUILE_VERSION}.tar.gz")
set (GUILE_DIR ${GLOBAL_DIR}/guile)
set (GUILE_PATCH ${CMAKE_SOURCE_DIR}/guile-1.8.patch)

set (OPENSSL_URL "http://www.openssl.org/source/openssl-0.9.8j.tar.gz")
set (OPENSSL_DIR ${GLOBAL_DIR}/openssl)

SET (ZLIB_VERSION "1.2.8")
SET (ZLIB_SRC_URL ${SF_MIRROR}/libpng/zlib-${ZLIB_VERSION}.tar.xz)
# This is the last version of GLib that supports Windows XP.
SET (GLIB_MINOR_VERSION "2.42")
SET (GLIB_MICRO_VERSION "2")
set (GLIB_VERSION ${GLIB_MINOR_VERSION}.${GLIB_MICRO_VERSION})
SET (GLIB_SRC_URL ${GNOME_SRC_MIRROR}/glib/${GLIB_MINOR_VERSION}/glib-${GLIB_VERSION}.tar.xz)
SET (GNUTLS_VERSION "3.2.19")
set (BUILD_GNUTLS_FROM_SOURCE "no")
set (GNUTLS_URL  "${GC_DEPS_URL}/gnutls-3.2.19-minGW.tgz")
set (GNUTLS_DEV_URL  "${GC_DEPS_URL}/gnutls-3.2.19-dev-minGW.tgz")
set (GNUTLS_PKG_URL "ftp://ftp.gnutls.org/gcrypt/gnutls/w32/gnutls-${GNUTLS_VERSION}-w32.zip")
SET (GCRYPT_VERSION "1.6.2")
set (GCRYPT_SRC_URL "ftp://ftp.gnutls.org/gcrypt/libgcrypt/libgcrypt-${GCRYPT_VERSION}.tar.bz2")
SET (GPG_ERROR_VERSION "1.17")
set (GPG_ERROR_SRC_URL "ftp://ftp.gnutls.org/gcrypt/libgpg-error/libgpg-error-${GPG_ERROR_VERSION}.tar.bz2")
set (GLIB_NETWORKING_SRC_URL "${GNOME_MIRROR}/sources/glib-networking/2.38/glib-networking-${GLIB_VERSION}.tar.xz")
set (GNUTLS_DIR ${GLOBAL_DIR}/gnutls)

set (MINGW_UTILS_URL "${SF_MIRROR}/mingw/mingw-utils-0.3.tar.gz")
set (MINGW_UTILS_DIR ${TOOLS_DIR})

set (EXETYPE_SCRIPT ${CMAKE_SOURCE_DIR}/exetype.pl)
set (EXETYPE_DIR ${TOOLS_DIR})

set (XMLSOFT_URL "http://xmlsoft.org/sources/win32")
set (XSLT_BASE_URL "http://ftp.acc.umu.se/pub/GNOME/sources/libxslt/1.1")
set (XML2_BASE_URL "ftp://xmlsoft.org/libxml2")
SET (LIBXSLT_VERSION "1.1.28")
set (LIBXSLT_SRC_URL "${XML2_BASE_URL}/libxslt-${LIBXSLT_VERSION}.tar.gz")
#set (LIBXSLT_MAKEFILE_PATCH "${CMAKE_SOURCE_DIR}/libxslt-1.1.22.Makefile.in.patch")
SET (LIBXML2_VERSION "2.9.0")
set (LIBXML2_SRC_URL "${XML2_BASE_URL}/libxml2-${LIBXML2_VERSION}.tar.gz")
set (LIBXSLT_ICONV_URL "${XMLSOFT_URL}/iconv-1.9.2.win32.zip")
set (LIBXSLT_ZLIB_URL "${XMLSOFT_URL}/zlib-1.2.3.win32.zip")
set (LIBXSLT_DIR ${GLOBAL_DIR}/libxslt)

set (EXPAT_URL               "${GNOME_WIN32_DEPS_URL}/expat_2.0.1-1_win32.zip")
set (EXPAT_DEV_URL           "${GNOME_WIN32_DEPS_URL}/expat-dev_2.0.1-1_win32.zip")
set (FREETYPE_VERSION "2.6.4")
set (FREETYPE_URL "${SF_MIRROR}/freetype/freetype-${FREETYPE_VERSION}.tar.bz2")
set (FONTCONFIG_VERSION "2.12.0")
set (FONTCONFIG_URL ${FREEDESKTOP_MIRROR}/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.bz2)
set (HARFBUZZ_VERSION "1.2.7")
set (HARFBUZZ_URL ${FREEDESKTOP_MIRROR}/harfbuzz/release/harfbuzz-${HARFBUZZ_VERSION}.tar.bz2)
set (GAIL_URL                "${GNOME_WIN32_URL}/gail/1.22/gail-1.22.0.zip")
set (GAIL_DEV_URL            "${GNOME_WIN32_URL}/gail/1.22/gail-dev-1.22.0.zip")
set (GETTEXT_RUNTIME_URL     "${GNOME_WIN32_DEPS_URL}/gettext-runtime_0.18.1.1-2_win32.zip")
set (GETTEXT_RUNTIME_DEV_URL "${GNOME_WIN32_DEPS_URL}/gettext-runtime-dev_0.18.1.1-2_win32.zip")
set (GETTEXT_TOOLS_URL       "${GNOME_WIN32_DEPS_URL}/gettext-tools-dev_0.18.1.1-2_win32.zip")
set (GTK_DOC_URL             "${GNOME_MIRROR}/sources/gtk-doc/1.13/gtk-doc-1.13.tar.bz2")
set (GTK_PREFS_URL           "${SF_MIRROR}/gtk-win/gtk2_prefs-0.4.1.bin-gtk2.10-win32.zip")
set (GTK_THEME_URL           "${SF_MIRROR}/gtk-win/gtk2-themes-2009-09-07-win32_bin.zip")
set (ICU_VERSION "55.1")
set (ICU_USCORE_VERSION "55_1")
set (ICU_URL "http://download.icu-project.org/files/icu4c/${ICU_VERSION}/icu4c-${ICU_USCORE_VERSION}-src.tgz")
set (INTLTOOL_URL            "${GNOME_WIN32_URL}/intltool/0.40/intltool_0.40.4-1_win32.zip")
set (LIBFFI_VERSION "3.2.1")
set (LIBFFI_URL "ftp://sourceware.org/pub/libffi/libffi-${LIBFFI_VERSION}.tar.gz")
set (LIBART_LGPL_URL         "${GNOME_WIN32_URL}/libart_lgpl/2.3/libart-lgpl_2.3.21-1_win32.zip")
set (LIBART_LGPL_DEV_URL     "${GNOME_WIN32_URL}/libart_lgpl/2.3/libart-lgpl-dev_2.3.21-1_win32.zip")
set (LIBICONV_URL            "${GNOME_WIN32_DEPS_URL}/libiconv-1.9.1.bin.woe32.zip")
set (LIBPNG_URL              "${GNOME_WIN32_DEPS_URL}/libpng_1.4.3-1_win32.zip")
set (LIBPNG_DEV_URL          "${GNOME_WIN32_DEPS_URL}/libpng-dev_1.4.3-1_win32.zip")
set (LIBTIFF_URL             "${GC_DEPS_URL}/tiff-4.0.3-mingw.tgz")
set (LIBTIFF_DEV_URL         "${GC_DEPS_URL}/tiff-4.0.3-dev-mingw.tgz")
set (LIBXML2_URL             "${GNOME_WIN32_DEPS_URL}/libxml2_2.7.7-1_win32.zip")
set (LIBXML2_DEV_URL         "${GNOME_WIN32_DEPS_URL}/libxml2-dev_2.7.7-1_win32.zip")
set (PKG_CONFIG_VER "0.29.1")
set (PKG_CONFIG_MIRROR https://pkg-config.freedesktop.org/releases/)
set (PKG_CONFIG_SRC_URL ${PKG_CONFIG_MIRROR}/pkg-config-${PKG_CONFIG_VER}.tar.gz)
set (PKG_CONFIG_URL          "${GNOME_WIN32_DEPS_URL}/pkg-config_0.25-1_win32.zip")
set (PKG_CONFIG_DEV_URL      "${GNOME_WIN32_DEPS_URL}/pkg-config-dev_0.25-1_win32.zip")
set (GLIB_URL                "${GC_DEPS_URL}/glib-${GLIB_VERSION}-2-minGW.tgz")
set (GLIB_DEV_URL            "${GC_DEPS_URL}/glib-${GLIB_VERSION}-2-dev-minGW.tgz")
set (CAIRO_VERSION "1.10.2")
set (CAIRO_URL               "${GC_DEPS_URL}/cairo-1.10.2-minGW.tgz")
set (CAIRO_DEV_URL           "${GC_DEPS_URL}/cairo-1.10.2-dev-minGW.tgz")
set (GTK_VERSION "2.24.24")
set (GTK_URL                 "${GC_DEPS_URL}/gtk+-2.24.24-minGW.tgz")
set (GTK_DEV_URL             "${GC_DEPS_URL}/gtk+-2.24.24-dev-minGW.tgz")
set (ZLIB_URL                "${GNOME_WIN32_DEPS_URL}/zlib_1.2.5-2_win32.zip")
set (ZLIB_DEV_URL            "${GNOME_WIN32_DEPS_URL}/zlib-dev_1.2.5-2_win32.zip")

set (GNOME_DIR ${GLOBAL_DIR}/gnome)

set (SWIG_URL "${SF_MIRROR}/swig/swigwin-2.0.11.zip")
set (SWIG_DIR ${GLOBAL_DIR}/swig)

set (PCRE_BIN_URL "${SF_MIRROR}/gnuwin32/pcre-7.0-bin.zip")
set (PCRE_LIB_URL "${SF_MIRROR}/gnuwin32/pcre-7.0-lib.zip")
set (PCRE_DIR ${GLOBAL_DIR}/pcre)

SET (LIBGSF_VERSION "1.14.21")
set (LIBGSF_URL "${GNOME_MIRROR}/sources/libgsf/1.14/libgsf-${LIBGSF_VERSION}.tar.bz2")
set (LIBGSF_DIR ${GLOBAL_DIR}/libgsf)

SET (GOFFICE_VERSION "0.8.17")
set (GOFFICE_URL "${GNOME_MIRROR}/sources/goffice/0.8/goffice-${GOFFICE_VERSION}.tar.bz2")
set (GOFFICE_DIR ${GLOBAL_DIR}/goffice)
#set (GOFFICE_PATCH ${CMAKE_SOURCE_DIR}/goffice-x.x.x.patch)

set (GLADE_URL "${GNOME_MIRROR}/sources/glade3/3.0/glade3-3.1.2.tar.bz2")
set (GLADE_DIR ${GLOBAL_DIR}/glade)

set (INNO_URL "http://files.jrsoftware.org/is/5/isetup-5.3.9-unicode.exe")
set (INNO_DIR ${GLOBAL_DIR}/inno)

set (HH_URL "http://download.microsoft.com/download/0/a/9/0a939ef6-e31c-430f-a3df-dfae7960d564/htmlhelp.exe")
set (HH_DIR ${GLOBAL_DIR}/hh)

set (BUILD_WEBKIT_FROM_SOURCE no)
set (WEBKIT_VERSION "1.8.3")
set (WEBKIT_URL "${SF_MIRROR}/gnucash/webkit-${WEBKIT_VERSION}-minGW.tgz")
set (WEBKIT_DEV_URL "${SF_MIRROR}/gnucash/webkit-${WEBKIT_VERSION}-dev-minGW.tgz")
set (WEBKIT_DIR ${GLOBAL_DIR}/webkit)
#NB: The Fedora project maintains a source version that has been patched for building in a Fedora-MinGW cross-compiler. This isn't quite good enough to build in MinGW itself, but it's a lot closer and less work than starting with a tarball direct from the WebKitGtk project.
set (WEBKIT_SRC_URL "https://pkgs.fedoraproject.org/repo/pkgs/mingw-webkitgtk/webkit-1.8.3.tar.xz/dcbf9d5e2e6391f857c29a57528b32a6/webkit-1.8.3.tar.xz")
set (WEBKIT_MINGW_PATCH_1 ${CMAKE_SOURCE_DIR}/0001-Fix-various-issues-when-compiling-natively-on-MinGW.patch)
set (WEBKIT_MINGW_PATCH_2 ${CMAKE_SOURCE_DIR}/0002-webkit-second-minGW.patch)
set (ENCHANT_VERSION "1.5.0")
set (ENCHANT_URL "${GNOME_WIN32_URL}/dependencies/enchant_${ENCHANT_VERSION}-2_win32.zip")
set (ENCHANT_DEV_URL "${GNOME_WIN32_URL}/dependencies/enchant-dev_${ENCHANT_VERSION}-2_win32.zip")
set (ENCHANT_DIR ${GLOBAL_DIR}/enchant)
set (BUILD_LIBSOUP_FROM_SOURCE no)
set (LIBSOUP_VERSION "2.48.0")
set (LIBSOUP_URL "${SF_MIRROR}/gnucash/libsoup-${LIBSOUP_VERSION}-minGW.tgz")
set (LIBSOUP_DEV_URL "${SF_MIRROR}/gnucash/libsoup-${LIBSOUP_VERSION}-dev-minGW.tgz")
set (LIBSOUP_DIR ${GLOBAL_DIR}/libsoup)
set (LIBSOUP_SRC_URL "${GNOME_MIRROR}/sources/libsoup/2.48/libsoup-${LIBSOUP_VERSION}.tar.xz")
set (LIBSOUP_BAD_SYMBOL_PATCH ${CMAKE_SOURCE_DIR}/libsoup-2.48.0-bad-symbol.patch)
set (LIBSOUP_RESERVED_WORD_PATCH ${CMAKE_SOURCE_DIR}/libsoup-2.48.0-soup-server-reserved-word.patch)
set (ICU4C_URL "http://download.icu-project.org/files/icu4c/4.4.1/icu4c-4_4_1-Win32-msvc9.zip")
set (ICU4C_SRC_URL "http://download.icu-project.org/files/icu4c/4.4.1/icu4c-4_4_1-src.tgz")
set (ICU4C_DIR ${GLOBAL_DIR}/icu-mingw32)
set (ICU4C_PATCH ${CMAKE_SOURCE_DIR}/icu-crossmingw.patch)

set (GIT_URL "https://github.com/msysgit/msysgit/releases/download/Git-1.9.4-preview20140611/Git-1.9.4-preview20140611.exe")
set (GIT_DIR ${GLOBAL_DIR}/git-1.9.4)

# OFX import in gnucash and ofx directconnect support for aqbanking
set (OPENSP_URL "${SF_MIRROR}/openjade/OpenSP-1.5.2.tar.gz")
set (OPENSP_DIR ${GLOBAL_DIR}/opensp)
set (OPENSP_PATCH ${CMAKE_SOURCE_DIR}/opensp-1.5.2.patch)

SET (LIBOFX_VERSION "0.9.9")
set (LIBOFX_URL "${SF_MIRROR}/libofx/libofx-${LIBOFX_VERSION}.tar.gz")
set (LIBOFX_DIR ${GLOBAL_DIR}/libofx)
set (LIBOFX_PATCH ${CMAKE_SOURCE_DIR}/libofx-0.9.8.patch)

## online banking: gwenhywfar+aqbanking
SET (GWENHYWFAR_VERSION "4.15.3")
## NB: Dummy means dummy! The important value in the following url is
## the release number, not the file name at the end!
set (GWENHYWFAR_URL "http://www2.aquamaniac.de/sites/download/download.php?package=01&release=201&file=01&dummy gwenhywfar-4.15.3.tar.gz")
set (GWENHYWFAR_DIR ${GLOBAL_DIR}/gwenhywfar)

SET (AQBANKING_VERSION "5.6.10")
## NB: Dummy means dummy! The important value in the following url is
## the release number, not the file name at the end!
set (AQBANKING_URL "http://www2.aquamaniac.de/sites/download/download.php?package=03&release=206&file=01&dummy aqbanking-5.6.10.tar.gz")
set (AQBANKING_DIR ${GLOBAL_DIR}/aqbanking)
set (AQB_PATCH ${CMAKE_SOURCE_DIR}/swift940-strndup.patch)

set (SQLITE3_URL "http://sqlite.org/sqlite-amalgamation-3.6.1.tar.gz")
set (SQLITE3_DIR ${GLOBAL_DIR}/sqlite3)
set (MYSQL_LIB_URL "http://mirror.csclub.uwaterloo.ca/mysql/Downloads/Connector-C/mysql-connector-c-noinstall-6.0.1-win32.zip")
set (MYSQL_LIB_DIR ${GLOBAL_DIR}/mysql)
set (LIBMYSQL_DEF ${CMAKE_SOURCE_DIR}/libmysql.def)
set (PGSQL_LIB_URL "${SF_MIRROR}/gnucash/pgsql-win32-2.tar.gz")
set (PGSQL_DIR ${GLOBAL_DIR}/pgsql)
set (LIBDBI_URL "${SF_MIRROR}/libdbi/libdbi-0.8.4.tar.gz")
set (LIBDBI_DIR ${GLOBAL_DIR}/libdbi)
set (LIBDBI_PATCH ${CMAKE_SOURCE_DIR}/libdbi-0.8.3.patch)
set (LIBDBI_DRIVERS_URL "${SF_MIRROR}/libdbi-drivers/libdbi-drivers-0.8.3-1.tar.gz")
set (LIBDBI_DRIVERS_DIR ${GLOBAL_DIR}/libdbi-drivers)
set (LIBDBI_DRIVERS_PATCH ${CMAKE_SOURCE_DIR}/libdbi-drivers-errno.patch)

set (CMAKE_URL "https://cmake.org/files/v3.3/cmake-3.3.2-win32-x86.zip")
set (CMAKE_DIR ${GLOBAL_DIR}/cmake)

set (NINJA_URL "http://github.com/ninja-build/ninja/releases/download/v1.6.0/ninja-win.zip")
set (NINJA_DIR ${GLOBAL_DIR}/ninja)

set (DOCBOOK_XSL_URL "${SF_MIRROR}/docbook/docbook-xsl-1.76.1.zip")
set (DOCBOOK_DTD_URL "http://www.oasis-open.org/docbook/xml/4.1.2/docbkx412.zip")
if (REPOS_TYPE STREQUAL "git")
  set (DOCS_SCM_REV "master")
  set (DOCS_URL "git://github.com/Gnucash/gnucash-docs.git")
endif()
set (UPDATE_DOCS yes)
set (DOCS_DIR ${GLOBAL_DIR}/gnucash-docs)
set (XSLTPROCFLAGS "")

set (ISOCODES_URL "http://pkg-isocodes.alioth.debian.org/downloads/iso-codes-3.49.tar.xz")
set (ISOCODES_DIR ${GLOBAL_DIR}/isocodes)

set (BOOST_URL "${SF_MIRROR}/boost/boost/boost_1_55_0.tar.bz2")
set (BOOST_DIR ${GLOBAL_DIR}/boost)
