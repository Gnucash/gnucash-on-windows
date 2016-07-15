set_property (GLOBAL PROPERTY EP_BASE ${GLOBAL_DEP_BUILD_DIR})
set (INSTALL_DIR ${GLOBAL_DEP_BUILD_DIR}/glib-install)
set (CMAKE_INSTALL_PREFIX ${INSTALL_DIR})
ExternalProject_Add(pkgconfig
  URL ${PKG_CONFIG_SRC_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${INSTALL_DIR} --with-internal-glib
  BUILD_COMMAND make
  INSTALL_COMMAND make install
  INSTALL_DIR ${INSTALL_DIR}
  )
ExternalProject_Add(zlib
  URL ${ZLIB_SRC_URL}
  CONFIGURE_COMMAND sed -i s/SHARED_MODE=0/SHARED_MODE=1/ <SOURCE_DIR>/win32/Makefile.gcc
  BUILD_COMMAND make -f <SOURCE_DIR>/win32/Makefile.gcc
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND prefix=${INSTALL_DIR} INCLUDE_PATH=${INSTALL_DIR}/include LIBRARY_PATH=${INSTALL_DIR}/lib BINARY_PATH=${INSTALL_DIR}/bin make -f <SOURCE_DIR>/win32/Makefile.gcc install
  INSTALL_DIR ${INSTALL_DIR}
  )
ExternalProject_Add(intltool
  URL ${INTLTOOL_URL}
  SOURCE_DIR ${INSTALL_DIR}
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  )
ExternalProject_Add(freetype
  URL ${FREETYPE_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${INSTALL_DIR} --without-bzip2 --without-png
  BUILD_COMMAND make
  INSTALL_COMMAND make install
  INSTALL_DIR ${INSTALL_DIR}
  DEPENDS intltool
  )
ExternalProject_Get_Property(freetype source_dir)
ExternalProject_Add_Step(freetype export-fix
  COMMAND sh -c "rm include/freetype/ftmac.h"
  WORKING_DIRECTORY ${source_dir}
  DEPENDEES configure
  DEPENDERS build
)
ExternalProject_Add(fontconfig
  URL ${FONTCONFIG_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${INSTALL_DIR} --disable-docs
  BUILD_COMMAND make
  INSTALL_COMMAND make install
  INSTALL_DIR ${INSTALL_DIR}
  DEPENDS freetype;pkgconfig
  )
ExternalProject_Add(libffi
  URL ${LIBFFI_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${INSTALL_DIR}
  BUILD_COMMAND make
  INSTALL_COMMAND make install
  INSTALL_DIR ${INSTALL_DIR}
  )
ExternalProject_Add(glib
  URL ${GLIB_SRC_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${INSTALL_DIR} --with-pcre=internal
  PATCH_COMMAND patch -p1 < ${CMAKE_SOURCE_DIR}/glib-timezone.patch
  BUILD_COMMAND make
  INSTALL_COMMAND make install
  INSTALL_DIR ${INSTALL_DIR}
  DEPENDS libffi;zlib
  )
ExternalProject_Add(harfbuzz
  URL ${HARFBUZZ_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${INSTALL_DIR}
  BUILD_COMMAND make
  INSTALL_DIR ${INSTALL_DIR}
  DEPENDS fontconfig;glib
  )
# harfbuzz has a dependency on glib for three unicode functions, so we
# need to build it again after building glib.
ExternalProject_Add_Step(harfbuzz fix-pkgconfig-prefix
  COMMAND sh -c "chmod -R o+w ${INSTALL_DIR}"
  COMMAND sh -c "sed -i 's@prefix *= *${INSTALL_DIR}@prefix = c:/gcdev@' ${INSTALL_DIR}/lib/pkgconfig/*.pc"
  COMMAND sh -c "sed -i s@${INSTALL_DIR}@\\$\\{prefix\\}@ ${INSTALL_DIR}/lib/pkgconfig/*.pc"
  DEPENDEES install
  )
if (GNC_MAKE_TARBALLS)
  set (TARBALL_DIR ${GLOBAL_DIR}/dependencies)
  ExternalProject_Add_Step(harfbuzz tarballs
    COMMAND sh -c "tar cjf ${TARBALL_DIR}/glib-${GLIB_VERSION}-MinGW-bin.tar.bz2 bin etc share"
    COMMAND sh -c "tar cjf ${TARBALL_DIR}/glib-${GLIB_VERSION}-MinGW-dev.tar.bz2 include lib/pkgconfig lib/glib-2.0 lib/libffi-${LIBFFI_VERSION} lib/*.a"
    BYPRODUCTS ${TARBALL_DIR}/glib-${GLIB_VERSION}-MinGW-bin.tar.bz2 ${TARBALL_DIR}/glib-${GLIB_VERSION}-MinGW-dev.tar.bz2
    WORKING_DIRECTORY ${INSTALL_DIR}
    DEPENDEES fix-pkgconfig-prefix
    )
endif()

if (GNC_INSTALL_DEPS OR GNC_INSTALL_GLIB)
  ExternalProject_Add_Step(harfbuzz final_install
    COMMAND sh -c "cp ${INSTALL_DIR}/bin/* ${GLOBAL_DIR}/gnome/bin"
    COMMAND sh -c "cp ${INSTALL_DIR}/lib/*.a ${GLOBAL_DIR}/gnome/lib"
    COMMAND sh -c "cp ${INSTALL_DIR}/lib/pkgconfig/* ${GLOBAL_DIR}/gnome/lib/pkgconfig"
    COMMAND sh -c "cp -r ${INSTALL_DIR}/lib/glib-2.0 ${GLOBAL_DIR}/gnome/lib/"
    COMMAND sh -c "cp -r ${INSTALL_DIR}/lib/libffi-${LIBFFI_VERSION} ${GLOBAL_DIR}/gnome/lib/"
    COMMAND sh -c "cp -r ${INSTALL_DIR}/etc ${GLOBAL_DIR}/gnome/"
    COMMAND sh -c "cp -r ${INSTALL_DIR}/share ${GLOBAL_DIR}/gnome/"
    ALWAYS 1
    DEPENDEES fix-pkgconfig-prefix
    )
endif()
