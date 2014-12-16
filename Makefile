#THEOS_DEVICE_IP = 192.168.1.247
THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

TARGET = iphone:clang::7.0

include theos/makefiles/common.mk

# this is baaad
THEOS_INCLUDE_PATH = include -I . -I /opt/theos/include

export ARCHS = armv7 arm64

TWEAK_NAME = NoAnnoyance
NoAnnoyance_FILES = Tweak.xm SpringBoard.xm NoAnnoyance.xm
NoAnnoyance_FRAMEWORKS = CoreFoundation UIKit
NoAnnoyance_LDFLAGS = -lMobileGestalt
NoAnnoyance_CFLAGS = -fobjc-arc -O3

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += noannoyanceprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
