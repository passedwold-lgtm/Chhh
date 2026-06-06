ARCHS = arm64
TARGET = iphone:clang
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Hack8ball

Hack8ball_FILES = Tweak.xm Menu.mm \
	KittyMemory/KittyMemory.cpp \
	KittyMemory/MemoryPatch.cpp \
	KittyMemory/MemoryBackup.cpp \
	KittyMemory/KittyUtils.cpp \
	KittyMemory/writeData.cpp \
	SCLAlertView/SCLAlertView.m \
	SCLAlertView/SCLAlertViewResponder.m \
	SCLAlertView/SCLAlertViewStyleKit.m \
	SCLAlertView/SCLButton.m \
	SCLAlertView/SCLSwitchView.m \
	SCLAlertView/SCLTextView.m \
	SCLAlertView/SCLTimerDisplay.m \
	SCLAlertView/UIImage+ImageEffects.m

Hack8ball_CFLAGS = -fobjc-arc -w
Hack8ball_CCFLAGS = -std=c++11 -fno-rtti -fno-exceptions

Hack8ball_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
Hack8ball_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
