# This file is part of MXE.
# See index.html for further information.

PKG             := lcms
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 2.5
$(PKG)_CHECKSUM := bab3470471fc7756c5fbe71be9a3c7d677d2ee7b
$(PKG)_SUBDIR   := $(PKG)$(word 1,$(subst ., ,$($(PKG)_VERSION)))-$(subst a,,$($(PKG)_VERSION))
$(PKG)_FILE     := $(PKG)$(word 1,$(subst ., ,$($(PKG)_VERSION)))-$(subst a,,$($(PKG)_VERSION)).tar.gz
$(PKG)_URL      := http://$(SOURCEFORGE_MIRROR)/project/$(PKG)/$(PKG)/$(subst a,,$($(PKG)_VERSION))/$($(PKG)_FILE)
$(PKG)_DEPS     := gcc jpeg tiff zlib

define $(PKG)_UPDATE
    $(WGET) -q -O- 'http://sourceforge.net/projects/lcms/files/lcms/' | \
    $(SED) -n 's,.*/\([0-9][^"]*\)/".*,\1,p' | \
    head -1
endef

define $(PKG)_BUILD
    cd '$(1)' && ./configure \
        $(MXE_CONFIGURE_OPTS) \
        --with-jpeg \
        --with-tiff \
        --with-zlib
    $(MAKE) -C '$(1)' -j '$(JOBS)' install bin_PROGRAMS= sbin_PROGRAMS= noinst_PROGRAMS= man_MANS=
endef
