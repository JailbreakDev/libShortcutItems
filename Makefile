export ARCHS = armv7 arm64
export TARGET = iphone:clang:9.0
include theos/makefiles/common.mk

LIBRARY_NAME = libShortcutItems
libShortcutItems_FILES = libShortcutItems.mm
libShortcutItems_FRAMEWORKS = UIKit
libShortcutItems_LIBRARIES = substrate
libShortcutItems_CFLAGS += -fobjc-arc
libShortcutItems_PRIVATE_FRAMEWORKS = SpringBoardServices

include $(THEOS_MAKE_PATH)/library.mk
