#import "Macros.h"

// ========================================
// 8BALL POOL - MOD TWEAK
// ========================================

// ========== GLOBAL MOD STATES ==========

bool longShotMode    = false;
bool perfectSpinMode = false;
bool ballGhostMode   = false;
float powerMultiplier = 2.0f;

// ========== ESP OVERLAY ==========

static NSMutableArray *espBallPositions;
static UIWindow       *espWindow;
static UIView         *espView;

@interface ESPView : UIView
@end

@implementation ESPView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;

        // Refresh drawing ~60fps
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick:(CADisplayLink *)link {
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (![switches isSwitchOn:@"ESP"]) return;

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // --- Draw ball circles ---
    CGContextSetLineWidth(ctx, 2.5f);

    @synchronized(espBallPositions) {
        for (NSValue *val in espBallPositions) {
            CGPoint p = [val CGPointValue];

            // Skip off-screen points
            if (p.x < 0 || p.y < 0 || p.x > self.bounds.size.width || p.y > self.bounds.size.height)
                continue;

            float radius = 14.0f;

            // Outer glow (red)
            CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:1 green:0 blue:0 alpha:0.9f].CGColor);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(p.x - radius, p.y - radius, radius * 2, radius * 2));

            // Inner dot
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:1 green:0 blue:0 alpha:0.4f].CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(p.x - 4, p.y - 4, 8, 8));

            // Label "Ball"
            NSString *label = @"Ball";
            NSDictionary *attrs = @{
                NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
                NSForegroundColorAttributeName: [UIColor whiteColor]
            };
            [label drawAtPoint:CGPointMake(p.x + radius + 3, p.y - 7) withAttributes:attrs];
        }
    }

    // --- Draw pocket markers (fixed positions, standard 8ball table) ---
    if ([switches isSwitchOn:@"ESP"]) {
        CGSize s = self.bounds.size;
        NSArray *pockets = @[
            [NSValue valueWithCGPoint:CGPointMake(s.width * 0.05f, s.height * 0.12f)],
            [NSValue valueWithCGPoint:CGPointMake(s.width * 0.50f, s.height * 0.10f)],
            [NSValue valueWithCGPoint:CGPointMake(s.width * 0.95f, s.height * 0.12f)],
            [NSValue valueWithCGPoint:CGPointMake(s.width * 0.05f, s.height * 0.88f)],
            [NSValue valueWithCGPoint:CGPointMake(s.width * 0.50f, s.height * 0.90f)],
            [NSValue valueWithCGPoint:CGPointMake(s.width * 0.95f, s.height * 0.88f)],
        ];

        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:1 green:1 blue:0 alpha:0.8f].CGColor);
        CGContextSetLineWidth(ctx, 2.0f);

        for (NSValue *val in pockets) {
            CGPoint p = [val CGPointValue];
            float r = 18.0f;
            CGContextStrokeEllipseInRect(ctx, CGRectMake(p.x - r, p.y - r, r * 2, r * 2));

            NSString *label = @"Pocket";
            NSDictionary *attrs = @{
                NSFontAttributeName: [UIFont boldSystemFontOfSize:9],
                NSForegroundColorAttributeName: [UIColor yellowColor]
            };
            [label drawAtPoint:CGPointMake(p.x - 15, p.y + r + 2) withAttributes:attrs];
        }
    }
}

@end

static void setupESPOverlay() {
    if (espWindow) return;

    espBallPositions = [NSMutableArray new];
    espWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    espWindow.windowLevel = UIWindowLevelStatusBar + 100;
    espWindow.backgroundColor = [UIColor clearColor];
    espWindow.userInteractionEnabled = NO;
    espWindow.hidden = NO;

    espView = [[ESPView alloc] initWithFrame:espWindow.bounds];
    [espWindow addSubview:espView];
    espWindow.rootViewController = [UIViewController new];
    espWindow.rootViewController.view.backgroundColor = [UIColor clearColor];
}

// ========== BALL POSITION HOOK (Long Shot + ESP) ==========

void(*old_BallGetPosition)(void *instance, float *outX, float *outY);
void BallGetPosition(void *instance, float *outX, float *outY) {
    old_BallGetPosition(instance, outX, outY);

    if ([switches isSwitchOn:@"ESP"] && outX && outY) {
        // Convert game coords to screen coords (scale factor)
        CGSize screen = UIScreen.mainScreen.bounds.size;
        float sx = (*outX / 100.0f) * screen.width;
        float sy = (*outY / 100.0f) * screen.height;
        NSValue *point = [NSValue valueWithCGPoint:CGPointMake(sx, sy)];

        @synchronized(espBallPositions) {
            // Avoid duplicates (same instance)
            uintptr_t key = (uintptr_t)instance % 16;
            if (key < (uintptr_t)espBallPositions.count) {
                espBallPositions[key] = point;
            } else {
                [espBallPositions addObject:point];
            }
        }
    }
}

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
+ (bool)isDeviceJailbroken       { return 0; }
+ (bool)isApplicationCrackd      { return 0; }
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
    HOOK(0x100000000 + 0x616AC, BallGetPosition,  old_BallGetPosition);
    HOOK(0x100000000 + 0x61698, BallSetPosition,  old_BallSetPosition);
    HOOK(0x100000000 + 0x616B8, BallSetVelocity,  old_BallSetVelocity);
    HOOK(0x100000000 + 0x61668, BallSetSpin,       old_BallSetSpin);
    HOOK(0x100000000 + 0x60F88, BallSetOpacity,    old_BallSetOpacity);

    // -- Switches --
    [switches addSwitch:@"ESP"
            description:@"Shows ball positions and pockets on screen"];

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
                maxVisibleSwitches:6
                menuWidth:260
                menuIcon:@"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wgARCAMgAvYDASIAAhEBAxEB/8QAGgABAAIDAQAAAAAAAAAAAAAAAAUGAQMEAv/EABQBAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhADEAAAAp8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8npHx5YFR4y6ctS8ln014TeIUTHmJE1mGwTe+uC09FOF72UDeXhVJAm3H2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwwxZIus+STjvIAZYGcejy9eQbzRt9YNOcAZMMjBkYDOzUJiWqIv2aPLlhaN4AAAAAAAAAAAAAAAAAAAAAAAAAAAAR8OS0B45AA6bKVTtt2Cv9fVHEhvrHGXTVSxclNF081LeTMf2SBy9kNFFu804XL3ShefFJ6Czc0fInFxWrpKNvuESQurf5OOUjfBdOugSpanP0AAAAAAAAAAAAAAAAAAAAAAAAAhCWgonoNPtg883RIkNvtXWVuTR5ZMU7lL4oOwunFCSZyRN58FG3dvENLJhnAAMmN8rYivyW+GJ3ZTeUvmKFsLvFx8gR/PZOgpOm1wxGgzOwOS+eqTZiQAAAAAAAAAAAAAAAAAAAAAA08tWOuOBnEocExNcZ38dc5CVjMYGWAAAZNlkrHsvFQ7Z0o7ZrMsZMMhO8NqPde4eEzgADOB68jOzUJuapQulfWApmLhWjkBO2Gg9xcWjeAAAAAAAAAAAAAAAAAAAIXngjLGTO2SsRwSbmPHJyRBLx3GPTGAzgM95Hu3iGWD15ZMWGvZLJWrjVDSZMvMsT1ckq4AAPWPR5xI6jjAB77Y/JYd9W7C27YWXIWAvvKUp3cJvtdOyX1FygAAAAAAAAAAAAAAAAArSFBkd3u0HjETAErEsmAMthqdu4jEsInMpqN8xWPB3xdu4CABnDJ2yEDOEJgForUqResAHr1aiP7uSvndw9O8jkuIhK+COx1854Bn14E9PUPcWqrWXoKW6OczaKtkvyJlgAAAAAAAAAAAAAABXeitAyJXXaBVtfKeE1KlQ33XyVDxc9hQOq5RxzTVS5S9KT4LypGwueiuyAktnsrULfqccRkzv5xgHRowAHrE4d23vEVJaoknlS5y6qN6Lvz1TnJeKkZkqO67ZKVquvooebzHlVnuSMLzUJCdKQ6OczbKlsL25OsAAAAAAAAAAAAAcHTSzXhkdei5nuqdMQd9o9ZNcFIyJT9N4jCp7NYlZun+i+wuueKCs0GciZjTQDZYqyL/zQ1iKH4sVdAM4ZMAZDqufH1iu8fAZwA7jixNxQtfvqMw8XGHdx+Q6ue9FSkp7Ue+TTJlHmeypl1p1l9lUwG+50WRLcAAAAAAAAAAAAQpGR2PRjCcJHn7qceZOMsRO+fWg3oKMLbWIvAAB6s1X9F8qkf0k/J0O1nJXr9wlObtQs9X2F6pdw4yogAyzgxNRN3NlXl6iAN3RazjklePO+u9hcK3D4GcDLPkWSti/ZocgWr1Dyh7ot7qRw2+mdJKQV7qJxAsM9QbkdgAAAAAAAAAANFKkYsGTrt/PDEdzLEQFngLGaou1Cm6LjBkI2awdBz9DWefIAM4FqlaBOk1VLhkoSahSbslBupW426UwwAdBNzmIgguV7PEtITJ59c9ZOqFwDOA97DVuzzmAAN6cIvosvs4Imy10hfE3zG6dpVsKr5sdcHbxC/ZhJsAAA"
                menuButton:@"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wgARCAMgAvYDASIAAhEBAxEB/8QAGgABAAIDAQAAAAAAAAAAAAAAAAUGAQMEAv/EABQBAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhADEAAAAp8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8npHx5YFR4y6ctS8ln014TeIUTHmJE1mGwTe+uC09FOF72UDeXhVJAm3H2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwwxZIus+STjvIAZYGcejy9eQbzRt9YNOcAZMMjBkYDOzUJiWqIv2aPLlhaN4AAAAAAAAAAAAAAAAAAAAAAAAAAAAR8OS0B45AA6bKVTtt2Cv9fVHEhvrHGXTVSxclNF081LeTMf2SBy9kNFFu804XL3ShefFJ6Czc0fInFxWrpKNvuESQurf5OOUjfBdOugSpanP0AAAAAAAAAAAAAAAAAAAAAAAAAhCWgonoNPtg883RIkNvtXWVuTR5ZMU7lL4oOwunFCSZyRN58FG3dvENLJhnAAMmN8rYivyW+GJ3ZTeUvmKFsLvFx8gR/PZOgpOm1wxGgzOwOS+eqTZiQAAAAAAAAAAAAAAAAAAAAAA08tWOuOBnEocExNcZ38dc5CVjMYGWAAAZNlkrHsvFQ7Z0o7ZrMsZMMhO8NqPde4eEzgADOB68jOzUJuapQulfWApmLhWjkBO2Gg9xcWjeAAAAAAAAAAAAAAAAAAAIXngjLGTO2SsRwSbmPHJyRBLx3GPTGAzgM95Hu3iGWD15ZMWGvZLJWrjVDSZMvMsT1ckq4AAPWPR5xI6jjAB77Y/JYd9W7C27YWXIWAvvKUp3cJvtdOyX1FygAAAAAAAAAAAAAAAAArSFBkd3u0HjETAErEsmAMthqdu4jEsInMpqN8xWPB3xdu4CABnDJ2yEDOEJgForUqResAHr1aiP7uSvndw9O8jkuIhK+COx1854Bn14E9PUPcWqrWXoKW6OczaKtkvyJlgAAAAAAAAAAAAAABXeitAyJXXaBVtfKeE1KlQ33XyVDxc9hQOq5RxzTVS5S9KT4LypGwueiuyAktnsrULfqccRkzv5xgHRowAHrE4d23vEVJaoknlS5y6qN6Lvz1TnJeKkZkqO67ZKVquvooebzHlVnuSMLzUJCdKQ6OczbKlsL25OsAAAAAAAAAAAAAcHTSzXhkdei5nuqdMQd9o9ZNcFIyJT9N4jCp7NYlZun+i+wuueKCs0GciZjTQDZYqyL/zQ1iKH4sVdAM4ZMAZDqufH1iu8fAZwA7jixNxQtfvqMw8XGHdx+Q6ue9FSkp7Ue+TTJlHmeypl1p1l9lUwG+50WRLcAAAAAAAAAAAAQpGR2PRjCcJHn7qceZOMsRO+fWg3oKMLbWIvAAB6s1X9F8qkf0k/J0O1nJXr9wlObtQs9X2F6pdw4yogAyzgxNRN3NlXl6iAN3RazjklePO+u9hcK3D4GcDLPkWSti/ZocgWr1Dyh7ot7qRw2+mdJKQV7qJxAsM9QbkdgAAAAAAAAAANFKkYsGTrt/PDEdzLEQFngLGaou1Cm6LjBkI2awdBz9DWefIAM4FqlaBOk1VLhkoSahSbslBupW426UwwAdBNzmIgguV7PEtITJ59c9ZOqFwDOA97DVuzzmAAN6cIvosvs4Imy10hfE3zG6dpVsKr5sdcHbxC/ZhJsAAA"
    ];
    setup();
}

// ========== LAUNCH ==========

static void didFinishLaunching(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef info) {
    timer(3) {
        setupESPOverlay();

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
