# This file is part of MXE.
# See index.html for further information.

PKG             := gcc
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 4.8.2
$(PKG)_CHECKSUM := 810fb70bd721e1d9f446b6503afe0a9088b62986
$(PKG)_SUBDIR   := gcc-$($(PKG)_VERSION)
$(PKG)_FILE     := gcc-$($(PKG)_VERSION).tar.bz2
$(PKG)_URL      := ftp://ftp.gnu.org/pub/gnu/gcc/gcc-$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_URL_2    := ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_DEPS     := binutils gcc-cloog gcc-gmp gcc-isl gcc-mpc gcc-mpfr

$(PKG)_DEPS_i686-pc-mingw32    := $($(PKG)_DEPS) mingwrt w32api
$(PKG)_DEPS_i686-w64-mingw32   := $($(PKG)_DEPS) mingw-w64
$(PKG)_DEPS_x86_64-w64-mingw32 := $($(PKG)_DEPS) mingw-w64
$(PKG)_DEPS_i686-pc-mingw32.static.wsl := $($(PKG)_DEPS) mingw-org-wsl

define $(PKG)_UPDATE
    $(WGET) -q -O- 'http://ftp.gnu.org/gnu/gcc/?C=M;O=D' | \
    $(SED) -n 's,.*<a href="gcc-\([0-9][^"]*\)/".*,\1,p' | \
    $(SORT) -V | \
    tail -1
endef

define $(PKG)_CONFIGURE
    # configure gcc
    mkdir '$(1).build'
    cd    '$(1).build' && '$(1)/configure' \
        --target='$(TARGET)' \
        --build='$(BUILD)' \
        --prefix='$(PREFIX)' \
        --libdir='$(PREFIX)/lib' \
        --enable-languages='c,c++,objc,fortran' \
        --enable-version-specific-runtime-libs \
        --with-gcc \
        --with-gnu-ld \
        --with-gnu-as \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --without-x \
        --disable-win32-registry \
        --enable-threads=win32 \
        --disable-libgomp \
        --disable-libmudflap \
        --with-cloog='$(PREFIX)' \
        --with-gmp='$(PREFIX)' \
        --with-isl='$(PREFIX)' \
        --with-mpc='$(PREFIX)' \
        --with-mpfr='$(PREFIX)' \
        --with-as='$(PREFIX)/bin/$(TARGET)-as' \
        --with-ld='$(PREFIX)/bin/$(TARGET)-ld' \
        --with-nm='$(PREFIX)/bin/$(TARGET)-nm' \
        $(shell [ `uname -s` == Darwin ] && echo "LDFLAGS='-Wl,-no_pie'")
endef

define $(PKG)_POST_BUILD
    rm -f $(addprefix $(PREFIX)/$(TARGET)/bin/, c++ g++ gcc gfortran)
endef

define $(PKG)_BUILD_i686-pc-mingw32
    # build full cross gcc
    $($(PKG)_CONFIGURE) \
        --disable-sjlj-exceptions
    $(MAKE) -C '$(1).build' -j '$(JOBS)'
    $(MAKE) -C '$(1).build' -j 1 install

    $($(PKG)_POST_BUILD)
endef

define $(PKG)_BUILD_i686-pc-mingw32.static.wsl
    # prepare source
    cd '$(1)' && $(call UNPACK_PKG_ARCHIVE,mingw-org-wsl)
    $(foreach PKG_PATCH,$(sort $(wildcard $(TOP_DIR)/src/mingw-org-wsl-*.patch)),
	        (cd '$(1)/$(mingw-org-wsl_SUBDIR)' && $(PATCH) -p1 -u) < $(PKG_PATCH))
    cd '$(1)/$(mingw-org-wsl_SUBDIR)' && git clone `grep url .gitmodules | cut -d '=' -f2`
    cd '$(1)/$(mingw-org-wsl_SUBDIR)' && autoreconf -fi

    # install headers
    # can't use any Makefile install targets as our patches add headers
    cp -rpv '$(1)/$(mingw-org-wsl_SUBDIR)/include'         '$(PREFIX)/$(TARGET)'
    cp -rpv '$(1)/$(mingw-org-wsl_SUBDIR)/misc/include/GL' '$(PREFIX)/$(TARGET)/include'

    # build standalone gcc
    $($(PKG)_CONFIGURE)
    $(MAKE) -C '$(1).build' -j '$(JOBS)' all-gcc
    $(MAKE) -C '$(1).build' -j 1 install-gcc

    # build crt
    mkdir '$(1).crt-build'
    cd '$(1).crt-build' && '$(1)/$(mingw-org-wsl_SUBDIR)/configure' \
        --target='$(TARGET)' \
        --host='$(BUILD)' \
        --prefix='$(PREFIX)/$(TARGET)' \
        CFLAGS=-D_X86_
    $(MAKE) -C '$(1).crt-build' \
        CC='$(TARGET)-gcc' \
        AR='$(TARGET)-ar' \
        AS='$(TARGET)-as' \
        DLLTOOL='$(TARGET)-dlltool' \
        RANLIB='$(TARGET)-ranlib' \
        mingwthrd.def libmingwex.a
    touch '$(1).crt-build/mingwm10.dll'
    $(MAKE) -C '$(1).crt-build' \
        CC='$(TARGET)-gcc' \
        AR='$(TARGET)-ar' \
        AS='$(TARGET)-as' \
        DLLTOOL='$(TARGET)-dlltool' \
        RANLIB='$(TARGET)-ranlib' \
        -j '$(JOBS)' install-dirs install-libs install-objs

    # build rest of gcc
    cd '$(1).build'
    $(MAKE) -C '$(1).build' -j '$(JOBS)'
    $(MAKE) -C '$(1).build' -j 1 install

    # build and install mingwm10.dll
    rm '$(1).crt-build/mingwm10.dll'
    $(MAKE) -C '$(1).crt-build' \
        CC='$(TARGET)-gcc' \
        AR='$(TARGET)-ar' \
        AS='$(TARGET)-as' \
        DLLTOOL='$(TARGET)-dlltool' \
        RANLIB='$(TARGET)-ranlib' \
        install-bins

    $($(PKG)_POST_BUILD)
endef

define $(PKG)_BUILD_mingw-w64
    # build standalone gcc
    $($(PKG)_CONFIGURE)
    $(MAKE) -C '$(1).build' -j '$(JOBS)' all-gcc
    $(MAKE) -C '$(1).build' -j 1 install-gcc

    # build mingw-w64-crt
    cd '$(1)' && $(call UNPACK_PKG_ARCHIVE,mingw-w64)
    mkdir '$(1).crt-build'
    cd '$(1).crt-build' && '$(1)/$(mingw-w64_SUBDIR)/mingw-w64-crt/configure' \
        --host='$(TARGET)' \
        --prefix='$(PREFIX)/$(TARGET)' \
        mxe-config-opts
    $(MAKE) -C '$(1).crt-build' -j '$(JOBS)' || $(MAKE) -C '$(1).crt-build' -j '$(JOBS)'
    $(MAKE) -C '$(1).crt-build' -j 1 install

    # build rest of gcc
    cd '$(1).build'
    $(MAKE) -C '$(1).build' -j '$(JOBS)'
    $(MAKE) -C '$(1).build' -j 1 install

    $($(PKG)_POST_BUILD)
endef

$(PKG)_BUILD_x86_64-w64-mingw32 = $(subst mxe-config-opts,--disable-lib32,$($(PKG)_BUILD_mingw-w64))
$(PKG)_BUILD_i686-w64-mingw32   = $(subst mxe-config-opts,--disable-lib64,$($(PKG)_BUILD_mingw-w64))

define $(PKG)_BUILD_$(BUILD)
    for f in c++ cpp g++ gcc gcov; do \
        ln -sf "`which $$f`" '$(PREFIX)/bin/$(TARGET)'-$$f ; \
    done
endef
