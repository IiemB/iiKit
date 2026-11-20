# Local paths (THEOS, TWEAK_REPO) go in .env, which is not committed.
# Copy .env.example to .env and fill it in.
-include .env
THEOS ?= $(HOME)/theos
export THEOS
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

# ----------------------------------------------------------------------------
# Publish to the IiemB tweak repo (https://iiemb.github.io/repo/).
#   make publish      build both packages, copy them and depiction/ into the
#                     tweak repo (TWEAK_REPO in .env), replacing older iiKit
#                     packages, then check it
# Deploying stays a manual step in the profile project (./build.sh, then commit
# and push iiemb.github.io/).
# ----------------------------------------------------------------------------
PUBLISH_ID := $(shell sed -n 's/^Package: *//p' control)
PUBLISH_VERSION := $(shell sed -n 's/^Version: *//p' control)

.PHONY: publish
publish:
	@test -n "$(TWEAK_REPO)" || { echo "error: TWEAK_REPO is not set; add it to .env (see .env.example)"; exit 1; }
	@test -f "$(TWEAK_REPO)/build.py" || { echo "error: no tweak repo at TWEAK_REPO (build.py not found)"; exit 1; }
	@# Fresh environment: a nested Theos build breaks on the outer one's exported state.
	@env -i PATH="$$PATH" HOME="$$HOME" TERM="$$TERM" THEOS="$(THEOS)" \
	    $(MAKE) --no-print-directory -C "$(CURDIR)" clean package FINALPACKAGE=1
	@echo "==> Publishing $(PUBLISH_ID) $(PUBLISH_VERSION) to $(TWEAK_REPO)"
	@rm -f "$(TWEAK_REPO)/debs/$(PUBLISH_ID)_"*.deb
	@cp "$(THEOS_PACKAGE_DIR)/$(PUBLISH_ID)_$(PUBLISH_VERSION)_iphoneos-arm64.deb" \
	    "$(THEOS_PACKAGE_DIR)/$(PUBLISH_ID)_$(PUBLISH_VERSION)_iphoneos-arm64e.deb" \
	    "$(TWEAK_REPO)/debs/"
	@mkdir -p "$(TWEAK_REPO)/info/$(PUBLISH_ID)"
	@rsync -a depiction/ "$(TWEAK_REPO)/info/$(PUBLISH_ID)/"
	@python3 "$(TWEAK_REPO)/build.py"
	@echo "==> Done. To go live, from $(dir $(TWEAK_REPO:/=)):"
	@echo "    ./build.sh && cd iiemb.github.io && git add -A && git commit -m \"iiKit $(PUBLISH_VERSION)\" && git push"
