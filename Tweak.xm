#import "Macros.h"

// ========================================
// 8BALL POOL - MOD TWEAK  (FLUORITE UI)
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
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick:(CADisplayLink *)link { [self setNeedsDisplay]; }

- (void)drawRect:(CGRect)rect {
    if (![switches isSwitchOn:@"ESP"]) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 2.5f);

    @synchronized(espBallPositions) {
        for (NSValue *val in espBallPositions) {
            CGPoint p = [val CGPointValue];
            if (p.x < 0 || p.y < 0 || p.x > self.bounds.size.width || p.y > self.bounds.size.height) continue;
            float radius = 14.0f;
            CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:1 green:0 blue:0 alpha:0.9f].CGColor);
            CGContextStrokeEllipseInRect(ctx, CGRectMake(p.x-radius, p.y-radius, radius*2, radius*2));
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:1 green:0 blue:0 alpha:0.4f].CGColor);
            CGContextFillEllipseInRect(ctx, CGRectMake(p.x-4, p.y-4, 8, 8));
            NSDictionary *attrs = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:10],NSForegroundColorAttributeName:[UIColor whiteColor]};
            [@"Ball" drawAtPoint:CGPointMake(p.x+radius+3, p.y-7) withAttributes:attrs];
        }
    }

    CGSize s = self.bounds.size;
    NSArray *pockets = @[
        [NSValue valueWithCGPoint:CGPointMake(s.width*0.05f, s.height*0.12f)],
        [NSValue valueWithCGPoint:CGPointMake(s.width*0.50f, s.height*0.10f)],
        [NSValue valueWithCGPoint:CGPointMake(s.width*0.95f, s.height*0.12f)],
        [NSValue valueWithCGPoint:CGPointMake(s.width*0.05f, s.height*0.88f)],
        [NSValue valueWithCGPoint:CGPointMake(s.width*0.50f, s.height*0.90f)],
        [NSValue valueWithCGPoint:CGPointMake(s.width*0.95f, s.height*0.88f)],
    ];
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:1 green:1 blue:0 alpha:0.8f].CGColor);
    CGContextSetLineWidth(ctx, 2.0f);
    for (NSValue *val in pockets) {
        CGPoint p = [val CGPointValue]; float r = 18.0f;
        CGContextStrokeEllipseInRect(ctx, CGRectMake(p.x-r, p.y-r, r*2, r*2));
        NSDictionary *attrs = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:9],NSForegroundColorAttributeName:[UIColor yellowColor]};
        [@"Pocket" drawAtPoint:CGPointMake(p.x-15, p.y+r+2) withAttributes:attrs];
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

// ========== HOOKS ==========

void(*old_BallGetPosition)(void *instance, float *outX, float *outY);
void BallGetPosition(void *instance, float *outX, float *outY) {
    old_BallGetPosition(instance, outX, outY);
    if ([switches isSwitchOn:@"ESP"] && outX && outY) {
        CGSize screen = UIScreen.mainScreen.bounds.size;
        float sx = (*outX / 100.0f) * screen.width;
        float sy = (*outY / 100.0f) * screen.height;
        NSValue *point = [NSValue valueWithCGPoint:CGPointMake(sx, sy)];
        @synchronized(espBallPositions) {
            uintptr_t key = (uintptr_t)instance % 16;
            if (key < (uintptr_t)espBallPositions.count) espBallPositions[key] = point;
            else [espBallPositions addObject:point];
        }
    }
}

void(*old_BallSetPosition)(void *instance, float x, float y);
void BallSetPosition(void *instance, float x, float y) {
    if ([switches isSwitchOn:@"Long Shot"]) { x *= 2.0f; y *= 2.0f; }
    old_BallSetPosition(instance, x, y);
}

void(*old_BallSetVelocity)(void *instance, float x, float y);
void BallSetVelocity(void *instance, float x, float y) {
    if ([switches isSwitchOn:@"Power Boost"]) { x *= powerMultiplier; y *= powerMultiplier; }
    old_BallSetVelocity(instance, x, y);
}

void(*old_BallSetSpin)(void *instance, float x, float y);
void BallSetSpin(void *instance, float x, float y) {
    if ([switches isSwitchOn:@"Perfect Spin"]) { x *= 0.5f; y *= 0.5f; }
    old_BallSetSpin(instance, x, y);
}

void(*old_BallSetOpacity)(void *instance, unsigned char opacity);
void BallSetOpacity(void *instance, unsigned char opacity) {
    if ([switches isSwitchOn:@"Ghost Balls"]) opacity = 128;
    old_BallSetOpacity(instance, opacity);
}

%hook UserInfo
- (int)lowAimRatio {
    if ([switches isSwitchOn:@"Auto Aim"]) return -999;
    return %orig;
}
%end

// ========== JAILBREAK BYPASS ==========

%hook JailBreakChecks
+ (bool)isDeviceJailbroken        { return 0; }
+ (bool)isApplicationCrackd       { return 0; }
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

// ========== SETUP ==========

void setup() {
    HOOK(0x100000000 + 0x616AC, BallGetPosition,  old_BallGetPosition);
    HOOK(0x100000000 + 0x61698, BallSetPosition,  old_BallSetPosition);
    HOOK(0x100000000 + 0x616B8, BallSetVelocity,  old_BallSetVelocity);
    HOOK(0x100000000 + 0x61668, BallSetSpin,       old_BallSetSpin);
    HOOK(0x100000000 + 0x60F88, BallSetOpacity,    old_BallSetOpacity);

    // ── Visualization tab ──
    [switches addSwitch:@"ESP"
            description:@"Shows ball positions and pockets on screen"
                    tab:FLTabVisualization];

    [switches addSwitch:@"Long Shot"
            description:@"Extends shot range 2x"
                    tab:FLTabVisualization];

    [switches addSwitch:@"Power Boost"
            description:@"Doubles ball velocity"
                    tab:FLTabVisualization];

    [switches addSwitch:@"Perfect Spin"
            description:@"Reduces unwanted spin for better control"
                    tab:FLTabVisualization];

    [switches addSwitch:@"Ghost Balls"
            description:@"Makes balls 50% transparent"
                    tab:FLTabVisualization];

    // ── Automation tab ──
    [switches addSwitch:@"Auto Aim"
            description:@"Extends aim line to max range"
                    tab:FLTabAutomation];

    // ── Settings tab ──
    [switches addOffsetSwitch:@"Always First Break"
                  description:@"Always get the first break shot"
                      offsets:{0x100000000 + 0xD0B04}
                        bytes:{"0x200080D2C0035FD6"}
                          tab:FLTabSettings];

    [switches addOffsetSwitch:@"Anti Jailbreak"
                  description:@"Bypass jailbreak detection"
                      offsets:{0x100000000 + 0x616AC}
                        bytes:{"0x200080D2C0035FD6"}
                          tab:FLTabSettings];
}

// ========== MENU CONFIG ==========

void setupMenu() {
    menu = [[Menu alloc]
        initWithTitle:@"8Ball Pool"
           titleColor:[UIColor whiteColor]
            titleFont:@"AvenirNext-Bold"
              credits:@"8Ball Pool Mod — not for sale.\n\nEnjoy!"
          headerColor:[UIColor colorWithRed:0.10f green:0.10f blue:0.12f alpha:1.0f]
       switchOffColor:[UIColor colorWithRed:0.14f green:0.14f blue:0.17f alpha:1.0f]
        switchOnColor:[UIColor colorWithRed:0.55f green:0.25f blue:0.90f alpha:1.0f]
      switchTitleFont:@"AvenirNext-Medium"
    switchTitleColor:[UIColor whiteColor]
    infoButtonColor:[UIColor colorWithRed:0.55f green:0.25f blue:0.90f alpha:1.0f]
   maxVisibleSwitches:8
            menuWidth:700
             menuIcon:@""
           menuButton:@""];
    setup();
}

// ========== LAUNCH ==========

static void didFinishLaunching(CFNotificationCenterRef center, void *observer,
                                CFStringRef name, const void *object,
                                CFDictionaryRef info) {
    timer(3) {
        setupESPOverlay();

        SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
        [alert addButton:@"Let's Play!" actionBlock:^(void) {
            timer(1) {
                setupMenu();
                [menu showMenuButton];
            });
        }];
        alert.shouldDismissOnTapOutside = NO;
        alert.customViewColor = [UIColor colorWithRed:0.55f green:0.25f blue:0.90f alpha:1.0f];
        alert.showAnimationType = SCLAlertViewShowAnimationSlideInFromCenter;
        [alert showSuccess:nil
                 subTitle:@"8Ball Pool loaded!\n\nTap the button to open the menu."
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
