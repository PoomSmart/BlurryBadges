PACKAGE_VERSION = 1.1.1

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
else
	TARGET = iphone:11.2:7.0
endif

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = BackdropBadge
BackdropBadge_FILES = Tweak.xm
BackdropBadge_FRAMEWORKS = CoreGraphics QuartzCore UIKit
BackdropBadg_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = BackdropBadgePref
BackdropBadgePref_FILES = BackdropBadgePref.m
BackdropBadgePref_INSTALL_PATH = /Library/PreferenceBundles
BackdropBadgePref_PRIVATE_FRAMEWORKS = Preferences
BackdropBadgePref_FRAMEWORKS = CoreGraphics UIKit

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BackdropBadgePref.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)

all::
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif
