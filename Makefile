export THEOS ?= /Users/iiemb/theos
THEOS_PACKAGE_SCHEME = rootless

TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard MobilePhone InCallService Preferences
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = iiKit

iiKit_FILES = $(wildcard Tweaks/*.x Tweaks/*.xm)
iiKit_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = iiKitPrefs iiKitURLLauncher

iiKitPrefs_FILES = prefs/iiKitPrefsListController.m
iiKitPrefs_FRAMEWORKS = UIKit
iiKitPrefs_INSTALL_PATH = /Library/PreferenceBundles
iiKitPrefs_RESOURCE_DIRS = prefs/Resources
iiKitPrefs_CFLAGS = -fobjc-arc
iiKitPrefs_LDFLAGS = -undefined dynamic_lookup

iiKitURLLauncher_BUNDLE_EXTENSION = bundle
iiKitURLLauncher_FILES = controlcenter/iiKitURLLauncher.m
iiKitURLLauncher_FRAMEWORKS = UIKit
iiKitURLLauncher_INSTALL_PATH = /Library/ControlCenter/Bundles
iiKitURLLauncher_RESOURCE_DIRS = controlcenter/Resources
iiKitURLLauncher_CFLAGS = -fobjc-arc
iiKitURLLauncher_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk

# Automatically generate both rootless (iphoneos-arm64) and roothide (iphoneos-arm64e) packages on `make package`
after-package::
	@echo "==> Packaging roothide (iphoneos-arm64e) build..."
	@rm -rf "$(THEOS_OBJ_DIR)/roothide_stage"
	@mkdir -p "$(THEOS_OBJ_DIR)/roothide_stage/DEBIAN"
	@cp -R "$(THEOS_STAGING_DIR)/var/jb/"* "$(THEOS_OBJ_DIR)/roothide_stage/"
	@sed 's/Architecture: iphoneos-arm64/Architecture: iphoneos-arm64e/' "$(THEOS_STAGING_DIR)/DEBIAN/control" > "$(THEOS_OBJ_DIR)/roothide_stage/DEBIAN/control"
	@COPYFILE_DISABLE=1 dpkg-deb --root-owner-group -Zxz -z$(THEOS_PLATFORM_DEB_COMPRESSION_LEVEL) -b "$(THEOS_OBJ_DIR)/roothide_stage" "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(_THEOS_INTERNAL_PACKAGE_VERSION)_iphoneos-arm64e.deb" >/dev/null
	@rm -rf "$(THEOS_OBJ_DIR)/roothide_stage"
	@echo "==> Built packages in $(THEOS_PACKAGE_DIR):"
	@ls -1 "$(THEOS_PACKAGE_DIR)/"*.deb
