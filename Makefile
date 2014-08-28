GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk
TWEAK_NAME = BackdropBadge
BackdropBadge_FILES = Tweak.xm
BackdropBadge_FRAMEWORKS = CoreGraphics QuartzCore UIKit

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

