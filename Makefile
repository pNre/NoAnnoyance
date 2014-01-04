TARGET = iphone:clang::7.0

include theos/makefiles/common.mk

export ARCHS = armv7 arm64

TWEAK_NAME = NoAnnoyance
NoAnnoyance_FILES = Tweak.xm
NoAnnoyance_FRAMEWORKS = CoreFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NoAnnoyance$(ECHO_END)
	$(ECHO_NOTHING)cp Settings/* $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NoAnnoyance/$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
