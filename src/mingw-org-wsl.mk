# This file is part of MXE.
# See index.html for further information.

PKG             := mingw-org-wsl
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := f70b9c8
$(PKG)_CHECKSUM := 92acd1b8ed349d9f23fe7254d41c36948596fbc6
$(PKG)_SUBDIR   := mirror-mingw-org-wsl-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://github.com/mirror/mingw-org-wsl/tarball/$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_DEPS     :=

# 4.0-dev seems to be more recent than master
define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://github.com/mirror/mingw-org-wsl/commits/4.0-dev' | \
    $(SED) -n 's#.*<span class="sha">\([^<]\{7\}\)[^<]\{3\}<.*#\1#p' | \
    head -1
endef
