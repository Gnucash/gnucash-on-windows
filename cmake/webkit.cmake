ExternalProject_Add(icu
  URL ${ICU_URL}
  CONFIGURE_COMMAND <SOURCE_DIR>/source/configure --prefix ${INSTALL_DIR}
  BUILD_COMMAND make
  INSTALL_COMMAND make install COMMAND sh -c "pushd ${INSTALL_DIR}/lib && for i in icu\*.dll$<SEMICOLON> do mv $i ../bin/lib$i$<SEMICOLON> done && popd" COMMAND sh -c "sed -i -e 's/libdir = \${exec_prefix}\\/lib/libdir = \${exec_prefix}\\/bin/' ${INSTALL_DIR}/lib/pkgconfig/icu*.pc"
  INSTALL_DIR ${INSTALL_DIR}
  )
