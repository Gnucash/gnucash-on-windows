#!/bin/sh
#
# GnuCash shellscript functions for dist.sh
#

function dist_prepare() {
    TMP_UDIR=`unix_path $TMP_DIR`
    if [ -x $DIST_DIR ]; then
        echo "Removing previous DIST_DIR ${DIST_DIR}"
        rm -fr "${DIST_DIR}"
    fi
    _UNZIP_UDIR=`unix_path $UNZIP_DIR`
    _GUILE_UDIR=`unix_path $GUILE_DIR`
    _WIN_UDIR=`unix_path $WINDIR`
    _EXETYPE_UDIR=`unix_path $EXETYPE_DIR`
    _GNOME_UDIR=`unix_path $GNOME_DIR`
    _BOOST_UDIR=`unix_path $BOOST_DIR`
    _PCRE_UDIR=`unix_path $PCRE_DIR`
    _LIBSOUP_UDIR=`unix_path $LIBSOUP_DIR`
    _ENCHANT_UDIR=`unix_path $ENCHANT_DIR`
    _LIBGSF_UDIR=`unix_path $LIBGSF_DIR`
    _GOFFICE_UDIR=`unix_path $GOFFICE_DIR`
    _OPENSP_UDIR=`unix_path $OPENSP_DIR`
    _LIBOFX_UDIR=`unix_path $LIBOFX_DIR`
    _LIBXSLT_UDIR=`unix_path $LIBXSLT_DIR`
    _GNUTLS_UDIR=`unix_path $GNUTLS_DIR`
    _GWENHYWFAR_UDIR=`unix_path $GWENHYWFAR_DIR`
    _AQBANKING_UDIR=`unix_path $AQBANKING_DIR`
    _SQLITE3_UDIR=`unix_path ${SQLITE3_DIR}`
    _MYSQL_LIB_UDIR=`unix_path ${MYSQL_LIB_DIR}`
    _PGSQL_UDIR=`unix_path ${PGSQL_DIR}`
    _LIBDBI_UDIR=`unix_path ${LIBDBI_DIR}`
    _LIBDBI_DRIVERS_UDIR=`unix_path ${LIBDBI_DRIVERS_DIR}`
    _LIBGDA_UDIR=`unix_path $LIBGDA_DIR`
    _GNUCASH_UDIR=`unix_path $GNUCASH_DIR`
    _GC_WIN_REPOS_UDIR=`unix_path $GC_WIN_REPOS_DIR`
    _REPOS_UDIR=`unix_path $REPOS_DIR`
    _BUILD_UDIR=`unix_path $BUILD_DIR`
    _DIST_UDIR=`unix_path $DIST_DIR`
    _MINGW_UDIR=`unix_path $MINGW_DIR`
    _INSTALL_UDIR=`unix_path $INSTALL_DIR`
    _INNO_UDIR=`unix_path $INNO_DIR`
    _WEBKIT_UDIR=`unix_path $WEBKIT_DIR`
    _ICU4C_UDIR=`unix_path $ICU4C_DIR`
    _ISOCODES_UDIR=`unix_path $ISOCODES_DIR`
    _MINGW_WFSDIR=`win_fs_path $MINGW_DIR`
    add_to_env $_UNZIP_UDIR/bin PATH # unzip
    add_to_env $_EXETYPE_UDIR/bin PATH # exetype

    _PID=$$
}

function dist_mingw() {
    setup mingw

    # Prepare mingw-get to install to alternative location
    MINGWGET_DIST_DIR=${GNUCASH_DIR}\\mingw-get-dist
    MINGWGET_DIST_UDIR=`unix_path $MINGWGET_DIST_DIR`
    mkdir -p $MINGWGET_DIST_UDIR/{bin,libexec,var/lib/mingw-get/data}
    cp $_MINGW_UDIR/bin/mingw-get.exe $MINGWGET_DIST_UDIR/bin/
    cp -a $_MINGW_UDIR/libexec/mingw-get/ $MINGWGET_DIST_UDIR/libexec/
    cp -a $_MINGW_UDIR/var/lib/mingw-get/data/defaults.xml $MINGWGET_DIST_UDIR/var/lib/mingw-get/data/profile.xml
    perl -pi.bak -e 's!.*subsystem="mingw32".*!    <sysroot subsystem="mingw32" path="%R/../dist" />!' $MINGWGET_DIST_UDIR/var/lib/mingw-get/data/profile.xml
    rm -f $MINGWGET_DIST_UDIR/var/lib/mingw-get/data/{manifest,sysroot}*

    configure_msys "$_PID" "$_MINGW_WFSDIR"

    add_to_env $_MINGW_UDIR/bin PATH
    add_to_env $MINGWGET_DIST_UDIR/bin/ PATH

    mingw_smart_get mingw32-libgmp-dll ${MINGW_GMP_VERSION}
    mingw_smart_get mingw32-libpthread-dll ${MINGW_PTHREAD_W32_VERSION}
    mingw_smart_get mingw32-libz-dll ${MINGW_ZLIB_VERSION}
    mingw_smart_get mingw32-libgcc-dll ${MINGW_GCC_VERSION}
    mingw_smart_get mingw32-libiconv-dll ${MINGW_LIBICONV_VERSION}
    mingw_smart_get mingw32-libintl-dll ${MINGW_GETTEXT_VERSION}
    mingw_smart_get mingw32-libltdl-dll ${MINGW_LIBLTDL_VERSION}
}

function dist_aqbanking() {
    setup aqbanking
    cp -a ${_AQBANKING_UDIR}/bin/*.exe ${_DIST_UDIR}/bin
    cp -a ${_AQBANKING_UDIR}/bin/*.dll ${_DIST_UDIR}/bin
    cp -a ${_AQBANKING_UDIR}/lib/aqbanking ${_DIST_UDIR}/lib
    cp -a ${_AQBANKING_UDIR}/share/aqbanking ${_DIST_UDIR}/share
    cp -a ${_AQBANKING_UDIR}/share/locale ${_DIST_UDIR}/share
}

function dist_boost() {
    setup Boost
    get_major_minor "$GNUCASH_SCM_REV"
    if [ "$GNUCASH_SCM_REV" != "master" ] &&
           (( $major_minor <= 206 )); then
        echo "Skipping. Boost is only needed for the master branch or future 2.7.x and up versions of gnucash."
        return
    fi

    cp -a ${_BOOST_UDIR}/lib/libboost_chrono.dll ${_DIST_UDIR}/bin
    cp -a ${_BOOST_UDIR}/lib/libboost_date_time.dll ${_DIST_UDIR}/bin
    cp -a ${_BOOST_UDIR}/lib/libboost_regex.dll ${_DIST_UDIR}/bin
}

function dist_gnome() {
    setup Gnome platform
    wget_unpacked $CAIRO_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $EXPAT_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $FREETYPE_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $GAIL_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $GETTEXT_RUNTIME_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $GLIB_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $GTK_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $LIBART_LGPL_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $LIBGNOMECANVAS_URL $DOWNLOAD_DIR $DIST_DIR
    smart_wget $LIBICONV_URL $DOWNLOAD_DIR
    unzip -q $LAST_FILE bin/iconv.dll -d $DIST_DIR
    wget_unpacked $LIBPNG_URL $DOWNLOAD_DIR $DIST_DIR
    wget_unpacked $LIBTIFF_URL $DOWNLOAD_DIR $DIST_DIR
    #wget_unpacked $LIBXML2_URL $DOWNLOAD_DIR $DIST_DIR
    echo 'gtk-theme-name = "Nimbus"' > $DIST_DIR/etc/gtk-2.0/gtkrc

    wget_unpacked $GTK_THEME_URL $DOWNLOAD_DIR $TMP_DIR
    assert_one_dir $TMP_UDIR/gtk2-themes-*
    cp -a $TMP_UDIR/gtk2-themes-*/lib $DIST_DIR/
    cp -a $TMP_UDIR/gtk2-themes-*/share $DIST_DIR/
    rm -rf $TMP_UDIR/gtk2-themes-*

    wget_unpacked $GTK_PREFS_URL $DOWNLOAD_DIR $TMP_DIR
    assert_one_dir $TMP_UDIR/gtk2_prefs-*
    mv $TMP_UDIR/gtk2_prefs-*/gtk2_prefs.exe $DIST_DIR/bin
    rm -rf $TMP_UDIR/gtk2_prefs-*

    cp -a $_GNOME_UDIR/bin/libxml*.dll $DIST_DIR/bin

    if [ -d $_DIST_UDIR/lib/locale ] ; then
        # Huh, is this removed in newer gtk?
        cp -a $_DIST_UDIR/lib/locale $_DIST_UDIR/share
        rm -rf $_DIST_UDIR/lib/locale
    fi
}

function dist_gnutls() {
    setup gnutls
    cp -a ${_GNUTLS_UDIR}/bin/*.dll ${_DIST_UDIR}/bin
    cp -a ${_GNUTLS_UDIR}/bin/*.exe ${_DIST_UDIR}/bin
}

function dist_goffice() {
    setup GOffice
    mkdir -p $_DIST_UDIR/bin
    cp -a $_GOFFICE_UDIR/bin/libgoffice*.dll $_DIST_UDIR/bin
    mkdir -p $_DIST_UDIR/lib
    cp -a $_GOFFICE_UDIR/lib/goffice $_DIST_UDIR/lib
    mkdir -p $_DIST_UDIR/share
    cp -a $_GOFFICE_UDIR/share/{goffice,locale,pixmaps} $_DIST_UDIR/share
}

function dist_guile() {
    setup Guile
    mkdir -p $_DIST_UDIR/bin
    cp -a $_GUILE_UDIR/bin/libguile*.dll $_DIST_UDIR/bin
    cp -a $_GUILE_UDIR/bin/guile.exe $_DIST_UDIR/bin
    mkdir -p $_DIST_UDIR/share
    cp -a $_GUILE_UDIR/share/guile $_DIST_UDIR/share
}

function dist_gwenhywfar() {
    setup gwenhywfar
    cp -a ${_GWENHYWFAR_UDIR}/bin/*.dll ${_DIST_UDIR}/bin
    mkdir -p ${_DIST_UDIR}/etc
    cp -a ${_GWENHYWFAR_UDIR}/lib/gwenhywfar ${_DIST_UDIR}/lib
    mkdir -p ${_DIST_UDIR}/share
    cp -a ${_GWENHYWFAR_UDIR}/share/gwenhywfar ${_DIST_UDIR}/share
}

function dist_isocodes() {
    setup isocodes
    mkdir -p $_DIST_UDIR/share
    cp -a $_ISOCODES_UDIR/share/{locale,xml} $_DIST_UDIR/share
}

function dist_ktoblzcheck() {
    setup ktoblzcheck
    # dll is already copied in dist_gwenhywfar
    cp -a ${_GWENHYWFAR_UDIR}/share/ktoblzcheck ${_DIST_UDIR}/share
}

function dist_libdbi() {
    setup LibDBI
    cp -a ${_SQLITE3_UDIR}/bin/* ${_DIST_UDIR}/bin
    cp -a ${_MYSQL_LIB_UDIR}/bin/*.{dll,manifest} ${_DIST_UDIR}/bin
    cp -a ${_MYSQL_LIB_UDIR}/lib/*.dll ${_DIST_UDIR}/bin
    cp -a ${_PGSQL_UDIR}/bin/* ${_DIST_UDIR}/bin
    cp -a ${_PGSQL_UDIR}/lib/*.dll ${_DIST_UDIR}/bin
    cp -a ${_LIBDBI_UDIR}/bin/* ${_DIST_UDIR}/bin
    mkdir ${_DIST_UDIR}/lib/dbd
    cp -a ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/*.dll ${_DIST_UDIR}/lib/dbd
}

function dist_libgsf() {
    setup libGSF
    mkdir -p $_DIST_UDIR/bin
    cp -a $_LIBGSF_UDIR/bin/libgsf*.dll $_DIST_UDIR/bin
    mkdir -p $_DIST_UDIR/share
    cp -a $_LIBGSF_UDIR/share/locale $_DIST_UDIR/share
}

function dist_libofx() {
    setup OpenSP and LibOFX
    cp -a ${_OPENSP_UDIR}/bin/*.dll ${_DIST_UDIR}/bin
    cp -a ${_OPENSP_UDIR}/share/OpenSP ${_DIST_UDIR}/share
    cp -a ${_LIBOFX_UDIR}/bin/*.dll ${_DIST_UDIR}/bin
    cp -a ${_LIBOFX_UDIR}/bin/*.exe ${_DIST_UDIR}/bin
    cp -a ${_LIBOFX_UDIR}/share/libofx ${_DIST_UDIR}/share
}

function dist_openssl() {
    setup OpenSSL
    _OPENSSL_UDIR=`unix_path $OPENSSL_DIR`
    mkdir -p $_DIST_UDIR/bin
    cp -a $_OPENSSL_UDIR/bin/*.dll $_DIST_UDIR/bin
}

function dist_pcre() {
    setup pcre
    mkdir -p $_DIST_UDIR/bin
    cp -a $_PCRE_UDIR/bin/pcre3.dll $_DIST_UDIR/bin
}

function dist_regex() {
    setup RegEx
    smart_wget $REGEX_URL $DOWNLOAD_DIR
    unzip -q $LAST_FILE bin/libgnurx-0.dll -d $DIST_DIR
}

function dist_webkit() {
    setup WebKit
    cp -a ${_LIBSOUP_UDIR}/bin/* ${_DIST_UDIR}/bin
    cp -a ${_LIBXSLT_UDIR}/bin/* ${_DIST_UDIR}/bin
    cp -a ${_ENCHANT_UDIR}/bin/* ${_DIST_UDIR}/bin
    cp -a ${_WEBKIT_UDIR}/bin/* ${_DIST_UDIR}/bin
}

function dist_icu4c() {
    setup icu4c
    get_major_minor "$GNUCASH_SCM_REV"
    if [ "$GNUCASH_SCM_REV" != "master" ] &&
           (( $major_minor <= 206 )); then
        echo "Skipping. ICU is only needed for the master branch or future 2.7.x and up versions of gnucash."
        return
    fi
    cp -a ${_ICU4C_UDIR}/bin/* ${_DIST_UDIR}/bin
}

function dist_gnucash() {
    setup GnuCash
    mkdir -p $_DIST_UDIR/bin
    cp $_MINGW_UDIR/bin/pthreadGC-3.dll $_DIST_UDIR/bin
    cp -a $_INSTALL_UDIR/bin/* $_DIST_UDIR/bin
    mkdir -p $_DIST_UDIR/etc/gnucash
    cp -a $_INSTALL_UDIR/etc/gnucash/* $_DIST_UDIR/etc/gnucash

    # For CMake builds, there are no lib*.la files, so skip. 
    if [ "$WITH_CMAKE" != "yes" ]; then
        cp -a $_INSTALL_UDIR/lib/lib*.la $_DIST_UDIR/bin
    fi 

    mkdir -p $_DIST_UDIR/share
    cp -a $_INSTALL_UDIR/share/{doc,gnucash,locale,glib-2.0} $_DIST_UDIR/share
    cp -a $_GC_WIN_REPOS_UDIR/extra_dist/{getperl.vbs,gnc-path-check,install-fq-mods.cmd} $_DIST_UDIR/bin

    _QTDIR_WIN=$(unix_path $QTDIR | sed 's,^/\([A-Za-z]\)/,\1:/,g' )
    # aqbanking >= 5.0.0
    AQBANKING_VERSION_H=${_AQBANKING_UDIR}/include/aqbanking5/aqbanking/version.h
    GWENHYWFAR_VERSION_H=${_GWENHYWFAR_UDIR}/include/gwenhywfar4/gwenhywfar/version.h
    GNUCASH_CONFIG_H=${_BUILD_UDIR}/config.h
    if [ "$WITH_CMAKE" == "yes" ]; then
        GNUCASH_CONFIG_H=${_BUILD_UDIR}/src/config.h
    fi

    _AQBANKING_SO_EFFECTIVE=$(awk '/AQBANKING_SO_EFFECTIVE / { print $3 }' ${AQBANKING_VERSION_H} )
    _GWENHYWFAR_SO_EFFECTIVE=$(awk '/GWENHYWFAR_SO_EFFECTIVE / { print $3 }' ${GWENHYWFAR_VERSION_H} )
    PACKAGE_VERSION=$(awk '/ PACKAGE_VERSION / { print $3 }' ${GNUCASH_CONFIG_H} | cut -d\" -f2 )
    PACKAGE=$(awk '/ PACKAGE / { print $3 }' ${GNUCASH_CONFIG_H} | cut -d\" -f2 )
    GNUCASH_MAJOR_VERSION=$(awk '/ GNUCASH_MAJOR_VERSION / { print $3 }' ${GNUCASH_CONFIG_H} )
    GNUCASH_MINOR_VERSION=$(awk '/ GNUCASH_MINOR_VERSION / { print $3 }' ${GNUCASH_CONFIG_H} )
    GNUCASH_MICRO_VERSION=$(awk '/ GNUCASH_MICRO_VERSION / { print $3 }' ${GNUCASH_CONFIG_H} )
    DIST_WFSDIR=$(echo $DIST_DIR | sed -e 's#\\#\\\\#g')
    GC_WIN_REPOS_WFSDIR=$(echo $GC_WIN_REPOS_DIR | sed -e 's#\\#\\\\#g')
    sed < $_GC_WIN_REPOS_UDIR/inno_setup/gnucash.iss \
        > $_GNUCASH_UDIR/gnucash.iss \
        -e "s#@-qtbindir-@#${_QTDIR_WIN}/bin#g" \
        -e "s#@-gwenhywfar_so_effective-@#${_GWENHYWFAR_SO_EFFECTIVE}#g" \
        -e "s#@-aqbanking_so_effective-@#${_AQBANKING_SO_EFFECTIVE}#g" \
        -e "s#@PACKAGE_VERSION@#${PACKAGE_VERSION}#g" \
        -e "s#@PACKAGE@#${PACKAGE}#g" \
        -e "s#@GNUCASH_MAJOR_VERSION@#${GNUCASH_MAJOR_VERSION}#g" \
        -e "s#@GNUCASH_MINOR_VERSION@#${GNUCASH_MINOR_VERSION}#g" \
        -e "s#@GNUCASH_MICRO_VERSION@#${GNUCASH_MICRO_VERSION}#g" \
        -e "s#@DIST_DIR@#${DIST_WFSDIR}#g" \
        -e "s#@GC_WIN_REPOS_DIR@#${GC_WIN_REPOS_WFSDIR}#g"
}

function dist_finish() {
    if [ "$WITH_CMAKE" != "yes" ]; then
        # Strip redirections in distributed libtool .la files.
	# Skip this for CMake builds, which don't generate *.la files.

        for file in $_DIST_UDIR/bin/*.la; do
            cat $file | sed 's,^libdir=,#libdir=,' > $file.new
            mv $file.new $file
        done
    fi;

    echo "Now running the Inno Setup Compiler for creating the setup.exe"
    ${_INNO_UDIR}/iscc //Q ${_GNUCASH_UDIR}/gnucash.iss

    if [ "$BUILD_FROM_TARBALL" = "no" ]; then
        # And changing output filename
        PKG_VERSION=`grep PACKAGE_VERSION ${GNUCASH_CONFIG_H} | cut -d" " -f3 | cut -d\" -f2 `
        REVISION=`grep GNUCASH_SCM_REV ${_BUILD_UDIR}/src/core-utils/gnc-vcs-info.h | cut -d" " -f3 | cut -d\" -f2 `
        SETUP_FILENAME="gnucash-${PKG_VERSION}-$(date +'%Y-%m-%d')-${REPOS_TYPE}-${REVISION}-setup.exe"
        qpushd ${_GNUCASH_UDIR}
            mv gnucash-${PKG_VERSION}-setup.exe ${SETUP_FILENAME}
        qpopd
        echo "Final resulting Setup program is:"
        echo ${_GNUCASH_UDIR}/${SETUP_FILENAME}
    fi
}

### Local Variables: ***
### sh-basic-offset: 4 ***
### indent-tabs-mode: nil ***
### End: ***
