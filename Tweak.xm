#import "Macros.h"

// ========================================
// 8BALL POOL - MOD TWEAK
// ========================================

// ========== GLOBAL MOD STATES ==========

bool longShotMode     = false;
bool perfectSpinMode  = false;
bool ballGhostMode    = false;
float powerMultiplier = 2.0f;

// ========== BALL POSITION HOOK (Long Shot) ==========

void(*old_BallSetPosition)(void *instance, float x, float y);
void BallSetPosition(void *instance, float x, float y) {
    if ([switches isSwitchOn:@"Long Shot"]) {
        x *= 2.0f;
        y *= 2.0f;
    }
    old_BallSetPosition(instance, x, y);
}

// ========== BALL VELOCITY HOOK (Power Boost) ==========

void(*old_BallSetVelocity)(void *instance, float x, float y);
void BallSetVelocity(void *instance, float x, float y) {
    if ([switches isSwitchOn:@"Power Boost"]) {
        x *= powerMultiplier;
        y *= powerMultiplier;
    }
    old_BallSetVelocity(instance, x, y);
}

// ========== BALL SPIN HOOK (Perfect Spin) ==========

void(*old_BallSetSpin)(void *instance, float x, float y);
void BallSetSpin(void *instance, float x, float y) {
    if ([switches isSwitchOn:@"Perfect Spin"]) {
        x *= 0.5f;
        y *= 0.5f;
    }
    old_BallSetSpin(instance, x, y);
}

// ========== BALL OPACITY HOOK (Ghost Mode) ==========

void(*old_BallSetOpacity)(void *instance, unsigned char opacity);
void BallSetOpacity(void *instance, unsigned char opacity) {
    if ([switches isSwitchOn:@"Ghost Balls"]) {
        opacity = 128;
    }
    old_BallSetOpacity(instance, opacity);
}

// ========== AUTO AIM HOOK ==========

%hook UserInfo
- (int)lowAimRatio {
    if ([switches isSwitchOn:@"Auto Aim"]) {
        return -999;
    }
    return %orig;
}
%end

// ========== JAILBREAK BYPASS ==========

%hook JailBreakChecks
+ (bool)isDeviceJailbroken      { return 0; }
+ (bool)isApplicationCrackd     { return 0; }
+ (bool)isApplicationTamperedWith { return 0; }
%end

%hook FYBJailbreakStatusProvider
+ (bool)isJailbroken { return 0; }
- (id)dictionaryWithKeyValueParameters { return NULL; }
%end

%hook SSEDeviceStatus
- (bool)jailBroken { return 0; }
%end

%hook USRVDevice
+ (bool)isRooted    { return 0; }
+ (bool)isSimulator { return 0; }
%end

%hook USRVApiDeviceInfo
+ (void)WebViewExposed_isRooted:(id)arg1    { arg1 = NULL; return %orig; }
+ (void)WebViewExposed_isSimulator:(id)arg1 { arg1 = NULL; return %orig; }
%end

%hook GULAppEnvironmentUtil
+ (bool)isSimulator { return 0; }
%end

%hook ANSMetadata
- (bool)isJailbroken        { return 0; }
- (bool)computeIsJailbroken { return 0; }
%end

%hook FBAdBotDetector
- (void)addJailbrokenSignalsForSignalList:(id)arg1 toDictionary:(id)arg2 {
    arg1 = NULL; arg2 = NULL; %orig;
}
- (bool)isNativeSignalJailbrokenEnabled { return 0; }
%end

%hook FBAdConfigManager
- (bool)woNativeSignalsJailbrokenSignalEnabled { return 0; }
%end

// ========== SETUP HOOKS & SWITCHES ==========

void setup() {

    // -- Function Hooks --
    // Offsets from EIGHTBALL.h (RVA = 0x100000000 + offset)
    HOOK(0x100000000 + 0x61698, BallSetPosition,  old_BallSetPosition);
    HOOK(0x100000000 + 0x616B8, BallSetVelocity,  old_BallSetVelocity);
    HOOK(0x100000000 + 0x61668, BallSetSpin,       old_BallSetSpin);
    HOOK(0x100000000 + 0x60F88, BallSetOpacity,    old_BallSetOpacity);

    // -- Switches --
    [switches addSwitch:@"Long Shot"
            description:@"Extends shot range 2x"];

    [switches addSwitch:@"Power Boost"
            description:@"Doubles ball velocity"];

    [switches addSwitch:@"Perfect Spin"
            description:@"Reduces unwanted spin for better control"];

    [switches addSwitch:@"Ghost Balls"
            description:@"Makes balls 50% transparent"];

    [switches addSwitch:@"Auto Aim"
            description:@"Extends aim line to max range"];

    // -- Offset Patches (Memory) --
    [switches addOffsetSwitch:@"Always First Break"
                  description:@"Always get the first break shot"
                      offsets:{0x100000000 + 0xD0B04}
                        bytes:{"0x200080D2C0035FD6"}];

    [switches addOffsetSwitch:@"Anti Jailbreak"
                  description:@"Bypass jailbreak detection"
                      offsets:{0x100000000 + 0x616AC}
                        bytes:{"0x200080D2C0035FD6"}];
}

// ========== MENU CONFIG ==========

void setupMenu() {
    menu = [[Menu alloc]
                initWithTitle:@"8Ball Pool Mod Menu"
                titleColor:[UIColor whiteColor]
                titleFont:@"Copperplate-Bold"
                credits:@"8Ball Pool Mod - Free & not for sale.\n\nEnjoy!"
                headerColor:UIColorFromHex(0x1B5E20)
                switchOffColor:[UIColor darkGrayColor]
                switchOnColor:UIColorFromHex(0x00C853)
                switchTitleFont:@"Copperplate-Bold"
                switchTitleColor:[UIColor whiteColor]
                infoButtonColor:UIColorFromHex(0x1B5E20)
                maxVisibleSwitches:5
                menuWidth:260
                menuIcon:@"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wgARCAMgAvYDASIAAhEBAxEB/8QAGgABAAIDAQAAAAAAAAAAAAAAAAUGAQMEAv/EABQBAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhADEAAAAp8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8npHx5YFR4y6ctS8ln014TeIUTHmJE1mGwTe+uC09FOF72UDeXhVJAm3H2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwwxZIus+STjvIAZYGcejy9eQbzRt9YNOcAZMMjBkYDOzUJiWqIv2aPLlhaN4AAAAAAAAAAAAAAAAAAAAAAAAAAAAR8OS0B45AA6bKVTtt2Cv9fVHEhvrHGXTVSxclNF081LeTMf2SBy9kNFFu804XL3ShefFJ6Czc0fInFxWrpKNvuESQurf5OOUjfBdOugSpanP0AAAAAAAAAAAAAAAAAAAAAAAAAhCWgonoNPtg883RIkNvtXWVuTR5ZMU7lL4oOwunFCSZyRN58FG3dvENLJhnAAMmN8rYivyW+GJ3ZTeUvmKFsLvFx8gR/PZOgpOm1wxGgzOwOS+eqTZiQAAAAAAAAAAAAAAAAAAAAAA08tWOuOBnEocExNcZ38dc5CVjMYGWAAAZNlkrHsvFQ7Z0o7ZrMsZMMhO8NqPde4eEzgADOB68jOzUJuapQulfWApmLhWjkBO2Gg9xcWjeAAAAAAAAAAAAAAAAAAAIXngjLGTO2SsRwSbmPHJyRBLx3GPTGAzgM95Hu3iGWD15ZMWGvZLJWrjVDSZMvMsT1ckq4AAPWPR5xI6jjAB77Y/JYd9W7C27YWXIWAvvKUp3cJvtdOyX1FygAAAAAAAAAAAAAAAAArSFBkd3u0HjETAErEsmAMthqdu4jEsInMpqN8xWPB3xdu4CABnDJ2yEDOEJgForUqResAHr1aiP7uSvndw9O8jkuIhK+COx1854Bn14E9PUPcWqrWXoKW6OczaKtkvyJlgAAAAAAAAAAAAAABXeitAyJXXaBVtfKeE1KlQ33XyVDxc9hQOq5RxzTVS5S9KT4LypGwueiuyAktnsrULfqccRkzv5xgHRowAHrE4d23vEVJaoknlS5y6qN6Lvz1TnJeKkZkqO67ZKVquvooebzHlVnuSMLzUJCdKQ6OczbKlsL25OsAAAAAAAAAAAAAcHTSzXhkdei5nuqdMQd9o9ZNcFIyJT9N4jCp7NYlZun+i+wuueKCs0GciZjTQDZYqyL/zQ1iKH4sVdAM4ZMAZDqufH1iu8fAZwA7jixNxQtfvqMw8XGHdx+Q6ue9FSkp7Ue+TTJlHmeypl1p1l9lUwG+50WRLcAAAAAAAAAAAAQpGR2PRjCcJHn7qceZOMsRO+fWg3oKMLbWIvAAB6s1X9F8qkf0k/J0O1nJXr9wlObtQs9X2F6pdw4yogAyzgxNRN3NlXl6iAN3RazjklePO+u9hcK3D4GcDLPkWSti/ZocgWr1Dyh7ot7qRw2+mdJKQV7qJxAsM9QbkdgAAAAAAAAAANFKkYsGTrt/PDEdzLEQFngLGaou1Cm6LjBkI2awdBz9DWefIAM4FqlaBOk1VLhkoSahSbslBupW426UwwAdBNzmIgguV7PEtITJ59c9ZOqFwDOA97DVuzzmAAN6cIvosvs4Imy10hfE3zG6dpVsKr5sdcHbxC/ZhJsAAA"
                menuButton:@"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wgARCAMgAvYDASIAAhEBAxEB/8QAGgABAAIDAQAAAAAAAAAAAAAAAAUGAQMEAv/EABQBAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhADEAAAAp8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8npHx5YFR4y6ctS8ln014TeIUTHmJE1mGwTe+uC09FOF72UDeXhVJAm3H2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwwxZIus+STjvIAZYGcejy9eQbzRt9YNOcAZMMjBkYDOzUJiWqIv2aPLlhaN4AAAAAAAAAAAAAAAAAAAAAAAAAAAAR8OS0B45AA6bKVTtt2Cv9fVHEhvrHGXTVSxclNF081LeTMf2SBy9kNFFu804XL3ShefFJ6Czc0fInFxWrpKNvuESQurf5OOUjfBdOugSpanP0AAAAAAAAAAAAAAAAAAAAAAAAAhCWgonoNPtg883RIkNvtXWVuTR5ZMU7lL4oOwunFCSZyRN58FG3dvENLJhnAAMmN8rYivyW+GJ3ZTeUvmKFsLvFx8gR/PZOgpOm1wxGgzOwOS+eqTZiQAAAAAAAAAAAAAAAAAAAAAA08tWOuOBnEocExNcZ38dc5CVjMYGWAAAZNlkrHsvFQ7Z0o7ZrMsZMMhO8NqPde4eEzgADOB68jOzUJuapQulfWApmLhWjkBO2Gg9xcWjeAAAAAAAAAAAAAAAAAAAIXngjLGTO2SsRwSbmPHJyRBLx3GPTGAzgM95Hu3iGWD15ZMWGvZLJWrjVDSZMvMsT1ckq4AAPWPR5xI6jjAB77Y/JYd9W7C27YWXIWAvvKUp3cJvtdOyX1FygAAAAAAAAAAAAAAAAArSFBkd3u0HjETAErEsmAMthqdu4jEsInMpqN8xWPB3xdu4CABnDJ2yEDOEJgForUqResAHr1aiP7uSvndw9O8jkuIhK+COx1854Bn14E9PUPcWqrWXoKW6OczaKtkvyJlgAAAAAAAAAAAAAABXeitAyJXXaBVtfKeE1KlQ33XyVDxc9hQOq5RxzTVS5S9KT4LypGwueiuyAktnsrULfqccRkzv5xgHRowAHrE4d23vEVJaoknlS5y6qN6Lvz1TnJeKkZkqO67ZKVquvooebzHlVnuSMLzUJCdKQ6OczbKlsL25OsAAAAAAAAAAAAAcHTSzXhkdei5nuqdMQd9o9ZNcFIyJT9N4jCp7NYlZun+i+wuueKCs0GciZjTQDZYqyL/zQ1iKH4sVdAM4ZMAZDqufH1iu8fAZwA7jixNxQtfvqMw8XGHdx+Q6ue9FSkp7Ue+TTJlHmeypl1p1l9lUwG+50WRLcAAAAAAAAAAAAQpGR2PRjCcJHn7qceZOMsRO+fWg3oKMLbWIvAAB6s1X9F8qkf0k/J0O1nJXr9wlObtQs9X2F6pdw4yogAyzgxNRN3NlXl6iAN3RazjklePO+u9hcK3D4GcDLPkWSti/ZocgWr1Dyh7ot7qRw2+mdJKQV7qJxAsM9QbkdgAAAAAAAAAANFKkYsGTrt/PDEdzLEQFngLGaou1Cm6LjBkI2awdBz9DWefIAM4FqlaBOk1VLhkoSahSbslBupW426UwwAdBNzmIgguV7PEtITJ59c9ZOqFwDOA97DVuzzmAAN6cIvosvs4Imy10hfE3zG6dpVsKr5sdcHbxC/ZhJsAAA"
    ];
    setup();
}

// ========== LAUNCH ==========

static void didFinishLaunching(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef info) {
    timer(3) {
        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];

        [alert addButton:@"Let's Play!" actionBlock:^(void) {
            timer(1) {
                setupMenu();
            });
        }];

        alert.shouldDismissOnTapOutside = NO;
        alert.customViewColor = UIColorFromHex(0x1B5E20);
        alert.showAnimationType = SCLAlertViewShowAnimationSlideInFromCenter;

        [alert showSuccess:nil
                 subTitle:@"8Ball Pool Mod Menu loaded!\n\nTap the button to open the menu."
         closeButtonTitle:nil
                 duration:99999999.0f];
    });
}

%ctor {
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetLocalCenter(), NULL,
        &didFinishLaunching,
        (CFStringRef)UIApplicationDidFinishLaunchingNotification,
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}
