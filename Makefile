export ARCHS = armv7 arm64
export TARGET = iphone:clang:9.0
include theos/makefiles/common.mk

LIBRARY_NAME = libShortcutItems
libShortcutItems_FILES = libShortcutItems.mm
libShortcutItems_FRAMEWORKS = UIKit
libShortcutItems_LIBRARIES = substrate
libShortcutItems_CFLAGS += -fobjc-arc
libShortcutItems_PRIVATE_FRAMEWORKS = SpringBoardServices

internal-stage::
	$(ECHO_NOTHING) mkdir -p $(THEOS_STAGING_DIR)/usr/include/libShortcutItems/; cp libShortcutItems.h $(THEOS_STAGING_DIR)/usr/include/libShortcutItems/$(ECHO_END)

include $(THEOS_MAKE_PATH)/library.mk
