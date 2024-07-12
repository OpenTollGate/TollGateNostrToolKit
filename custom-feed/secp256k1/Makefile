include $(TOPDIR)/rules.mk

PKG_NAME:=secp256k1
PKG_VERSION:=0.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/bitcoin-core/secp256k1.git
PKG_SOURCE_VERSION:=HEAD

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/secp256k1
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Optimized C library for EC operations on curve secp256k1
  URL:=https://github.com/bitcoin-core/secp256k1
endef

define Package/secp256k1/description
  Optimized C library for EC operations on curve secp256k1
endef

CONFIGURE_ARGS += \
  --enable-module-recovery \
  --enable-experimental \
  --enable-module-ecdh

define Build/Compile
  $(MAKE) -C $(PKG_BUILD_DIR) \
    CC="$(TARGET_CC)" \
    AR="$(TARGET_AR)" \
    RANLIB="$(TARGET_RANLIB)" \
    CFLAGS="$(TARGET_CFLAGS)" \
    LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/secp256k1/install
  $(INSTALL_DIR) $(1)/usr/lib
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/.libs/libsecp256k1.so* $(1)/usr/lib/
  $(INSTALL_DIR) $(1)/usr/include
  $(INSTALL_BIN) $(PKG_BUILD_DIR)/include/secp256k1*.h $(1)/usr/include/
endef

$(eval $(call BuildPackage,secp256k1))
