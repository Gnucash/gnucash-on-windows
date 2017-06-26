#!/bin/sh
#
# GnuCash shellscript functions for install.sh
#

function inst_prepare() {
    # Necessary so that intltoolize doesn't come up with some
    # foolish AC_CONFIG_AUX_DIR; bug#362006
    # We cannot simply create install-sh in the repository, because
    # this will confuse other parts of the tools
    _REPOS_UDIR=`unix_path $REPOS_DIR`
    level0=.
    level1=$(basename ${_REPOS_UDIR})
    level2=$(basename $(dirname ${_REPOS_UDIR}))"/"$level1
    for mydir in $level0 $level1 $level2; do
        if [ -f $mydir/make-gnucash-potfiles.in ]; then
            die "Do not save install.sh in the repository or one its parent directories"
        fi
    done
#     # Remove old empty install-sh files
#     if [ -f ${_REPOS_UDIR}/install-sh -a "$(cat ${_REPOS_UDIR}/install-sh &>/dev/null | wc -l)" -eq 0 ]; then
#         rm -f ${_REPOS_UDIR}/install-sh
#     fi
    # Partially remove RegEx-GNU if installed
    _REGEX_UDIR=`unix_path $REGEX_DIR`
    if [ -f ${_REGEX_UDIR}/contrib/regex-0.12-GnuWin32.README ]; then
        qpushd ${_REGEX_UDIR}
            rm -f bin/*regex*.dll
            rm -f contrib/regex*
            rm -f lib/*regex*
        qpopd
    fi

    DOWNLOAD_UDIR=`unix_path $DOWNLOAD_DIR`
    TMP_UDIR=`unix_path $TMP_DIR`
    mkdir -p $TMP_UDIR
    mkdir -p $DOWNLOAD_UDIR

    if [ "$DISABLE_OPTIMIZATIONS" = "yes" ]; then
        export CFLAGS="$CFLAGS -g -O0"
    fi

    if [ "$CROSS_COMPILE" = "yes" ]; then
        # to avoid using the build machine's installed packages
        set_env "" PKG_CONFIG_PATH    # registered
        export PKG_CONFIG_LIBDIR=""   # not registered
    fi

  # Save pid for use in temporary files
  _PID=$$
}

function inst_msys() {
    setup MSys
    _MINGW_UDIR=`unix_path $MINGW_DIR`
    _MINGW_LDDIR=/mingw/lib
    _MSYS_UDIR=`unix_path $MSYS_DIR`
    add_to_env $_MINGW_UDIR/bin PATH
    add_to_env $_MSYS_UDIR/bin PATH

    # The bootstrap script already set some of this up
    # It will be set up again here to catch version updates of any of these packages
    mingw-get update
    mingw-get upgrade mingw-get

    # Note: msys-base can't be upgraded by this script
    #       it potentially will want to upgrade bash
    #       which will fail because bash is running
    #       If you want to install a newer version
    #       of msys-base anyway, then
    #       - open a traditional windows command shell
    #       - cd into your MINGW's bin directory
    #         (Default: c:\soft\mingw\bin)
    #       - run mingw-get upgrade msys-base
    #       - or mingw-get upgrade msys-base=<new-version>
    #mingw_smart_get upgrade msys-base
    mingw_smart_get msys-wget ${MSYS_WGET_VERSION}
    mingw_smart_get msys-m4 ${MSYS_M4_VERSION}
    mingw_smart_get msys-patch ${MSYS_PATCH_VERSION}
    mingw_smart_get msys-perl ${MSYS_PERL_VERSION}
    mingw_smart_get msys-unzip ${MSYS_UNZIP_VERSION}
    mingw_smart_get msys-bison ${MSYS_BISON_VERSION}
    mingw_smart_get msys-flex ${MSYS_FLEX_VERSION}

    quiet perl --help || die "perl not installed correctly"
    quiet wget --version || die "wget unavailable"
    quiet unzip --help || die "unzip unavailable"
}

function inst_cmake() {
    setup CMake
    _CMAKE_UDIR=`unix_path ${CMAKE_DIR}`
    add_to_env ${_CMAKE_UDIR}/bin PATH
    if [ -f ${_CMAKE_UDIR}/bin/cmake.exe ]
    then
        echo "cmake already installed in $_CMAKE_UDIR.  skipping."
    else
        WGET_EXTRA_OPTIONS="--no-check-certificate"
        wget_unpacked $CMAKE_URL $DOWNLOAD_DIR $CMAKE_DIR
        unset WGET_EXTRA_OPTIONS
        assert_one_dir ${_CMAKE_UDIR}/cmake-3*
        mv ${_CMAKE_UDIR}/cmake-3*/* ${_CMAKE_UDIR}
        rm -rf ${_CMAKE_UDIR}/cmake-3*

        [ -f ${_CMAKE_UDIR}/bin/cmake.exe ] || die "cmake not installed correctly"
    fi
}

function inst_ninja() {
    setup Ninja
    _NINJA_UDIR=`unix_path ${NINJA_DIR}`
    add_to_env ${_NINJA_UDIR} PATH
    if [ -f ${_NINJA_UDIR}/ninja.exe ]
    then
        echo "ninja already install in $_NINJA_UDIR.  skipping."
    else
        WGET_EXTRA_OPTIONS="--no-check-certificate -O $TMP_DIR\\$(basename $NINJA_URL)"
        wget_unpacked $NINJA_URL $DOWNLOAD_DIR $NINJA_DIR
        unset WGET_EXTRA_OPTIONS

        [ -f ${_NINJA_UDIR}/ninja.exe ] || die "ninja not installed correctly"
    fi
}

function inst_exetype() {
    setup exetype
    _EXETYPE_UDIR=`unix_path $EXETYPE_DIR`
    add_to_env $_EXETYPE_UDIR/bin PATH
    if quiet which exetype
    then
        echo "exetype already installed in $_EXETYPE_UDIR.  skipping."
    else
        mkdir -p $_EXETYPE_UDIR/bin
        cp $EXETYPE_SCRIPT $_EXETYPE_UDIR/bin/exetype
        chmod +x $_EXETYPE_UDIR/bin/exetype
        quiet which exetype || die "exetype unavailable"
    fi
}

function test_for_mingw() {
    if [ "$CROSS_COMPILE" == "yes" ]; then
        ${CC} --version && ${LD} --help
    else
#        g++ --version && mingw32-make --help
        g++ --version
    fi
}

function inst_mingw() {
    setup MinGW
    _MINGW_UDIR=`unix_path $MINGW_DIR`
    _MINGW_WFSDIR=`win_fs_path $MINGW_DIR`
    # Configure msys to use mingw on the above path before running any tests !
    configure_msys "$_PID" "$_MINGW_WFSDIR"
    add_to_env $_MINGW_UDIR/bin PATH

    mkdir -p $_MINGW_UDIR

    # Download the precompiled packages in any case to get their DLLs
    # NOTE: installation order matters here - care should be taken
    #       that each call to mingw_smart_get really installs one package
    #       or group of packages that embody one entity such as gcc's subpackages)
    #       This is due to the very limited package management features
    #       of mingw-get (which is called by mingw_smart_get.
    #       If multiple packages are automatically installed in
    #       one command, it becomes virtually impossible to guarantee
    #       the predetermined versions of all packages will be installed
    #       (instead of the most recent one)

    # Win32 runtime and api
    mingw_smart_get mingw32-mingwrt-dev ${MINGW_RT_VERSION}
    mingw_smart_get mingw32-w32api-dev ${MINGW_W32API_VERSION}
    # GCC/G++ dependencies
    mingw_smart_get mingw32-libgmp-dll ${MINGW_GMP_VERSION}
    mingw_smart_get mingw32-libmpfr-dll ${MINGW_MPFR_VERSION}
    mingw_smart_get mingw32-libmpc-dll ${MINGW_MPC_VERSION}
    mingw_smart_get mingw32-libpthread-dll ${MINGW_PTHREAD_W32_VERSION}
    mingw_smart_get mingw32-libz-dll ${MINGW_ZLIB_VERSION}
    mingw_smart_get mingw32-libgcc-dll ${MINGW_GCC_VERSION}
    # Gettext and friends - should come before binutils
    mingw_smart_get mingw32-libiconv-dev ${MINGW_LIBICONV_VERSION}
    mingw_smart_get mingw32-libexpat-dev ${MINGW_LIBEXPAT_VERSION}
    mingw_smart_get mingw32-gettext-dev ${MINGW_GETTEXT_VERSION}
    # Binutils and GCC/G++ binaries
    mingw_smart_get mingw32-binutils-bin ${MINGW_BINUTILS_VERSION}
    mingw_smart_get mingw32-gcc ${MINGW_GCC_VERSION}
    mingw_smart_get mingw32-gcc-g++ ${MINGW_GCC_VERSION}
    # Autotools
    mingw_smart_get mingw32-autoconf2.1 ${MINGW_AUTOCONF21_VERSION}
    mingw_smart_get mingw32-autoconf2.5 ${MINGW_AUTOCONF25_VERSION}
    mingw_smart_get mingw32-autoconf ${MINGW_AUTOCONF_VERSION}
    mingw_smart_get mingw32-automake1.11 ${MINGW_AUTOMAKE111_VERSION}
    mingw_smart_get mingw32-automake1.10 ${MINGW_AUTOMAKE110_VERSION}
    mingw_smart_get mingw32-automake1.9 ${MINGW_AUTOMAKE19_VERSION}
    mingw_smart_get mingw32-automake1.8 ${MINGW_AUTOMAKE18_VERSION}
    mingw_smart_get mingw32-automake1.7 ${MINGW_AUTOMAKE17_VERSION}
    mingw_smart_get mingw32-automake1.6 ${MINGW_AUTOMAKE16_VERSION}
    mingw_smart_get mingw32-automake1.5 ${MINGW_AUTOMAKE15_VERSION}
    mingw_smart_get mingw32-automake1.4 ${MINGW_AUTOMAKE14_VERSION}
    mingw_smart_get mingw32-automake ${MINGW_AUTOMAKE_VERSION}
    mingw_smart_get mingw32-libtool ${MINGW_LIBTOOL_VERSION}
    mingw_smart_get mingw32-libltdl ${MINGW_LIBLTDL_VERSION}
    mingw_smart_get mingw32-libiconv-bin ${MINGW_LIBICONV_VERSION}
    # Build dependencies for gnucash and other self-built libraries
    mingw_smart_get mingw32-gmp-dev ${MINGW_GMP_VERSION}
    mingw_smart_get mingw32-pthreads-w32-dev ${MINGW_PTHREAD_W32_VERSION}

    if [ "$CROSS_COMPILE" != "yes" ]; then
        mingw_smart_get mingw32-pexports ${MINGW_PEXPORTS_VERSION}
        quiet which pexports || die "mingw-utils not installed correctly (pexports)"
        # Hack to make Gnome's pkg-config happy (without having to rebuild it)
        cp "${_MINGW_UDIR}"/bin/libintl*.dll "${_MINGW_UDIR}/bin/intl.dll"
    else
        ./create_cross_mingw.sh
    fi

    # Test if everything worked out correctly
    quiet test_for_mingw || die "mingw not installed correctly"
    quiet autoconf --help || die "autoconf not installed correctly"
    quiet automake --help || die "automake not installed correctly"
    quiet libtoolize --help && \
    quiet ${LD} -lltdl -o $TMP_UDIR/ofile || die "libtool/libtoolize not installed correctly"

    # Still needed ?
    #[ ! -d $_AUTOTOOLS_UDIR/share/aclocal ] || add_to_env "-I $_AUTOTOOLS_UDIR/share/aclocal" ACLOCAL_FLAGS
}

function inst_swig() {
    setup Swig
    _SWIG_UDIR=`unix_path $SWIG_DIR`
    add_to_env $_SWIG_UDIR PATH
    if quiet swig -version
    then
        echo "swig already installed in $_SWIG_UDIR.  skipping."
    else
        wget_unpacked $SWIG_URL $DOWNLOAD_DIR $SWIG_DIR
        qpushd $SWIG_DIR
            mv swigwin-* mydir
            mv mydir/* .
            mv mydir/.[A-Za-z]* . # hidden files
            rmdir mydir
            rm INSTALL # bites with /bin/install
        qpopd
        quiet swig -version || die "swig unavailable"
    fi
}

function inst_git() {
    setup Git
    _GIT_UDIR=`unix_path $GIT_DIR`
    # Don't add git's directory to the PATH, its installed DLLs conflict
    # with the ones in our mingw environment
    # add_to_env $_GIT_UDIR/bin PATH
    if quiet git --help
    then
        echo "git already installed in the system path.  skipping."
        set_env git GIT_CMD
    elif quiet "$_GIT_UDIR/bin/git" --help
    then
        echo "git already installed in $_GIT_UDIR.  skipping."
        set_env "$_GIT_UDIR/bin/git" GIT_CMD
    else
        WGET_EXTRA_OPTIONS="--no-check-certificate -O$TMP_DIR\\$(basename $GIT_URL)" # github certificate can't be verified on WinXP
        smart_wget $GIT_URL $DOWNLOAD_DIR $(basename $GIT_URL)
        $LAST_FILE //SP- //SILENT //DIR="$GIT_DIR"
        set_env "$_GIT_UDIR/bin/git" GIT_CMD
        unset WGET_EXTRA_OPTIONS
        quiet "$GIT_CMD" --help || die "git unavailable"
    fi
    # Make sure GIT_CMD is available to subshells if it is set
    [ -n "$GIT_CMD" ] && export GIT_CMD
}

function inst_aqbanking() {
    setup AqBanking
    _AQBANKING_UDIR=`unix_path ${AQBANKING_DIR}`
    add_to_env ${_AQBANKING_UDIR}/bin PATH
    add_to_env ${_AQBANKING_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --exact-version=${AQBANKING_VERSION} aqbanking
    then
        echo "AqBanking ${AQBANKING_VERSION} already installed in $_AQBANKING_UDIR. skipping."
    else
        wget_unpacked $AQBANKING_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/aqbanking-*
        qpushd $TMP_UDIR/aqbanking-*
            if [ -n "$AQB_PATCH" -a -f "$AQB_PATCH" ]; then
                patch -p1 < $AQB_PATCH
            fi

            _AQ_CPPFLAGS="-I${_LIBOFX_UDIR}/include ${KTOBLZCHECK_CPPFLAGS} ${GNOME_CPPFLAGS} ${GNUTLS_CPPFLAGS} -I${_GWENHYWFAR_UDIR}/include/gwenhywfar4"
            _AQ_LDFLAGS="-L${_LIBOFX_UDIR}/lib ${KTOBLZCHECK_LDFLAGS} ${GNOME_LDFLAGS} ${GNUTLS_LDFLAGS}"
            if test x$CROSS_COMPILE = xyes; then
                XMLMERGE="xmlmerge"
            else
                XMLMERGE="${_GWENHYWFAR_UDIR}/bin/xmlmerge"
            fi
            _AQ_BACKENDS="aqhbci aqofxconnect"
            if [ -n "$AQBANKING_PATCH" -a -f "$AQBANKING_PATCH" ] ; then
                patch -p1 < $AQBANKING_PATCH
                #automake
                #aclocal -I m4 ${ACLOCAL_FLAGS}
                #autoconf
            fi
            ./configure ${HOST_XCOMPILE} \
                --with-gwen-dir=${_GWENHYWFAR_UDIR} \
                --with-xmlmerge=${XMLMERGE} \
                --with-frontends="cbanking" \
                --with-backends="${_AQ_BACKENDS}" \
                CPPFLAGS="${_AQ_CPPFLAGS}" \
                LDFLAGS="${_AQ_LDFLAGS}" \
                --prefix=${_AQBANKING_UDIR}
            make
            rm -rf ${_AQBANKING_UDIR}
            make install
        qpopd
        qpushd ${_AQBANKING_UDIR}/bin
            exetype aqbanking-cli.exe console
            exetype aqhbci-tool4.exe console
        qpopd
        ${PKG_CONFIG} --exists aqbanking || die "AqBanking not installed correctly"
        rm -rf ${TMP_UDIR}/aqbanking-*
    fi
    [ ! -d $_AQBANKING_UDIR/share/aclocal ] || add_to_env "-I $_AQBANKING_UDIR/share/aclocal" ACLOCAL_FLAGS
}

function inst_enchant() {
    setup enchant
    _ENCHANT_UDIR=`unix_path $ENCHANT_DIR`
    add_to_env ${_ENCHANT_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    add_to_env -L${_ENCHANT_UDIR}/lib ENCHANT_LDFLAGS
    if quiet ${PKG_CONFIG} --exists enchant
    then
        echo "enchant already installed in $_ENCHANT_UDIR.  skipping."
    else
        wget_unpacked $ENCHANT_URL $DOWNLOAD_DIR $ENCHANT_DIR
        wget_unpacked $ENCHANT_DEV_URL $DOWNLOAD_DIR $ENCHANT_DIR
        quiet ${PKG_CONFIG} --exists enchant || die "enchant not installed correctly"
    fi
}

function inst_glade() {
    setup Glade
    _GLADE_UDIR=`unix_path $GLADE_DIR`
    _GLADE_WFSDIR=`win_fs_path $GLADE_DIR`
    add_to_env $_GLADE_UDIR/bin PATH
    if quiet glade-3 --version
    then
        echo "glade already installed in $_GLADE_UDIR.  skipping."
    else
        wget_unpacked $GLADE_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/glade3-*
        qpushd $TMP_UDIR/glade3-*
            ./configure ${HOST_XCOMPILE} --prefix=$_GLADE_WFSDIR
            make
            make install
        qpopd
        quiet glade-3 --version || die "glade not installed correctly"
        rm -rf ${TMP_UDIR}/glade3-*
    fi
}

function inst_gnome() {
    setup Gnome platform
    _GNOME_UDIR=`unix_path $GNOME_DIR`
    add_to_env -I$_GNOME_UDIR/include GNOME_CPPFLAGS
    add_to_env -L$_GNOME_UDIR/lib GNOME_LDFLAGS
    add_to_env $_GNOME_UDIR/bin PATH
    add_to_env $_GNOME_UDIR/lib/pkgconfig PKG_CONFIG_PATH
    add_to_env pkg-config PKG_CONFIG
    if quiet ${PKG_CONFIG} --atleast-version=${GTK_VERSION} gtk+-2.0 &&
        quiet ${PKG_CONFIG} --atleast-version=${CAIRO_VERSION} cairo &&
        quiet ${PKG_CONFIG} --exact-version=${LIBXML2_VERSION} libxml-2.0 &&
        quiet intltoolize --version
    then
        echo "gnome packages installed in $_GNOME_UDIR.  skipping."
    else
        mkdir -p $_GNOME_UDIR
        wget_unpacked $CAIRO_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $CAIRO_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $EXPAT_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $EXPAT_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $FREETYPE_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $FREETYPE_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $GAIL_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $GAIL_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $GLIB_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $GLIB_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $GTK_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $GTK_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $INTLTOOL_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBART_LGPL_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBART_LGPL_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBGNOMECANVAS_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBGNOMECANVAS_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBPNG_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBPNG_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBTIFF_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $LIBTIFF_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $PKG_CONFIG_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $PKG_CONFIG_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $ZLIB_URL $DOWNLOAD_DIR $GNOME_DIR
        wget_unpacked $ZLIB_DEV_URL $DOWNLOAD_DIR $GNOME_DIR
        echo 'gtk-theme-name = "Nimbus"' > ${_GNOME_UDIR}/etc/gtk-2.0/gtkrc

        wget_unpacked $GTK_THEME_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/gtk2-themes-*
        cp -a $TMP_UDIR/gtk2-themes-*/lib $_GNOME_UDIR/
        cp -a $TMP_UDIR/gtk2-themes-*/share $_GNOME_UDIR/
        rm -rf $TMP_UDIR/gtk2-themes-*

        wget_unpacked $GTK_PREFS_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/gtk2_prefs-*
        mv $TMP_UDIR/gtk2_prefs-*/gtk2_prefs.exe $_GNOME_UDIR/bin
        rm -rf $TMP_UDIR/gtk2_prefs-*

        wget_unpacked $GTK_DOC_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/gtk-doc-*
        mv $TMP_UDIR/gtk-doc-*/gtk-doc.m4 $_GNOME_UDIR/share/aclocal
        rm -rf $TMP_UDIR/gtk-doc-*

        # Fix paths to tools used by gnome provided intltool scripts
        qpushd $_GNOME_UDIR
            for file in bin/intltool-*; do
                sed '1s,!.*perl,!'"perl"',;s,/opt/gnu/bin/iconv,iconv,' $file > tmp
                mv tmp $file
            done
        qpopd

        qpushd $_GNOME_UDIR/lib/pkgconfig
            perl -pi.bak -e"s!^prefix=.*\$!prefix=$_GNOME_UDIR!" *.pc
            #perl -pi.bak -e's!^Libs: !Libs: -L\${prefix}/bin !' *.pc
        qpopd
        fix_libtool_files ${_GNOME_UDIR}

        if quiet ${PKG_CONFIG} --exact-version=${LIBXML2_VERSION} libxml-2.0 ; then
            echo "Libxml2 already compiled + installed"
        else
            wget_unpacked $LIBXML2_SRC_URL $DOWNLOAD_DIR $TMP_DIR
            assert_one_dir $TMP_UDIR/libxml2-*
            qpushd $TMP_UDIR/libxml2-*
                ./configure ${HOST_XCOMPILE} \
                    --prefix=${_GNOME_UDIR} \
                    --disable-static \
                    --with-python=no \
                    --without-threads \
                    CPPFLAGS="${GNOME_CPPFLAGS}" LDFLAGS="${GNOME_LDFLAGS}"
                make
                make install
            qpopd
            rm -rf ${TMP_UDIR}/libxml2-*
        fi

        quiet ${PKG_CONFIG} --atleast-version=${GTK_VERSION} gtk+-2.0 || die "gnome not installed correctly: no gtk+-2.0 with atleast-version=${GTK_VERSION}"
        quiet ${PKG_CONFIG} --atleast-version=${CAIRO_VERSION} cairo || die "gnome not installed correctly: no cairo with atleast-version=${CAIRO_VERSION}"
        quiet ${PKG_CONFIG} --exact-version=${LIBXML2_VERSION} libxml-2.0 || die "gnome not installed correctly: no libxml-2.0 with exact-version=${LIBXML2_VERSION}"
        quiet intltoolize --version || die "gnome not installed correctly: no intltoolize"
    fi
    [ ! -d $_GNOME_UDIR/share/aclocal ] || add_to_env "-I $_GNOME_UDIR/share/aclocal" ACLOCAL_FLAGS
}

function inst_gnutls() {
    setup GNUTLS
    _GNUTLS_UDIR=`unix_path ${GNUTLS_DIR}`
    add_to_env ${_GNUTLS_UDIR}/bin PATH
    add_to_env ${_GNUTLS_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    add_to_env "-I${_GNUTLS_UDIR}/include" GNUTLS_CPPFLAGS
    add_to_env "-L${_GNUTLS_UDIR}/lib" GNUTLS_LDFLAGS
    if quiet ${PKG_CONFIG} --exact-version=${GNUTLS_VERSION} gnutls
    then
        echo "GNUTLS already installed in $_GNUTLS_UDIR. skipping."
    else
        if [ "$BUILD_GNUTLS_FROM_SOURCE" = "yes" ]; then
            mkdir -p $_GNUTLS_UDIR
            wget_unpacked $GNUTLS_PKG_URL $DOWNLOAD_DIR $GNUTLS_DIR
            wget_unpacked $GCRYPT_SRC_URL $DOWNLOAD_DIR $TMP_DIR
            wget_unpacked $GPG_ERROR_SRC_URL $DOWNLOAD_DIR $TMP_DIR
            wget_unpacked $GLIB_NETWORKING_SRC_URL $DOWNLOAD_DIR $TMP_DIR
            rm $_GNUTLS_UDIR/lib/*.la
            assert_one_dir $TMP_UDIR/libgcrypt-*
            assert_one_dir $TMP_UDIR/libgpg-error-*
            assert_one_dir $TMP_UDIR/glib-networking-*
            qpushd $TMP_UDIR/libgpg-error-*
                sed -i'' s/ro// po/LINGUAS #Converting ro.po to UTF8 hangs
                ./configure ${HOST_XCOMPILE} --prefix=$_GNUTLS_UDIR  --disable-nls \
                    --disable-languages \
                    CPPFLAGS="${GNOME_CPPFLAGS}" \
                    LDFLAGS="${GNOME_LDFLAGS}"
                make
                make install
            qpopd
            qpushd $TMP_UDIR/libgcrypt-*
                ./configure ${HOST_XCOMPILE} --prefix=$_GNUTLS_UDIR \
                    CPPFLAGS="${GNOME_CPPFLAGS}" \
                    LDFLAGS="${GNOME_LDFLAGS}"
                make
                make install
            qpopd
            qpushd $TMP_UDIR/glib-networking-*
                ./configure ${HOST_XCOMPILE} --prefix=$_GNUTLS_UDIR \
                    --with-ca-certificates=no \
                    --with-pkcs11=no \
                    CPPFLAGS="${GNOME_CPPFLAGS}" \
                    LDFLAGS="${GNOME_LDFLAGS}"
                make
                make install
            qpopd

            rm -f $_GNUTLS_UDIR/lib/*.la
        else
            mkdir -p $_GNUTLS_UDIR
            wget_unpacked $GNUTLS_URL $DOWNLOAD_DIR $GNUTLS_DIR
            wget_unpacked $GNUTLS_DEV_URL $DOWNLOAD_DIR $GNUTLS_DIR
            fix_libtool_files ${_GNUTLS_UDIR}
        fi
        quiet ${PKG_CONFIG} --exists gnutls || die "GNUTLS not installed correctly"
    fi
    [ ! -d $_GNUTLS_UDIR/share/aclocal ] || add_to_env "-I $_GNUTLS_UDIR/share/aclocal" ACLOCAL_FLAGS
}

function inst_goffice() {
    setup GOffice
    _GOFFICE_UDIR=`unix_path $GOFFICE_DIR`
    add_to_env $_GOFFICE_UDIR/bin PATH
    add_to_env $_GOFFICE_UDIR/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --atleast-version=${GOFFICE_VERSION} libgoffice-0.8
    then
        echo "goffice already installed in $_GOFFICE_UDIR.  skipping."
    else
        wget_unpacked $GOFFICE_URL $DOWNLOAD_DIR $TMP_DIR
        mydir=`pwd`
        assert_one_dir $TMP_UDIR/goffice-*
        qpushd $TMP_UDIR/goffice-*
            [ -n "$GOFFICE_PATCH" -a -f "$GOFFICE_PATCH" ] && \
                patch -p1 < $GOFFICE_PATCH
            libtoolize --force
            aclocal ${ACLOCAL_FLAGS} -I .
            automake
            autoconf
            ./configure ${HOST_XCOMPILE} --prefix=$_GOFFICE_UDIR \
                CPPFLAGS="${GNOME_CPPFLAGS} ${PCRE_CPPFLAGS} ${HH_CPPFLAGS}" \
                LDFLAGS="${GNOME_LDFLAGS} ${PCRE_LDFLAGS} ${HH_LDFLAGS}"
            [ -d ../libgsf-* ] || die "We need the unpacked package $TMP_UDIR/libgsf-*; please unpack it in $TMP_UDIR"
            [ -f dumpdef.pl ] || cp -p ../libgsf-*/dumpdef.pl .
            make
            rm -rf ${_GOFFICE_UDIR}
            make install
        qpopd
        ${PKG_CONFIG} --exists libgoffice-0.8 && [ -f $_GOFFICE_UDIR/bin/libgoffice*.dll ] || die "goffice not installed correctly"
        rm -rf ${TMP_UDIR}/goffice-*
        rm -rf ${TMP_UDIR}/libgsf-*
    fi
}

function inst_guile() {
    setup Guile
    _GUILE_WFSDIR=`win_fs_path $GUILE_DIR`
    _GUILE_UDIR=`unix_path $GUILE_DIR`
    _GUILE_LDDIR=`unix_ldpath $GUILE_DIR`
    _WIN_UDIR=`unix_path $WINDIR`
    add_to_env -I$_GUILE_UDIR/include GUILE_CPPFLAGS
    add_to_env -L$_GUILE_LDDIR/lib GUILE_LDFLAGS
    add_to_env $_GUILE_UDIR/bin PATH
    add_to_env ${_GUILE_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    if quiet guile -c '(use-modules (srfi srfi-39))' &&
        quiet ${PKG_CONFIG} --atleast-version=${GUILE_VERSION} guile-1.8
    then
        echo "guile and slib already installed in $_GUILE_UDIR.  skipping."
    else
        smart_wget $GUILE_URL $DOWNLOAD_DIR
        _GUILE_BALL=$LAST_FILE
        tar -xzpf $_GUILE_BALL -C $TMP_UDIR
        assert_one_dir $TMP_UDIR/guile-*
        qpushd $TMP_UDIR/guile-*
            if [ -n "$GUILE_PATCH" -a -f "$GUILE_PATCH" ]; then
                patch -p1 < $GUILE_PATCH
            fi

            autoreconf -fvi
            ./configure ${HOST_XCOMPILE} -C \
                --disable-elisp \
                --disable-error-on-warning \
                --disable-dependency-tracking \
                --prefix=$_GUILE_WFSDIR \
                ac_cv_func_regcomp_rx=yes \
                ac_cv_func_strncasecmp=yes \
                CPPFLAGS="${READLINE_CPPFLAGS} ${REGEX_CPPFLAGS}" \
                LDFLAGS="${READLINE_LDFLAGS} ${REGEX_LDFLAGS} -Wl,--enable-auto-import"
            make
            make install
        qpopd
        guile -c '(use-modules (srfi srfi-39))' || die "guile not installed correctly"

        # If this libguile is used from MSVC compiler, we must
        # deactivate some macros of scmconfig.h again.
        SCMCONFIG_H=$_GUILE_UDIR/include/libguile/scmconfig.h
        cat >> ${SCMCONFIG_H} <<EOF

#ifdef _MSC_VER
# undef HAVE_STDINT_H
# undef HAVE_INTTYPES_H
# undef HAVE_UNISTD_H
#endif
EOF
        # Also, for MSVC compiler we need to create an import library
        if [ x"$(which pexports.exe > /dev/null 2>&1)" != x ]
        then
            pexports $_GUILE_UDIR/bin/libguile.dll > $_GUILE_UDIR/lib/libguile.def
            ${DLLTOOL} -d $_GUILE_UDIR/lib/libguile.def -D $_GUILE_UDIR/bin/libguile.dll -l $_GUILE_UDIR/lib/libguile.lib
        fi
        # Also, for MSVC compiler we need to slightly modify the gc.h header
        GC_H=$_GUILE_UDIR/include/libguile/gc.h
        grep -v 'extern .*_freelist2;' ${GC_H} > ${GC_H}.tmp
        grep -v 'extern int scm_block_gc;' ${GC_H}.tmp > ${GC_H}
        cat >> ${GC_H} <<EOF
#ifdef _MSC_VER
# define LIBGUILEDECL __declspec (dllimport)
#else
# define LIBGUILEDECL /* */
#endif
extern LIBGUILEDECL SCM scm_freelist2;
extern LIBGUILEDECL struct scm_t_freelist scm_master_freelist2;
extern LIBGUILEDECL int scm_block_gc;
EOF
        rm -rf ${TMP_UDIR}/guile-*
    fi
    if [ "$CROSS_COMPILE" = "yes" ]; then
        mkdir -p $_GUILE_UDIR/bin
        qpushd $_GUILE_UDIR/bin
        # The cross-compiling guile expects these program names
        # for the build-time guile
        ln -sf /usr/bin/guile-config mingw32-guile-config
        ln -sf /usr/bin/guile mingw32-build-guile
        qpopd
    fi
    [ ! -d $_GUILE_UDIR/share/aclocal ] || add_to_env "-I $_GUILE_UDIR/share/aclocal" ACLOCAL_FLAGS
}

function inst_gwenhywfar() {
    setup Gwenhywfar
    _GWENHYWFAR_UDIR=`unix_path ${GWENHYWFAR_DIR}`
    add_to_env ${_GWENHYWFAR_UDIR}/bin PATH
    add_to_env ${_GWENHYWFAR_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --exact-version=${GWENHYWFAR_VERSION} gwenhywfar
    then
        echo "Gwenhywfar ${GWENHYWFAR_VERSION} already installed in $_GWENHYWFAR_UDIR. skipping."
    else
#        INSTALLED_GWEN=`${PKG_CONFIG} --modversion gwenhywfar`
#        echo "GWENHYWFAR installed version ${INSTALLED_GWEN} doesn't match required version ${GWENHYWFAR_VERSION}"
#        exit
        wget_unpacked $GWENHYWFAR_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/gwenhywfar-*
        qpushd $TMP_UDIR/gwenhywfar-*

            if [ -n "$GWEN_PATCH" -a -f "$GWEN_PATCH" ]; then
                patch -p1 < $GWEN_PATCH
            fi
            # circumvent binreloc bug, http://trac.autopackage.org/ticket/28
            # Note: gwenhywfar-3.x and higher don't use openssl anymore.
            ./configure ${HOST_XCOMPILE} \
                --with-libgcrypt-prefix=$_GNUTLS_UDIR \
                --disable-binreloc \
                --disable-ssl \
                --prefix=$_GWENHYWFAR_UDIR \
                --with-guis=gtk2 \
                CPPFLAGS="${GNOME_CPPFLAGS} ${GNUTLS_CPPFLAGS} `pkg-config --cflags gtk+-2.0`" \
                LDFLAGS="${GNOME_LDFLAGS} ${GNUTLS_LDFLAGS} -lintl"
            make
#            [ "$CROSS_COMPILE" != "yes" ] && make check
            rm -rf ${_GWENHYWFAR_UDIR}
            make install
        qpopd
#        fix_libtool_files ${_GWENHYWFAR_UDIR}
        ${PKG_CONFIG} --exists gwenhywfar || die "Gwenhywfar not installed correctly"
        rm -rf ${TMP_UDIR}/gwenhywfar-*
    fi
    [ ! -d $_GWENHYWFAR_UDIR/share/aclocal ] || add_to_env "-I $_GWENHYWFAR_UDIR/share/aclocal" ACLOCAL_FLAGS
}

function inst_isocodes() {
    setup isocodes
    _ISOCODES_UDIR=`unix_path ${ISOCODES_DIR}`
    add_to_env $_ISOCODES_UDIR/share/pkgconfig PKG_CONFIG_PATH
    if [ -f ${_ISOCODES_UDIR}/share/pkgconfig/iso-codes.pc ]
    then
        echo "isocodes already installed in $_ISOCODES_UDIR. skipping."
    else
        wget_unpacked $ISOCODES_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/iso-codes-*
        qpushd $TMP_UDIR/iso-codes-*
            ./configure ${HOST_XCOMPILE} \
                --prefix=${_ISOCODES_UDIR}
            make
            make install
        qpopd
        quiet [ -f ${_ISOCODES_UDIR}/share/pkgconfig/iso-codes.pc ] || die "isocodes not installed correctly"
        rm -rf ${TMP_UDIR}/iso-codes-*
    fi
}

function inst_ktoblzcheck() {
    setup Ktoblzcheck
    # Out of convenience ktoblzcheck is being installed into
    # GWENHYWFAR_DIR
    add_to_env "-I${_GWENHYWFAR_UDIR}/include" KTOBLZCHECK_CPPFLAGS
    add_to_env "-L${_GWENHYWFAR_UDIR}/lib" KTOBLZCHECK_LDFLAGS
    if quiet ${PKG_CONFIG} --exact-version=${KTOBLZCHECK_VERSION} ktoblzcheck
    then
        echo "Ktoblzcheck ${KTOBLZCHECK_VERSION} already installed in $_GWENHYWFAR_UDIR. skipping."
    else
        wget_unpacked $KTOBLZCHECK_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/ktoblzcheck-*
        qpushd $TMP_UDIR/ktoblzcheck-*
            # circumvent binreloc bug, http://trac.autopackage.org/ticket/28
            ./configure ${HOST_XCOMPILE} \
                --prefix=${_GWENHYWFAR_UDIR} \
                --disable-binreloc \
                --disable-python
            make
#            [ "$CROSS_COMPILE" != "yes" ] && make check
            make install
        qpopd
        ${PKG_CONFIG} --exists ktoblzcheck || die "Ktoblzcheck not installed correctly"
        rm -rf ${TMP_UDIR}/ktoblzcheck-*
    fi
}

function inst_libdbi() {
    setup LibDBI
    _SQLITE3_UDIR=`unix_path ${SQLITE3_DIR}`
    _MYSQL_LIB_UDIR=`unix_path ${MYSQL_LIB_DIR}`
    _PGSQL_UDIR=`unix_path ${PGSQL_DIR}`
    _LIBDBI_UDIR=`unix_path ${LIBDBI_DIR}`
    _LIBDBI_DRIVERS_UDIR=`unix_path ${LIBDBI_DRIVERS_DIR}`
    add_to_env -I$_LIBDBI_UDIR/include LIBDBI_CPPFLAGS
    add_to_env -L$_LIBDBI_UDIR/lib LIBDBI_LDFLAGS
    add_to_env -I${_SQLITE3_UDIR}/include SQLITE_CFLAGS
    add_to_env "-L${_SQLITE3_UDIR}/lib -lsqlite3" SQLITE_LIBS
    if test -f ${_SQLITE3_UDIR}/bin/libsqlite3-0.dll
    then
        echo "SQLite3 already installed in $_SQLITE3_UDIR.  skipping."
    else
        wget_unpacked $SQLITE3_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/sqlite-*
        qpushd $TMP_UDIR/sqlite-*
            autoreconf -if
            ./configure ${HOST_XCOMPILE} \
                --prefix=${_SQLITE3_UDIR}
            make
            make install
        qpopd
        test -f ${_SQLITE3_UDIR}/bin/libsqlite3-0.dll || die "SQLite3 not installed correctly"
        rm -rf ${TMP_UDIR}/sqlite-*
    fi
    if test -f ${_MYSQL_LIB_UDIR}/lib/libmysql.dll -a \
            -f ${_MYSQL_LIB_UDIR}/lib/libmysqlclient.a
    then
        echo "MySQL library already installed in $_MYSQL_LIB_UDIR.  skipping."
    else
        wget_unpacked $MYSQL_LIB_URL $DOWNLOAD_DIR $TMP_DIR
        mkdir -p $_MYSQL_LIB_UDIR
        assert_one_dir $TMP_UDIR/mysql*
        cp -r $TMP_UDIR/mysql*/* $_MYSQL_LIB_UDIR
        cp -r $TMP_UDIR/mysql*/include $_MYSQL_LIB_UDIR/include/mysql
        rm -rf ${TMP_UDIR}/mysql*
        qpushd $_MYSQL_LIB_UDIR/lib
        ${DLLTOOL} --input-def $LIBMYSQL_DEF --dllname libmysql.dll --output-lib libmysqlclient.a -k
        test -f ${_MYSQL_LIB_UDIR}/lib/libmysql.dll || die "mysql not installed correctly - libmysql.dll"
        test -f ${_MYSQL_LIB_UDIR}/lib/libmysqlclient.a || die "mysql not installed correctly - libmysqlclient.a"
        qpopd
    fi
    if test -f ${_PGSQL_UDIR}/lib/libpq.dll
    then
        echo "PGSQL library already installed in $_PGSQL_UDIR.  skipping."
    else
        wget_unpacked $PGSQL_LIB_URL $DOWNLOAD_DIR $TMP_DIR
        cp -r $TMP_UDIR/pgsql* $_PGSQL_UDIR
        rm -rf ${TMP_UDIR}/pgsql*
        test -f ${_PGSQL_UDIR}/lib/libpq.dll || die "libpq not installed correctly"
    fi
    if test -f ${_LIBDBI_UDIR}/bin/libdbi-1.dll
    then
        echo "libdbi already installed in $_LIBDBI_UDIR.  skipping."
    else
        wget_unpacked $LIBDBI_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/libdbi-0*
        qpushd $TMP_UDIR/libdbi-0*
            if [ -n "$LIBDBI_PATCH" -a -f "$LIBDBI_PATCH" ]; then
                patch -p1 < $LIBDBI_PATCH
            fi
            if [ "$CROSS_COMPILE" = "yes" ]; then
                rm -f ltmain.sh aclocal.m4
                libtoolize --force
                aclocal
                autoheader
                automake --add-missing
                autoconf
            fi
            ./configure ${HOST_XCOMPILE} \
                --disable-docs \
                --prefix=${_LIBDBI_UDIR}
            make
            make install
        qpopd
        qpushd ${_LIBDBI_UDIR}
        if [ x"$(which pexports.exe > /dev/null 2>&1)" != x ]
        then
            pexports bin/libdbi-1.dll > lib/libdbi.def
            ${DLLTOOL} -d lib/libdbi.def -D bin/libdbi-1.dll -l lib/libdbi.lib
        fi
        qpopd
        test -f ${_LIBDBI_UDIR}/bin/libdbi-1.dll || die "libdbi not installed correctly"
        rm -rf ${TMP_UDIR}/libdbi-0*
    fi
    if test -f ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/libdbdsqlite3.dll -a \
            -f ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/libdbdmysql.dll -a \
            -f ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/libdbdpgsql.dll
    then
        echo "libdbi drivers already installed in $_LIBDBI_DRIVERS_UDIR.  skipping."
    else
        wget_unpacked $LIBDBI_DRIVERS_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/libdbi-drivers-*
        qpushd $TMP_UDIR/libdbi-drivers*
            [ -n "$LIBDBI_DRIVERS_PATCH" -a -f "$LIBDBI_DRIVERS_PATCH" ] && \
                patch -p1 < $LIBDBI_DRIVERS_PATCH
            ./configure ${HOST_XCOMPILE} \
                --disable-docs \
                --with-dbi-incdir=${_LIBDBI_UDIR}/include \
                --with-dbi-libdir=${_LIBDBI_UDIR}/lib \
                --with-sqlite3 \
                --with-sqlite3-dir=${_SQLITE3_UDIR} \
                --with-mysql \
                --with-mysql-dir=${_MYSQL_LIB_UDIR} \
                --with-pgsql \
                --with-pgsql-dir=${_PGSQL_UDIR} \
                --prefix=${_LIBDBI_DRIVERS_UDIR}
            make LDFLAGS="$LDFLAGS -no-undefined"
            make install
        qpopd
        test -f ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/libdbdsqlite3.dll || die "libdbi sqlite3 driver not installed correctly"
        test -f ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/libdbdmysql.dll || die "libdbi mysql driver not installed correctly"
        test -f ${_LIBDBI_DRIVERS_UDIR}/lib/dbd/libdbdpgsql.dll || die "libdbi pgsql driver not installed correctly"
        rm -rf ${TMP_UDIR}/libdbi-drivers-*
    fi
}

function inst_libgsf() {
    setup libGSF
    _LIBGSF_UDIR=`unix_path $LIBGSF_DIR`
    add_to_env $_LIBGSF_UDIR/bin PATH
    add_to_env $_LIBGSF_UDIR/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --exists libgsf-1 &&
        quiet ${PKG_CONFIG} --atleast-version=${LIBGSF_VERSION} libgsf-1
    then
        echo "libgsf already installed in $_LIBGSF_UDIR.  skipping."
    else
        rm -rf ${TMP_UDIR}/libgsf-*
        wget_unpacked $LIBGSF_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/libgsf-*
        qpushd $TMP_UDIR/libgsf-*
            ./configure ${HOST_XCOMPILE} \
                --prefix=$_LIBGSF_UDIR \
                --disable-static \
                --without-python \
                CPPFLAGS="${GNOME_CPPFLAGS}" \
                LDFLAGS="${GNOME_LDFLAGS}"
            make
            rm -rf ${_LIBGSF_UDIR}
            make install
        qpopd
        ${PKG_CONFIG} --exists libgsf-1 || die "libgsf not installed correctly: No libgsf-1"
        #${PKG_CONFIG} --exists libgsf-gnome-1 || die "libgsf not installed correctly: No libgsf-gnome-1"
    fi
}

function inst_libofx() {
    setup Libofx
    _LIBOFX_UDIR=`unix_path ${LIBOFX_DIR}`
    add_to_env ${_LIBOFX_UDIR}/bin PATH
    add_to_env ${_LIBOFX_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --exists libofx && quiet ${PKG_CONFIG} --atleast-version=${LIBOFX_VERSION} libofx
    then
        echo "Libofx already installed in $_LIBOFX_UDIR. skipping."
    else
        wget_unpacked $LIBOFX_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/libofx-*
        qpushd $TMP_UDIR/libofx-*
            if [ -n "$LIBOFX_PATCH" -a -f "$LIBOFX_PATCH" ]; then
                patch -p1 < $LIBOFX_PATCH
#                libtoolize --force
#                aclocal ${ACLOCAL_FLAGS}
#                automake
#                autoconf
#                ACLOCAL="aclocal $ACLOCAL_FLAGS" autoreconf -fvi $ACLOCAL_FLAGS
            fi
            ./configure ${HOST_XCOMPILE} \
                --prefix=${_LIBOFX_UDIR} \
                --with-opensp-includes=${_OPENSP_UDIR}/include/OpenSP \
                --with-opensp-libs=${_OPENSP_UDIR}/lib \
                CPPFLAGS="-DOS_WIN32 ${GNOME_CPPFLAGS}" \
                --disable-static \
                --with-iconv=${_GNOME_UDIR}
            make LDFLAGS="${LDFLAGS} -no-undefined ${GNOME_LDFLAGS} -liconv"
            make install
        qpopd
        quiet ${PKG_CONFIG} --exists libofx || die "Libofx not installed correctly"
        rm -rf ${TMP_UDIR}/libofx-*
    fi
}

#Building LibSoup requires python. Setting $PYTHON isn't sufficient, it must be on the path.
function inst_libsoup() {
    setup libsoup
    _LIBSOUP_UDIR=`unix_path $LIBSOUP_DIR`
    add_to_env $_LIBSOUP_UDIR/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --exists libsoup-2.4
    then
        echo "libsoup already installed in $_LIBSOUP_UDIR.  skipping."
    else
        if [ "$BUILD_LIBSOUP_FROM_SOURCE" = "yes" ]; then
            wget_unpacked $LIBSOUP_SRC_URL $DOWNLOAD_DIR $TMP_DIR
            assert_one_dir $TMP_UDIR/libsoup-*
            qpushd $TMP_UDIR/libsoup-*
            	patch -p1 < $LIBSOUP_BAD_SYMBOL_PATCH
            	patch -p1 < $LIBSOUP_RESERVED_WORD_PATCH
                ./configure ${HOST_XCOMPILE} \
                    --prefix=${_LIBSOUP_UDIR} \
                    --disable-gtk-doc \
                    --without-gnome \
                    CPPFLAGS=-I${_GNOME_UDIR}/include \
                    LDFLAGS="-L${_GNOME_UDIR}/lib -Wl,-s -lz"
                make
                make install
            qpopd
       else
            mkdir -p $_LIBSOUP_UDIR
            wget_unpacked $LIBSOUP_URL $DOWNLOAD_DIR $LIBSOUP_DIR
            wget_unpacked $LIBSOUP_DEV_URL $DOWNLOAD_DIR $LIBSOUP_DIR
            fix_libtool_files ${_LIBSOUP_UDIR}
        fi
        quiet ${PKG_CONFIG} --exists libsoup-2.4 || die "libsoup not installed correctly"
        rm -rf ${TMP_UDIR}/libsoup-*
    fi
    LIBSOUP_CPPFLAGS=`${PKG_CONFIG} --cflags libsoup-2.4`
}

function inst_libxslt() {
    setup LibXSLT
    _LIBXSLT_UDIR=`unix_path $LIBXSLT_DIR`
    add_to_env $_LIBXSLT_UDIR/bin PATH
    add_to_env $_LIBXSLT_UDIR/lib/pkgconfig PKG_CONFIG_PATH
    add_to_env -L${_LIBXSLT_UDIR}/lib LIBXSLT_LDFLAGS
    if quiet which xsltproc &&
        quiet ${PKG_CONFIG} --atleast-version=${LIBXSLT_VERSION} libxslt
    then
        echo "libxslt already installed in $_LIBXSLT_UDIR.  skipping."
    else
        #wget_unpacked ${LIBXSLT_ICONV_URL} ${DOWNLOAD_DIR} ${LIBXSLT_DIR}
        #wget_unpacked ${LIBXSLT_ZLIB_URL} ${DOWNLOAD_DIR} ${LIBXSLT_DIR}

        wget_unpacked $LIBXSLT_SRC_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/libxslt-*
        qpushd $TMP_UDIR/libxslt-*
            if [ -n "$LIBXSLT_MAKEFILE_PATCH" -a -f "$LIBXSLT_MAKEFILE_PATCH" ]; then
                patch -p0 -u -i ${LIBXSLT_MAKEFILE_PATCH}
            fi
            ./configure ${HOST_XCOMPILE} \
                --prefix=${_LIBXSLT_UDIR} \
                --with-python=no \
                --with-libxml-prefix=${_GNOME_UDIR} \
                CPPFLAGS="${GNOME_CPPFLAGS} ${GNUTLS_CPPFLAGS}" \
                LDFLAGS="${GNOME_LDFLAGS} ${GNUTLS_LDFLAGS}"
            make
            make install
        qpopd
        rm -rf ${TMP_UDIR}/libxslt-*

        quiet which xsltproc || die "libxslt not installed correctly"
    fi
}

function inst_opensp() {
    setup OpenSP
    _OPENSP_UDIR=`unix_path ${OPENSP_DIR}`
    add_to_env ${_OPENSP_UDIR}/bin PATH
    if test -f ${_OPENSP_UDIR}/bin/libosp-5.dll
    then
        echo "OpenSP already installed in $_OPENSP_UDIR. skipping."
    else
        wget_unpacked $OPENSP_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/OpenSP-*
        qpushd $TMP_UDIR/OpenSP-*
            [ -n "$OPENSP_PATCH" -a -f "$OPENSP_PATCH" ] && \
                patch -p0 < $OPENSP_PATCH
            libtoolize --force
            aclocal ${ACLOCAL_FLAGS} -I m4
            automake
            autoconf
            ./configure ${HOST_XCOMPILE} \
                --prefix=${_OPENSP_UDIR} \
                --disable-doc-build --disable-static
            # On many windows machines, none of the programs will
            # build, but we only need the library, so ignore the rest.
            make all-am
            make -C lib
            make -i
            make -i install
        qpopd
        test -f ${_OPENSP_UDIR}/bin/libosp-5.dll || die "OpenSP not installed correctly"
        rm -rf $TMP_UDIR/OpenSP-*
    fi
}

function inst_openssl() {
    setup OpenSSL
    _OPENSSL_UDIR=`unix_path $OPENSSL_DIR`
    add_to_env $_OPENSSL_UDIR/bin PATH
    # Make sure the files of Win32OpenSSL-0_9_8d are really gone!
    if test -f $_OPENSSL_UDIR/unins000.exe ; then
        die "Wrong version of OpenSSL installed! Run $_OPENSSL_UDIR/unins000.exe and start install.sh again."
    fi
    # Make sure the files of openssl-0.9.7c-{bin,lib}.zip are really gone!
    if [ -f $_OPENSSL_UDIR/lib/libcrypto.dll.a ] ; then
        die "Found old OpenSSL installation in $_OPENSSL_UDIR.  Please remove that first."
    fi

    if quiet ${LD} -L$_OPENSSL_UDIR/lib -leay32 -lssl32 -o $TMP_UDIR/ofile ; then
        echo "openssl already installed in $_OPENSSL_UDIR.  skipping."
    else
        smart_wget $OPENSSL_URL $DOWNLOAD_DIR
        echo -n "Extracting ${LAST_FILE##*/} ... "
        tar -xzpf $LAST_FILE -C $TMP_UDIR &>/dev/null | true
        echo "done"
        assert_one_dir $TMP_UDIR/openssl-*
        qpushd $TMP_UDIR/openssl-*
            for _dir in crypto ssl ; do
                qpushd $_dir
                    find . -name "*.h" -exec cp {} ../include/openssl/ \;
                qpopd
            done
            cp *.h include/openssl
            _COMSPEC_U=`unix_path $COMSPEC`
            PATH=$_ACTIVE_PERL_UDIR/ActivePerl/Perl/bin:$_MINGW_UDIR/bin $_COMSPEC_U //c ms\\mingw32
            mkdir -p $_OPENSSL_UDIR/bin
            mkdir -p $_OPENSSL_UDIR/lib
            mkdir -p $_OPENSSL_UDIR/include
            cp -a libeay32.dll libssl32.dll $_OPENSSL_UDIR/bin
            cp -a libssl32.dll $_OPENSSL_UDIR/bin/ssleay32.dll
            for _implib in libeay32 libssl32 ; do
                cp -a out/$_implib.a $_OPENSSL_UDIR/lib/$_implib.dll.a
            done
            cp -a include/openssl $_OPENSSL_UDIR/include
        qpopd
        quiet ${LD} -L$_OPENSSL_UDIR/lib -leay32 -lssl32 -o $TMP_UDIR/ofile || die "openssl not installed correctly"
        rm -rf ${TMP_UDIR}/openssl-*
    fi
    _eay32dll=$(echo $(which libeay32.dll))  # which sucks
    if [ -z "$_eay32dll" ] ; then
        die "Did not find libeay32.dll in your PATH, why that?"
    fi
    if [ "$_eay32dll" != "$_OPENSSL_UDIR/bin/libeay32.dll" ] ; then
        die "Found $_eay32dll in PATH.  If you have added $_OPENSSL_UDIR/bin to your PATH before, make sure it is listed before paths from other packages shipping SSL libraries.  In particular, check $_MINGW_UDIR/etc/profile.d/installer.sh."
    fi
}

function inst_pcre() {
    setup pcre
    _PCRE_UDIR=`unix_path $PCRE_DIR`
    add_to_env -I$_PCRE_UDIR/include PCRE_CPPFLAGS
    add_to_env -L$_PCRE_UDIR/lib PCRE_LDFLAGS
    add_to_env $_PCRE_UDIR/bin PATH
    if quiet ${LD} $PCRE_LDFLAGS -lpcre -o $TMP_UDIR/ofile
    then
        echo "pcre already installed in $_PCRE_UDIR.  skipping."
    else
        mkdir -p $_PCRE_UDIR
        wget_unpacked $PCRE_BIN_URL $DOWNLOAD_DIR $PCRE_DIR
        wget_unpacked $PCRE_LIB_URL $DOWNLOAD_DIR $PCRE_DIR
    fi
    quiet ${LD} $PCRE_LDFLAGS -lpcre -o $TMP_UDIR/ofile || die "pcre not installed correctly"
}

function inst_readline() {
    setup Readline
    _READLINE_UDIR=`unix_path $READLINE_DIR`
    add_to_env -I$_READLINE_UDIR/include READLINE_CPPFLAGS
    add_to_env -L$_READLINE_UDIR/lib READLINE_LDFLAGS
    add_to_env $_READLINE_UDIR/bin PATH
    if quiet ${LD} $READLINE_LDFLAGS -lreadline -o $TMP_UDIR/ofile
    then
        echo "readline already installed in $_READLINE_UDIR.  skipping."
    else
        mkdir -p $_READLINE_UDIR
        wget_unpacked $READLINE_BIN_URL $DOWNLOAD_DIR $READLINE_DIR
        wget_unpacked $READLINE_LIB_URL $DOWNLOAD_DIR $READLINE_DIR
        quiet ${LD} $READLINE_LDFLAGS -lreadline -o $TMP_UDIR/ofile || die "readline not installed correctly"
    fi
}

function inst_regex() {
    setup RegEx
    _REGEX_UDIR=`unix_path $REGEX_DIR`
    add_to_env -lregex REGEX_LDFLAGS
    add_to_env -I$_REGEX_UDIR/include REGEX_CPPFLAGS
    add_to_env -L$_REGEX_UDIR/lib REGEX_LDFLAGS
    add_to_env $_REGEX_UDIR/bin PATH
    if quiet ${LD} $REGEX_LDFLAGS -o $TMP_UDIR/ofile
    then
        echo "regex already installed in $_REGEX_UDIR.  skipping."
    else
        mkdir -p $_REGEX_UDIR
        wget_unpacked $REGEX_URL $DOWNLOAD_DIR $REGEX_DIR
        wget_unpacked $REGEX_DEV_URL $DOWNLOAD_DIR $REGEX_DIR
        quiet ${LD} $REGEX_LDFLAGS -o $TMP_UDIR/ofile || die "regex not installed correctly"
    fi
}

#To build webkit from source you need an extra dependency, gperf. You
#can most easily get it from
#http://gnuwin32.sourceforge.net/packages.html; install it in
#c:\Programs\GnuWin32.
#You also need python 2.6+ and ICU 50+
#Setting $PYTHON isn't sufficient, it must be on the path.
#Make sure that $CC is set, otherwise the perl modules will try to use /usr/bin/gcc which doesn't exist.
#Build ICU and install it in /c/gcdev/webkit. Symlink icu*.dll to libicu*.dll.
#
#After building and before installing, make the following changes to
#$(top_builddir)/Source/WebKit/gtk/webkit-1.0.pc:
#${prefix}/lib -> ${prefix}/bin
#Libs: ${libdir} -lwebkitgtk-1.0 -> Libs: ${libdir} -lwebkitgtk-1.0-0
#
function inst_webkit() {
    setup WebKit
    _WEBKIT_UDIR=`unix_path ${WEBKIT_DIR}`
    add_to_env ${_WEBKIT_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
    if quiet ${PKG_CONFIG} --exists webkit-1.0 &&
        quiet ${PKG_CONFIG} --atleast-version=${WEBKIT_VERSION} webkit-1.0
    then
        echo "webkit already installed in $_WEBKIT_UDIR.  skipping."
    else
        if [ "$BUILD_WEBKIT_FROM_SOURCE" = "yes" ]; then
            wget_unpacked $WEBKIT_SRC_URL $DOWNLOAD_DIR $TMP_DIR
            assert_one_dir ${TMP_UDIR}/webkit-*
            qpushd $TMP_UDIR/webkit-*
                add_to_env /c/Programs/GnuWin32/bin PATH
                SAVED_PATH=$PATH
                add_to_env ${_ACTIVE_PERL_BASE_DIR}/bin PATH
                export PERL5LIB=${_ACTIVE_PERL_BASE_DIR}/lib

                patch -p1 -u < $WEBKIT_MINGW_PATCH_1
                patch -p1 -u < $WEBKIT_MINGW_PATCH_2
                autoreconf -fis -ISource/autotools -I$GNOME_DIR/share/aclocal
                ./configure \
                    --prefix=${_WEBKIT_UDIR} \
                    --with-target=win32 \
                    --with-gtk=2.0 \
                    --disable-geolocation \
                    --enable-web-sockets \
                    --disable-video \
                CPPFLAGS="${GNOME_CPPFLAGS} ${SQLITE_CFLAGS}" \
                LDFLAGS="${GNOME_LDFLAGS} ${SQLITE_LIBS}" \
                PERL="${_ACTIVE_PERL_BASE_DIR}/bin/perl"
                cp $WEBKIT_WEBKITENUMTYPES_CPP DerivedSources
                cp $WEBKIT_WEBKITENUMTYPES_H Webkit/gtk/webkit
                make
                make install
                PATH=$SAVED_PATH
            qpopd
        else
            mkdir -p $_WEBKIT_UDIR
            wget_unpacked $WEBKIT_URL $DOWNLOAD_DIR $WEBKIT_DIR
            wget_unpacked $WEBKIT_DEV_URL $DOWNLOAD_DIR $WEBKIT_DIR
            fix_libtool_files ${_WEBKIT_UDIR}
        fi
        quiet ${PKG_CONFIG} --exists webkit-1.0 || die "webkit not installed correctly"
        rm -rf ${TMP_UDIR}/webkit-*

        qpushd $_WEBKIT_UDIR/lib/pkgconfig
            perl -pi.bak -e"s!^prefix=.*\$!prefix=$_WEBKIT_UDIR!" *.pc
        qpopd
    fi
}

function inst_inno() {
    setup Inno Setup Compiler
    _INNO_UDIR=`unix_path $INNO_DIR`
    add_to_env $_INNO_UDIR PATH
    if quiet which iscc
    then
        echo "Inno Setup Compiler already installed in $_INNO_UDIR.  skipping."
    else
        smart_wget $INNO_URL $DOWNLOAD_DIR
        $LAST_FILE //SP- //SILENT //DIR="$INNO_DIR"
        quiet which iscc || die "iscc (Inno Setup Compiler) not installed correctly"
    fi
}

function test_for_hh() {
    qpushd $TMP_UDIR
        cat > ofile.c <<EOF
#include <windows.h>
#include <htmlhelp.h>
int main(int argc, char **argv) {
  HtmlHelpW(0, (wchar_t*)"", HH_HELP_CONTEXT, 0);
  return 0;
}
EOF
        gcc -shared -o ofile.dll ofile.c "$HH_CPPFLAGS" "$HH_LDFLAGS" -lhtmlhelp || return 1
        rm ofile*
    qpopd
}

function inst_hh() {
    setup HTML Help Workshop
    HH_SYS_DIR=$(cscript //nologo get-install-path.vbs)
    if [ -z "$HH_SYS_DIR" ]; then
        smart_wget $HH_URL $DOWNLOAD_DIR
        echo "!!! Attention !!!"
        echo "!!! This is the only installation step that requires your direct input !!!"
        echo "!!! Contray to older installation scripts the HtmlHelp Workshop should !!!"
        echo "!!! no longer be installed in $HH_DIR !!!"
        echo "!!! When asked for an installation path, DO NOT specify $HH_DIR !!!"
        CMD=$(basename "$LAST_FILE")
        cscript //nologo run-as-admin.vbs $CMD "" "$DOWNLOAD_DIR"
        HH_SYS_DIR=$(cscript //nologo get-install-path.vbs)
        if [ -z "$HH_SYS_DIR" ]; then
            die "HTML Help Workshop not installed correctly (Windows installer failed for some reason)"
        fi
    fi

    _HH_UDIR=`unix_path $HH_DIR`
    _HH_SYS_UDIR="`unix_path $HH_SYS_DIR`"
    if [ "$_HH_UDIR" = "$_HH_SYS_UDIR" ]; then
        echo "Warning: Installing HTML Help Workshop inside the gnucash development directory is no longer recommended."
        echo "         The script will proceed in $HH_DIR\\mingw for now."
        echo "         To fix this for future safety, you should"
        echo "         - uninstall HTML Help Workshop"
        echo "         - delete directory $HH_DIR and all of its remaining content"
        echo "         - rerun install.sh"
        echo
        _HH_UDIR="$_HH_UDIR/mingw"
    fi

    add_to_env -I$_HH_UDIR/include HH_CPPFLAGS
    add_to_env -L$_HH_UDIR/lib HH_LDFLAGS
    add_to_env "$_HH_SYS_UDIR" PATH
    if quiet test_for_hh
    then
        echo "html help workshop already installed in $_HH_UDIR.  skipping."
    else
        mkdir -p $_HH_UDIR/{include,lib}
        _HHCTRL_OCX=$(which hhctrl.ocx || true)
        [ "$_HHCTRL_OCX" ] || die "Did not find hhctrl.ocx"
        cp "$_HH_SYS_UDIR/include/htmlhelp.h" $_HH_UDIR/include
        qpushd "$_HH_UDIR"
            pexports -h include/htmlhelp.h $_HHCTRL_OCX > $_HH_UDIR/lib/htmlhelp.def
        qpopd
        qpushd $_HH_UDIR/lib
            ${DLLTOOL} -k -d htmlhelp.def -l libhtmlhelp.a
        qpopd
        test_for_hh || die "HTML Help Workshop not installed correctly (link test failed)"
    fi
}


function inst_icu4c() {
    setup icu4c
    _ICU4C_UDIR=`unix_path $ICU4C_DIR`
    if [ -f "$_ICU4C_UDIR/lib/libicuuc.dll.a" ]
    then
        echo "icu4c already installed.  Skipping."
    else
        wget_unpacked $ICU4C_SRC_URL $DOWNLOAD_DIR $TMP_DIR
#        qpushd $TMP_UDIR/icu
#            patch -p1 < $ICU4C_PATCH
        #        qpopd
        mkdir $TMP_UDIR/icu/build
        qpushd $TMP_UDIR/icu/build
        ../source/configure --prefix ${_ICU4C_UDIR} \
                   --disable-strict \
                   --disable-extras \
                   --disable-layout \
                   --disable-layoutex \
                   --disable-tests \
                   --disable-samples \
                   CPPFLAGS="${CPPFLAGS} -DU_CHARSET_IS_UTF8=1 -DU_NO_DEFAULT_INCLUDE_UTF_HEADERS=1 -DU_USING_ICU_NAMESPACE=0" \
                   CXXFLAGS="${CXXFLAGS} -std=gnu++11"

            make V=0
            make install V=0
            ln ${_ICU4C_UDIR}/lib/libicudt.dll.a ${_ICU4C_UDIR}/lib/libicudata.dll.a
            ln ${_ICU4C_UDIR}/lib/libicuin.dll.a ${_ICU4C_UDIR}/lib/libicui18n.dll.a
        qpopd
       # cleanup
        rm -rf $TMP_UDIR/icu*
    fi
    add_to_env ${_ICU4C_UDIR}/lib PATH
    add_to_env ${_ICU4C_UDIR}/lib/pkgconfig PKG_CONFIG_PATH
}

function inst_boost() {
    setup Boost
    get_major_minor "$GNUCASH_SCM_REV"
    if [ "$GNUCASH_SCM_REV" != "master" ] &&
        (( $major_minor <= 206 )); then
        echo "Skipping. Boost is only needed for the master branch or future 2.7.x and up versions of gnucash."
        return
    fi
    _BOOST_UDIR=`unix_path ${BOOST_DIR}`
    _ICU4C_WDIR=`win_fs_path ${ICU4C_DIR}`
    # The boost m4 macro included with gnucash looks for boost in either
    # $BOOST_ROOT/staging (useless here) or $ac_boost_path, while the cmake build
    # looks in $BOOST_ROOT. So we set both to support both build systems.
    set_env ${_BOOST_UDIR} BOOST_ROOT
    set_env ${_BOOST_UDIR} ac_boost_path
    export BOOST_ROOT ac_boost_path
    add_to_env ${_BOOST_UDIR}/lib PATH
    if test -f ${_BOOST_UDIR}/lib/libboost_date_time.dll
    then
        echo "Boost already installed in $_BOOST_UDIR. skipping."
    else
        wget_unpacked $BOOST_URL $DOWNLOAD_DIR $TMP_DIR
        assert_one_dir $TMP_UDIR/boost_*
        qpushd $TMP_UDIR/boost_*
        ./bootstrap.sh --with-toolset=mingw \
                       --prefix=${_BOOST_UDIR} \
                       --with-icu=${_ICU4C_WDIR} \
                       --with-libraries=${BOOST_LIBS}
        sed -i"" "s/mingw /gcc /" project-config.jam
        ./b2 --prefix=${_BOOST_UDIR} --layout=system \
             link=shared variant=release \
             -sICU_PATH=${_ICU4C_WDIR} \
             install
        qpopd
        test -f ${_BOOST_UDIR}/lib/libboost_date_time.dll || die "Boost not installed correctly"
        rm -rf $TMP_UDIR/boost_*
    fi
}

function inst_gtest() {
    setup Google Test Framework
    get_major_minor "$GNUCASH_SCM_REV"
    if [ "$GNUCASH_SCM_REV" != "master" ] &&
        (( $major_minor <= 206 )); then
        echo "Skipping. The Google test framework is only needed for the master branch or future 2.7.x and up versions of gnucash."
        return
    fi

    _GTEST_UDIR=`unix_path ${GTEST_DIR}`
    set_env ${_GTEST_UDIR}/googletest GTEST_ROOT
    set_env ${_GTEST_UDIR}/googlemock GMOCK_ROOT
    export GTEST_ROOT GMOCK_ROOT
    if [ -f ${GTEST_ROOT}/src/gtest-all.cc ] &&
       [ -f ${GTEST_ROOT}/include/gtest/gtest.h ] &&
       [ -f ${GMOCK_ROOT}/src/gmock-all.cc ] &&
       [ -f ${GMOCK_ROOT}/include/gmock/gmock.h ]
    then
        echo "Google test framework already installed in ${_GTEST_UDIR}. skipping."
    else
        rm -fr ${_GTEST_UDIR}
        $GIT_CMD clone $GTEST_REPO -b $GTEST_VERSION ${_GTEST_UDIR}

        ([ -f ${GTEST_ROOT}/src/gtest-all.cc ] &&
         [ -f ${GTEST_ROOT}/include/gtest/gtest.h ] &&
         [ -f ${GMOCK_ROOT}/src/gmock-all.cc ] &&
         [ -f ${GMOCK_ROOT}/include/gmock/gmock.h ]) || die "Google test framework not installed correctly"
    fi
}

function inst_cutecash() {
    setup Cutecash
    _BUILD_UDIR=`unix_path $CUTECASH_BUILD_DIR`
    _REPOS_UDIR=`unix_path $REPOS_DIR`
    mkdir -p $_BUILD_UDIR

    qpushd $_BUILD_UDIR
        cmake ${_REPOS_UDIR} \
            -G"MSYS Makefiles" \
            -DREGEX_INCLUDE_PATH=${_REGEX_UDIR}/include \
            -DREGEX_LIBRARY=${_REGEX_UDIR}/lib/libregex.a \
            -DGUILE_INCLUDE_DIR=${_GUILE_UDIR}/include \
            -DGUILE_LIBRARY=${_GUILE_UDIR}/bin/libguile.dll \
            -DLIBINTL_INCLUDE_PATH=${_GNOME_UDIR}/include \
            -DLIBINTL_LIBRARY=${_GNOME_UDIR}/bin/intl.dll \
            -DLIBXML2_INCLUDE_DIR=${_GNOME_UDIR}/include/libxml2 \
            -DLIBXML2_LIBRARIES=${_GNOME_UDIR}/bin/libxml2-2.dll \
            -DPKG_CONFIG_EXECUTABLE=${_GNOME_UDIR}/bin/pkg-config \
            -DZLIB_INCLUDE_DIR=${_GNOME_UDIR}/include \
            -DZLIB_LIBRARY=${_GNOME_UDIR}/bin/zlib1.dll \
            -DSWIG_EXECUTABLE=${_SWIG_UDIR}/swig.exe \
            -DHTMLHELP_INCLUDE_PATH=${_HH_UDIR}/include \
            -DWITH_SQL=ON \
            -DLIBDBI_INCLUDE_PATH=${_LIBDBI_UDIR}/include \
            -DLIBDBI_LIBRARY=${_LIBDBI_UDIR}/lib/libdbi.dll.a \
            -DCMAKE_BUILD_TYPE=Debug
        make
    qpopd
}

function inst_gnucash_using_cmake() {
    setup "Gnucash (using cmake)"
    _INSTALL_UDIR=`unix_path $INSTALL_DIR`
    _BUILD_UDIR=`unix_path  $BUILD_DIR`
    _GLOBAL_UDIR=`unix_path $GLOBAL_DIR`
    _REPOS_UDIR=`unix_path  $REPOS_DIR`
    _NINJA_UDIR=`unix_path  $NINJA_DIR`
    _MSYS_UDIR=`unix_path   $MSYS_DIR`
    _HH_UDIR=`unix_path     $HH_DIR`
    _LIBDBI_DRIVERS_UDIR=`unix_path ${LIBDBI_DRIVERS_DIR}`
    
    mkdir -p $_BUILD_UDIR

    # Remove existing INSTALL_UDIR
    if [ -x $_INSTALL_UDIR ]; then
        echo Removing previous inst dir $_INSTALL_UDIR ...
        rm -rf "$_INSTALL_UDIR"
    fi;

    add_to_env $_INSTALL_UDIR/bin PATH

    if [ "$BUILD_FROM_TARBALL" != "yes" ]; then
        qpushd $REPOS_DIR
            $GIT_CMD checkout $GNUCASH_SCM_REV
        qpopd
    fi

    _CMAKE_MAKE_PROGRAM=$_MSYS_UDIR/bin/make
    if [ "$CMAKE_GENERATOR" = "Ninja" ]; then
        _CMAKE_MAKE_PROGRAM=$_NINJA_UDIR/ninja.exe
    fi
    qpushd $_BUILD_UDIR
         if [ -f CMakeCache.txt ]; then
             rm CMakeCache.txt
         fi
         cmake -G "$CMAKE_GENERATOR" \
               -D CMAKE_INSTALL_PREFIX=${_INSTALL_UDIR} \
               -D CMAKE_PREFIX_PATH=${_GLOBAL_UDIR} \
               -D PERL_EXECUTABLE=${_MSYS_UDIR}/bin/perl \
               -D CMAKE_MAKE_PROGRAM=${_CMAKE_MAKE_PROGRAM} \
               -D GNC_DBD_DIR=${_LIBDBI_DRIVERS_UDIR}/lib/dbd \
	       -D HTMLHELP_DIR=${_HH_UDIR} \
               ${_REPOS_UDIR}
          ${_CMAKE_MAKE_PROGRAM} install
     qpopd
}

function inst_gnucash() {
    setup GnuCash
    _INSTALL_WFSDIR=`win_fs_path $INSTALL_DIR`
    _INSTALL_UDIR=`unix_path $INSTALL_DIR`
    _BUILD_UDIR=`unix_path $BUILD_DIR`
    _REPOS_UDIR=`unix_path $REPOS_DIR`
    mkdir -p $_BUILD_UDIR
    add_to_env $_INSTALL_UDIR/bin PATH

    AQBANKING_OPTIONS="--enable-aqbanking"
    AQBANKING_UPATH="${_OPENSSL_UDIR}/bin:${_GWENHYWFAR_UDIR}/bin:${_AQBANKING_UDIR}/bin"
    LIBOFX_OPTIONS="--enable-ofx"

    if [ "$BUILD_FROM_TARBALL" != "yes" ]; then
        qpushd $REPOS_DIR
            $GIT_CMD checkout $GNUCASH_SCM_REV
            ./autogen.sh
        qpopd
    fi

    qpushd $_BUILD_UDIR
        $_REPOS_UDIR/configure ${HOST_XCOMPILE} \
            --prefix=$_INSTALL_WFSDIR \
            --enable-debug \
            --enable-dbi \
            --with-dbi-dbd-dir=$( echo ${_LIBDBI_DRIVERS_UDIR} | sed 's,^/\([A-Za-z]\)/,\1:/,g' )/lib/dbd \
            ${LIBOFX_OPTIONS} \
            ${AQBANKING_OPTIONS} \
            --enable-binreloc \
            --enable-locale-specific-tax \
            CPPFLAGS="${REGEX_CPPFLAGS} ${GNOME_CPPFLAGS} ${GUILE_CPPFLAGS} ${LIBDBI_CPPFLAGS} ${KTOBLZCHECK_CPPFLAGS} ${HH_CPPFLAGS} ${LIBSOUP_CPPFLAGS} -D_WIN32 ${EXTRA_CFLAGS}" \
            LDFLAGS="${REGEX_LDFLAGS} ${GNOME_LDFLAGS} ${GUILE_LDFLAGS} ${LIBDBI_LDFLAGS} ${KTOBLZCHECK_LDFLAGS} ${HH_LDFLAGS} -L${_SQLITE3_UDIR}/lib -L${_ENCHANT_UDIR}/lib -L${_LIBXSLT_UDIR}/lib" \
            PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"

        make

        make_install
    qpopd
}

# This function will be called by make_install.sh as well,
# so do not regard variables from inst_* functions as set
# Parameters allowed: skip_scripts
function make_install() {
    _BUILD_UDIR=`unix_path $BUILD_DIR`
    _INSTALL_UDIR=`unix_path $INSTALL_DIR`
    _GOFFICE_UDIR=`unix_path $GOFFICE_DIR`
    _LIBGSF_UDIR=`unix_path $LIBGSF_DIR`
    _PCRE_UDIR=`unix_path $PCRE_DIR`
    _GNOME_UDIR=`unix_path $GNOME_DIR`
    _GUILE_UDIR=`unix_path $GUILE_DIR`
    _REGEX_UDIR=`unix_path $REGEX_DIR`
    _OPENSSL_UDIR=`unix_path $OPENSSL_DIR`
    _GWENHYWFAR_UDIR=`unix_path ${GWENHYWFAR_DIR}`
    _AQBANKING_UDIR=`unix_path ${AQBANKING_DIR}`
    _LIBOFX_UDIR=`unix_path ${LIBOFX_DIR}`
    _OPENSP_UDIR=`unix_path ${OPENSP_DIR}`
    _LIBDBI_UDIR=`unix_path ${LIBDBI_DIR}`
    _SQLITE3_UDIR=`unix_path ${SQLITE3_DIR}`
    _WEBKIT_UDIR=`unix_path ${WEBKIT_DIR}`
    _GNUTLS_UDIR=`unix_path ${GNUTLS_DIR}`
    AQBANKING_UPATH="${_OPENSSL_UDIR}/bin:${_GWENHYWFAR_UDIR}/bin:${_AQBANKING_UDIR}/bin"
    AQBANKING_PATH="${OPENSSL_DIR}\\bin;${GWENHYWFAR_DIR}\\bin;${AQBANKING_DIR}\\bin"

    for param in "$@"; do
        [ "$param" = "skip_scripts" ] && _skip_scripts=1
    done

    make install

    qpushd $_INSTALL_UDIR/bin
        if [ ! -f $_MINGW_UDIR/bin/libstdc++-6.dll ] ; then die "File $_MINGW_UDIR/bin/libstdc++-6.dll is missing.  Install step unavailable in cross-compile." ; fi

        # Copy libstdc++-6.dll and its dependency to gnucash bin directory
        # to prevent DLL loading errors
        # (__gxx_personality_v0 not found in libstdc++-6.dll)
        cp $_MINGW_UDIR/bin/{libstdc++-6.dll,libgcc_s_dw2-1.dll} .
    qpopd

    qpushd $_INSTALL_UDIR/lib
        # Move modules that are compiled without -module to lib/gnucash and
        # correct the 'dlname' in the libtool archives. We do not use these
        # files to dlopen the modules, so actually this is unneeded.
        # Also, in all installed .la files, remove the dependency_libs line
        mv bin/*.dll gnucash/*.dll $_INSTALL_UDIR/bin 2>/dev/null || true
        for A in gnucash/*.la; do
            sed '/dependency_libs/d;s#../bin/##' $A > tmp ; mv tmp $A
        done
        for A in *.la; do
            sed '/dependency_libs/d' $A > tmp ; mv tmp $A
        done
    qpopd

    if [ -z $_skip_scripts ]; then
        # Create a startup script that works without the msys shell
        # If you make any changes here, you should probably also change
        # the equivalent sections in inno_setup/gnucash.iss, and
        # (in the gnucash source repository) src/bin/environment*.in
        qpushd $_INSTALL_UDIR/bin
            cat > gnucash-launcher.cmd <<EOF
@echo off
setlocal
set PATH=$INSTALL_DIR\\bin;%PATH%
set PATH=$INSTALL_DIR\\lib;%PATH%
set PATH=$INSTALL_DIR\\lib\\gnucash;%PATH%
set PATH=$BOOST_DIR\\lib;%PATH%
set PATH=$GNUTLS_DIR\\bin;%PATH%
set PATH=$MINGW_DIR\\bin;%PATH%
set PATH=$GOFFICE_DIR\\bin;%PATH%
set PATH=$LIBGSF_DIR\\bin;%PATH%
set PATH=$PCRE_DIR\\bin;%PATH%
set PATH=$GNOME_DIR\\bin;%PATH%
set PATH=$GUILE_DIR\\bin;%PATH%
set PATH=$WEBKIT_DIR\\bin;%PATH%
set PATH=$REGEX_DIR\\bin;%PATH%
set PATH=$AQBANKING_PATH;%PATH%
set PATH=$LIBOFX_DIR\\bin;%PATH%
set PATH=$OPENSP_DIR\\bin;%PATH%
set PATH=$LIBDBI_DIR\\bin;%PATH%
set PATH=$SQLITE3_DIR\\bin;%PATH%
set PATH=$MYSQL_LIB_DIR\\lib;%PATH%
set PATH=$PGSQL_DIR\\bin;%PATH%
set PATH=$PGSQL_DIR\\lib;%PATH%
set PATH=$ENCHANT_DIR\\bin;%PATH%
set PATH=$ENCHANT_DIR\\lib;%PATH%
set PATH=$LIBSOUP_DIR\\bin;%PATH%
set PATH=$LIBSOUP_DIR\\lib;%PATH%
set PATH=$LIBXSLT_DIR\\bin;%PATH%
set PATH=$LIBXSLT_DIR\\lib;%PATH%
set PATH=$ICU4C_DIR\\lib;%PATH%

set LTDL_LIBRARY_PATH=${INSTALL_DIR}\\lib

start gnucash %*
EOF
        qpopd
    fi
}

function checkupd_docs_git() {

    if [ "$UPDATE_DOCS" = "yes" ]; then
        if [ -x .git ]; then
            setup "Docs - Update repository (git)"
            $GIT_CMD pull
        else
            setup "Docs - Checkout repository (git)"
            $GIT_CMD clone $DOCS_URL .
            $GIT_CMD checkout $DOCS_SCM_REV
        fi
    fi
}

function make_chm() {
    _CHM_TYPE=$1
    _CHM_LANG=$2
    _XSLTPROC_OPTS=$3
    echo "Processing $_CHM_TYPE ($_CHM_LANG) ..."
    qpushd $_CHM_TYPE/$_CHM_LANG
        ## Some debug output
        #echo xsltproc $XSLTPROCFLAGS $_XSLTPROC_OPTS --path ../../../docbookx-dtd ../../../docbook-xsl/htmlhelp/htmlhelp.xsl gnucash-$_CHM_TYPE.xml
        #ls ../../../docbookx-dtd ../../../docbook-xsl/htmlhelp/htmlhelp.xsl gnucash-$_CHM_TYPE.xml
        xsltproc $XSLTPROCFLAGS $_XSLTPROC_OPTS --path ../../../docbookx-dtd ../../../docbook-xsl/htmlhelp/htmlhelp.xsl gnucash-$_CHM_TYPE.xml
        count=0
        echo >> htmlhelp.hhp
        echo "[ALIAS]" >> htmlhelp.hhp
        echo "IDH_0=index.html" >> htmlhelp.hhp
        echo "#define IDH_0 0" > mymaps
        echo "[Map]" > htmlhelp.hhmap
        echo "Searching for anchors ..."
        for id in `cat *.xml | sed '/sect.*id=/!d;s,.*id=["'\'']\([^"'\'']*\)["'\''].*,\1,'` ; do
            files=`grep -l "[\"']${id}[\"']" *.html` || continue
            echo "IDH_$((++count))=${files}#${id}" >> htmlhelp.hhp
            echo "#define IDH_${count} ${count}" >> mymaps
            echo "${id}=${count}" >> htmlhelp.hhmap
        done
        echo >> htmlhelp.hhp
        echo "[MAP]" >> htmlhelp.hhp
        cat mymaps >> htmlhelp.hhp
        rm mymaps
        echo "Will now call hhc.exe for $_CHM_TYPE ($_CHM_LANG)..."
        hhc htmlhelp.hhp  >/dev/null  || true
        echo "... hhc.exe completed successfully."
        cp -fv htmlhelp.chm $_DOCS_INST_UDIR/$_CHM_LANG/gnucash-$_CHM_TYPE.chm
        cp -fv htmlhelp.hhmap $_DOCS_INST_UDIR/$_CHM_LANG/gnucash-$_CHM_TYPE.hhmap
    qpopd
}

function inst_docs() {
    setup "Docbook xsl and dtd"
    _DOCS_UDIR=`unix_path $DOCS_DIR`
    if [ ! -d $_DOCS_UDIR/docbook-xsl ] ; then
        wget_unpacked $DOCBOOK_XSL_URL $DOWNLOAD_DIR $DOCS_DIR
        # add a pause to allow windows to realize that the files now exist
        sleep 1
        mv $_DOCS_UDIR/docbook-xsl-* $_DOCS_UDIR/docbook-xsl
    else
        echo "Docbook xsl already installed. Skipping."
    fi
    if [ ! -d $_DOCS_UDIR/docbookx-dtd ] ; then
        mkdir -p $_DOCS_UDIR/docbookx-dtd
        wget_unpacked $DOCBOOK_DTD_URL $DOWNLOAD_DIR $DOCS_DIR/docbookx-dtd
    else
        echo "Docbook dtd already installed. Skipping."
    fi

    mkdir -p $_DOCS_UDIR/repos
    qpushd $_DOCS_UDIR/repos
        checkupd_docs_git
        setup docs
        _DOCS_INST_UDIR=`unix_path $INSTALL_DIR`/share/gnucash/help
        mkdir -p $_DOCS_INST_UDIR/{C,de,it,ja}
        make_chm guide C
        make_chm guide de
        make_chm guide it
# Temporarily disabled because it makes hh
#        make_chm guide ja "--stringparam chunker.output.encoding Shift_JIS --stringparam htmlhelp.encoding Shift_JIS"
        make_chm help C
        make_chm help de
#        make_chm help it
    qpopd
}

function inst_finish() {
    setup Finish...
    if [ "$NO_SAVE_PROFILE" != "yes" ]; then
        _NEW=x
        for _ENV in $ENV_VARS; do
            _ADDS=`eval echo '"\$'"${_ENV}"'_ADDS"'`
            if [ "$_ADDS" ]; then
                if [ "$_NEW" ]; then
                    echo
                    echo "Environment variables changed, please do the following"
                    echo
                    [ -d /etc/profile.d ] || echo "mkdir -p /etc/profile.d"
                    _NEW=
                fi
                _VAL=`eval echo '"$'"${_ENV}_BASE"'"'`
                if [ "$_VAL" ]; then
                    _CHANGE="export ${_ENV}=\"${_ADDS}"'$'"${_ENV}\""
                else
                    _CHANGE="export ${_ENV}=\"${_ADDS}\""
                fi
                echo $_CHANGE
                echo echo "'${_CHANGE}' >> /etc/profile.d/installer.sh"
            fi
        done
    fi
    if [ "$CROSS_COMPILE" = "yes" ]; then
        echo "You might want to create a binary tarball now as follows:"
        qpushd $GLOBAL_DIR
        echo tar -czf $HOME/gnucash-fullbin.tar.gz --anchored \
            --exclude='*.a' --exclude='*.o' --exclude='*.h' \
            --exclude='*.info' --exclude='*.html' \
            --exclude='*include/*' --exclude='*gtk-doc*' \
            --exclude='bin*' \
            --exclude='mingw32/*' --exclude='*bin/mingw32-*' \
            --exclude='gnucash-trunk*' \
            *
        qpopd
    fi
}

### Local Variables: ***
### sh-basic-offset: 4 ***
### indent-tabs-mode: nil ***
### End: ***
