#import <Foundation/Foundation.h>
#import "Menu.h"

// ── COLOURS ──────────────────────────────────────────────────
#define FL_BG           [UIColor colorWithRed:0.10f green:0.10f blue:0.12f alpha:0.97f]
#define FL_PANEL        [UIColor colorWithRed:0.14f green:0.14f blue:0.17f alpha:1.0f]
#define FL_HEADER_BG    [UIColor colorWithRed:0.10f green:0.10f blue:0.12f alpha:1.0f]
#define FL_TAB_ACTIVE   [UIColor colorWithRed:0.55f green:0.25f blue:0.90f alpha:1.0f]
#define FL_TEXT_PRIMARY [UIColor whiteColor]
#define FL_TEXT_SEC     [UIColor colorWithWhite:0.65f alpha:1.0f]
#define FL_DIVIDER      [UIColor colorWithWhite:0.25f alpha:1.0f]
#define FL_CORNER       16.0f
#define FL_ROW_H        52.0f

// ── GLOBALS ───────────────────────────────────────────────────
static NSUserDefaults *defaults;
static CGFloat         gMenuWidth  = 700.0f;
static NSString       *gSwitchFont;
static UIColor        *gSwitchColor;
static UIButton       *gMenuButton;
static UIWindow       *gMainWindow;

// per-tab row arrays (0=Vis, 1=Auto, 2=Settings)
static NSMutableArray *gTabRows[3];

Menu     *menu     = nil;
Switches *switches = nil;

__attribute__((constructor))
static void initialize_menu() {
    menu = [[Menu alloc] init];
    switches = [[Switches alloc] init];
}

// ── IVAR STORAGE for array (C array can't be @property) ──────
static UIScrollView *gTabSV[3];

// ═══════════════════════════════════════════════════════════════
//  MENU
// ═══════════════════════════════════════════════════════════════
@interface Menu ()
@property (strong, nonatomic) UIView       *containerView;
@property (strong, nonatomic) UILabel      *titleLabel;
@property (strong, nonatomic) NSArray      *tabButtons;
@property (assign, nonatomic) FLTab         activeTab;
@property (assign, nonatomic) CGPoint       dragStart;
@property (assign, nonatomic) CGPoint       containerStart;
@end

@implementation Menu

- (id)initWithTitle:(NSString *)title_
         titleColor:(UIColor *)titleColor_
          titleFont:(NSString *)titleFont_
            credits:(NSString *)credits_
        headerColor:(UIColor *)headerColor_
     switchOffColor:(UIColor *)switchOffColor_
      switchOnColor:(UIColor *)switchOnColor_
    switchTitleFont:(NSString *)switchTitleFont_
  switchTitleColor:(UIColor *)switchTitleColor_
  infoButtonColor:(UIColor *)infoButtonColor_
 maxVisibleSwitches:(int)maxVisibleSwitches_
          menuWidth:(CGFloat)menuWidth_
           menuIcon:(NSString *)menuIconBase64_
         menuButton:(NSString *)menuButtonBase64_ {

    gMainWindow  = [UIApplication sharedApplication].keyWindow;
    defaults     = [NSUserDefaults standardUserDefaults];
    gMenuWidth   = menuWidth_;
    gSwitchFont  = switchTitleFont_;
    gSwitchColor = switchTitleColor_;

    for (int i = 0; i < 3; i++)
        gTabRows[i] = [NSMutableArray new];

    self = [super initWithFrame:gMainWindow.bounds];
    self.backgroundColor = [UIColor clearColor];
    self.layer.opacity   = 0.0f;
    [gMainWindow addSubview:self];

    // dim overlay
    UIView *dim = [[UIView alloc] initWithFrame:self.bounds];
    dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55f];
    [self addSubview:dim];

    // card
    CGFloat cw = gMenuWidth, ch = 420.0f;
    _containerView = [[UIView alloc] initWithFrame:CGRectMake(
        (self.bounds.size.width - cw)/2,
        (self.bounds.size.height - ch)/2,
        cw, ch)];
    _containerView.backgroundColor      = FL_BG;
    _containerView.layer.cornerRadius   = FL_CORNER;
    _containerView.layer.masksToBounds  = YES;
    [self addSubview:_containerView];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    [_containerView addGestureRecognizer:pan];

    // header
    CGFloat hh = 56.0f;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,cw,hh)];
    header.backgroundColor = FL_HEADER_BG;
    [_containerView addSubview:header];

    UILabel *gem = [[UILabel alloc] initWithFrame:CGRectMake(16,0,32,hh)];
    gem.text      = @"✦";
    gem.textColor = FL_TAB_ACTIVE;
    gem.font      = [UIFont boldSystemFontOfSize:20];
    [header addSubview:gem];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52,0,cw-100,hh)];
    _titleLabel.text      = title_;
    _titleLabel.textColor = FL_TEXT_PRIMARY;
    _titleLabel.font      = [UIFont boldSystemFontOfSize:17];
    [header addSubview:_titleLabel];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(cw-44, 0, 44, hh);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:17];
    [close setTitleColor:FL_TEXT_SEC forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:close];

    UIView *hdiv = [[UIView alloc] initWithFrame:CGRectMake(0,hh-0.5f,cw,0.5f)];
    hdiv.backgroundColor = FL_DIVIDER;
    [_containerView addSubview:hdiv];

    // tab bar
    CGFloat tabY = hh, tabH = 44.0f, tabW = cw/3.0f;
    NSArray *tabNames = @[@"Visualization", @"Automation", @"Settings"];
    NSMutableArray *tabBtns = [NSMutableArray new];
    for (int i = 0; i < 3; i++) {
        UIButton *tb = [UIButton buttonWithType:UIButtonTypeSystem];
        tb.frame = CGRectMake(i*tabW, tabY, tabW, tabH);
        tb.tag   = i;
        [tb setTitle:tabNames[i] forState:UIControlStateNormal];
        tb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [tb addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_containerView addSubview:tb];
        [tabBtns addObject:tb];
    }
    _tabButtons = [tabBtns copy];

    UIView *tabLine = [[UIView alloc] initWithFrame:CGRectMake(0, tabY+tabH-0.5f, cw, 0.5f)];
    tabLine.backgroundColor = FL_DIVIDER;
    [_containerView addSubview:tabLine];

    // scroll views — stored in static C array (avoids @property array issue)
    CGFloat svY = tabY+tabH, svH = ch-svY;
    for (int i = 0; i < 3; i++) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0,svY,cw,svH)];
        sv.backgroundColor = [UIColor clearColor];
        sv.showsVerticalScrollIndicator = YES;
        sv.hidden = (i != 0);
        gTabSV[i] = sv;
        [_containerView addSubview:sv];
    }

    _activeTab = FLTabVisualization;
    [self refreshTabAppearance];

    // เรียก Setup
    if ([switches respondsToSelector:@selector(setupFluoriteLayout)]) {
        [switches setupFluoriteLayout];
    }

    return self;
}

- (void)tabTapped:(UIButton *)sender {
    _activeTab = (FLTab)sender.tag;
    for (int i = 0; i < 3; i++)
        gTabSV[i].hidden = (i != _activeTab);
    [self refreshTabAppearance];
}

- (void)refreshTabAppearance {
    for (int i = 0; i < 3; i++) {
        UIButton *tb = _tabButtons[i];
        BOOL active  = (i == _activeTab);
        [tb setTitleColor:active ? FL_TAB_ACTIVE : FL_TEXT_SEC forState:UIControlStateNormal];
        // remove old pill
        for (UIView *v in tb.subviews)
            if (v.tag == 555) [v removeFromSuperview];
        if (active) {
            CGFloat pw = tb.bounds.size.width * 0.7f;
            UIView *pill = [[UIView alloc] initWithFrame:CGRectMake(
                (tb.bounds.size.width-pw)/2, tb.bounds.size.height-3, pw, 3)];
            pill.tag                = 555;
            pill.backgroundColor    = FL_TAB_ACTIVE;
            pill.layer.cornerRadius = 1.5f;
            [tb addSubview:pill];
        }
    }
}

- (void)addSwitchToMenu:(id)switch_ {
    [self addSwitchToMenu:switch_ tab:FLTabVisualization];
}

- (void)addSwitchToMenu:(id)switch_ tab:(FLTab)tab {
    NSMutableArray *rows = gTabRows[tab];
    CGFloat rowY = rows.count * FL_ROW_H;

    UIView *row = (UIView *)switch_;
    row.frame = CGRectMake(0, rowY, gMenuWidth, FL_ROW_H);
    [rows addObject:switch_];

    UIScrollView *sv = gTabSV[tab];
    [sv addSubview:row];
    sv.contentSize = CGSizeMake(gMenuWidth, rowY + FL_ROW_H + 8);

    // restore saved toggle state
    if ([switch_ respondsToSelector:@selector(getPreferencesKey)]) {
        NSString *key = [switch_ performSelector:@selector(getPreferencesKey)];
        BOOL saved    = [defaults boolForKey:key];
        if ([switch_ isKindOfClass:[OffsetSwitch class]]) {
            OffsetSwitch *os = (OffsetSwitch *)switch_;
            [os restoreState:saved];
        }
    }

    // row divider
    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(16, FL_ROW_H-0.5f, gMenuWidth-32, 0.5f)];
    div.backgroundColor = FL_DIVIDER;
    [row addSubview:div];
}

- (void)handlePan:(UIPanGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        _dragStart      = [gr locationInView:self];
        _containerStart = _containerView.center;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint now = [gr locationInView:self];
        _containerView.center = CGPointMake(
            _containerStart.x + now.x - _dragStart.x,
            _containerStart.y + now.y - _dragStart.y);
    }
}

- (void)showMenuButton {
    CGFloat s = 52.0f;
    gMenuButton = [[UIButton alloc] initWithFrame:CGRectMake(
        20, gMainWindow.bounds.size.height/2 - s/2, s, s)];
    gMenuButton.backgroundColor    = FL_TAB_ACTIVE;
    gMenuButton.layer.cornerRadius = s/2;
    gMenuButton.layer.shadowColor  = [UIColor colorWithRed:0.55f green:0.25f blue:0.90f alpha:0.7f].CGColor;
    gMenuButton.layer.shadowOpacity = 0.9f;
    gMenuButton.layer.shadowRadius  = 12.0f;
    gMenuButton.layer.shadowOffset  = CGSizeMake(0,4);

    UILabel *lbl = [[UILabel alloc] initWithFrame:gMenuButton.bounds];
    lbl.text          = @"🎱";
    lbl.font          = [UIFont systemFontOfSize:26];
    lbl.textAlignment = NSTextAlignmentCenter;
    [gMenuButton addSubview:lbl];

    [gMenuButton addTarget:self action:@selector(openMenu)
         forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(dragButton:)];
    [gMenuButton addGestureRecognizer:pan];

    [gMainWindow addSubview:gMenuButton];
}

- (void)dragButton:(UIPanGestureRecognizer *)gr {
    CGPoint t = [gr translationInView:gMainWindow];
    gMenuButton.center = CGPointMake(gMenuButton.center.x+t.x, gMenuButton.center.y+t.y);
    [gr setTranslation:CGPointZero inView:gMainWindow];
}

- (void)openMenu {
    [gMainWindow bringSubviewToFront:self];
    [UIView animateWithDuration:0.25 delay:0
         usingSpringWithDamping:0.82f initialSpringVelocity:0.3f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{ self.layer.opacity = 1.0f; }
                     completion:nil];
}

- (void)closeMenu {
    [UIView animateWithDuration:0.18 animations:^{ self.layer.opacity = 0.0f; }];
}

- (void)showPopup:(NSString *)title_ description:(NSString *)description_ {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.customViewColor           = FL_TAB_ACTIVE;
    alert.showAnimationType         = SCLAlertViewShowAnimationSlideInFromCenter;
    alert.shouldDismissOnTapOutside = YES;
    [alert showInfo:nil
           subTitle:[NSString stringWithFormat:@"%@\n\n%@", title_, description_]
   closeButtonTitle:@"OK"
           duration:0];
}

@end


// ═══════════════════════════════════════════════════════════════
//  OFFSET SWITCH
// ═══════════════════════════════════════════════════════════════
@implementation OffsetSwitch {
    std::vector<MemoryPatch> memoryPatches;
    UISwitch *toggleSwitch;
}

- (id)initHackNamed:(NSString *)hackName_
        description:(NSString *)description_
            offsets:(std::vector<uint64_t>)offsets_
              bytes:(std::vector<std::string>)bytes_ {

    self = [super initWithFrame:CGRectMake(0, 0, gMenuWidth, FL_ROW_H)];
    if(self) {
        preferencesKey   = hackName_;
        switchDescription = description_;

        if (offsets_.size() != bytes_.size()) {
            [menu showPopup:@"Invalid input count"
                description:[NSString stringWithFormat:@"Offsets (%d) ≠ bytes (%d)",
                             (int)offsets_.size(), (int)bytes_.size()]];
        } else {
            for (size_t i = 0; i < offsets_.size(); i++) {
                MemoryPatch p = MemoryPatch::createWithHex(NULL, offsets_[i], bytes_[i]);
                if (p.isValid()) memoryPatches.push_back(p);
                else [menu showPopup:@"Invalid patch"
                         description:[NSString stringWithFormat:@"Bad offset: 0x%llx", offsets_[i]]];
            }
        }

        self.backgroundColor = [UIColor clearColor];

        toggleSwitch = [[UISwitch alloc] init];
        toggleSwitch.onTintColor = FL_TAB_ACTIVE;
        toggleSwitch.frame = CGRectMake(
            gMenuWidth - toggleSwitch.frame.size.width - 16,
            (FL_ROW_H  - toggleSwitch.frame.size.height)/2,
            toggleSwitch.frame.size.width,
            toggleSwitch.frame.size.height);
        [toggleSwitch addTarget:self action:@selector(toggleChanged:)
              forControlEvents:UIControlEventValueChanged];
        [self addSubview:toggleSwitch];

        switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(
            16, 0, gMenuWidth - toggleSwitch.frame.size.width - 48, FL_ROW_H)];
        switchLabel.text      = hackName_;
        switchLabel.textColor = FL_TEXT_PRIMARY;
        switchLabel.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [self addSubview:switchLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(rowDoubleTapped:)];
        tap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)restoreState:(BOOL)on {
    toggleSwitch.on     = on;
    self.backgroundColor = on
        ? [FL_TAB_ACTIVE colorWithAlphaComponent:0.15f]
        : [UIColor clearColor];
}

- (void)rowDoubleTapped:(UITapGestureRecognizer *)gr { [self showInfo]; }

- (void)showInfo {
    [menu showPopup:preferencesKey description:switchDescription];
}

- (void)toggleChanged:(UISwitch *)sender {
    BOOL on = sender.isOn;
    [defaults setBool:on forKey:preferencesKey];
    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundColor = on
            ? [FL_TAB_ACTIVE colorWithAlphaComponent:0.15f]
            : [UIColor clearColor];
    }];
    for (auto &p : memoryPatches)
        on ? p.Modify() : p.Restore();
}

- (NSString *)getPreferencesKey  { return preferencesKey; }
- (NSString *)getDescription     { return switchDescription; }
- (std::vector<MemoryPatch>)getMemoryPatches { return memoryPatches; }

@end


// ═══════════════════════════════════════════════════════════════
//  TEXT-FIELD SWITCH
// ═══════════════════════════════════════════════════════════════
// แก้ Error redeclare: ไม่ต้องสร้าง { NSString *preferencesKey; UILabel *switchLabel; } ซ้ำ
@implementation TextFieldSwitch {
    UITextField *textfieldValue;
}

- (id)initTextfieldNamed:(NSString *)hackName_
             description:(NSString *)description_
       inputBorderColor:(UIColor *)inputBorderColor_ {

    self = [super initWithFrame:CGRectMake(0, 0, gMenuWidth, FL_ROW_H)];
    if(self) {
        preferencesKey    = hackName_;
        switchValueKey    = [hackName_ stringByApplyingTransform:
                                NSStringTransformLatinToCyrillic reverse:NO];
        switchDescription = description_;

        self.backgroundColor = [UIColor clearColor];

        switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, gMenuWidth*0.5f, 22)];
        switchLabel.text      = hackName_;
        switchLabel.textColor = FL_TEXT_PRIMARY;
        switchLabel.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [self addSubview:switchLabel];

        textfieldValue = [[UITextField alloc] initWithFrame:CGRectMake(
            gMenuWidth*0.52f, 10, gMenuWidth*0.36f, 30)];
        textfieldValue.layer.borderColor  = inputBorderColor_.CGColor;
        textfieldValue.layer.borderWidth  = 1.5f;
        textfieldValue.layer.cornerRadius = 8.0f;
        textfieldValue.textColor          = FL_TEXT_PRIMARY;
        textfieldValue.textAlignment      = NSTextAlignmentCenter;
        textfieldValue.font               = [UIFont systemFontOfSize:13];
        textfieldValue.backgroundColor    = FL_PANEL;
        textfieldValue.delegate           = self;

        NSString *saved = [defaults objectForKey:switchValueKey];
        if (saved) textfieldValue.text = saved;
        [self addSubview:textfieldValue];
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    switchValueKey = [preferencesKey stringByApplyingTransform:
                        NSStringTransformLatinToCyrillic reverse:NO];
    [defaults setObject:tf.text forKey:switchValueKey];
    [tf resignFirstResponder];
    return YES;
}

- (NSString *)getSwitchValueKey { return switchValueKey; }

@end


// ═══════════════════════════════════════════════════════════════
//  SLIDER SWITCH
// ═══════════════════════════════════════════════════════════════
@implementation SliderSwitch {
    UISlider *sliderValue;
}

- (id)initSliderNamed:(NSString *)hackName_
          description:(NSString *)description_
         minimumValue:(float)minimumValue_
         maximumValue:(float)maximumValue_
          sliderColor:(UIColor *)sliderColor_ {

    self = [super initWithFrame:CGRectMake(0, 0, gMenuWidth, FL_ROW_H)];
    if(self) {
        preferencesKey    = hackName_;
        switchValueKey    = [hackName_ stringByApplyingTransform:
                                NSStringTransformLatinToCyrillic reverse:NO];
        switchDescription = description_;

        self.backgroundColor = [UIColor clearColor];

        switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, gMenuWidth*0.5f, 20)];
        switchLabel.text      = hackName_;
        switchLabel.textColor = FL_TEXT_PRIMARY;
        switchLabel.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [self addSubview:switchLabel];

        sliderValue = [[UISlider alloc] initWithFrame:CGRectMake(16, 28, gMenuWidth-100, 20)];
        sliderValue.minimumValue          = minimumValue_;
        sliderValue.maximumValue          = maximumValue_;
        sliderValue.thumbTintColor        = sliderColor_;
        sliderValue.minimumTrackTintColor = FL_TAB_ACTIVE;
        sliderValue.maximumTrackTintColor = FL_DIVIDER;
        sliderValue.continuous            = YES;
        [sliderValue addTarget:self action:@selector(sliderChanged:)
             forControlEvents:UIControlEventValueChanged];

        float saved = [defaults floatForKey:switchValueKey];
        if (saved != 0) sliderValue.value = saved;

        UILabel *valLbl = [[UILabel alloc] initWithFrame:CGRectMake(gMenuWidth-78, 28, 62, 20)];
        valLbl.tag       = 77;
        valLbl.textColor = FL_TEXT_SEC;
        valLbl.font      = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
        valLbl.text      = [NSString stringWithFormat:@"%.2f", sliderValue.value];
        [self addSubview:valLbl];
        [self addSubview:sliderValue];
    }
    return self;
}

- (void)sliderChanged:(UISlider *)s {
    switchValueKey = [preferencesKey stringByApplyingTransform:
                        NSStringTransformLatinToCyrillic reverse:NO];
    [defaults setFloat:s.value forKey:switchValueKey];
    UILabel *lbl = (UILabel *)[self viewWithTag:77];
    lbl.text = [NSString stringWithFormat:@"%.2f", s.value];
}

@end

// ═══════════════════════════════════════════════════════════════
//  ACTION BUTTON (Standalone Button Row)
// ═══════════════════════════════════════════════════════════════
@implementation ActionButton {
    void (^action)(void);
}

- (id)initButtonNamed:(NSString *)btnName
             colWidth:(CGFloat)colWidth
          actionBlock:(void (^)(void))actionBlock {
    // แก้ไข: สืบทอดจาก UIView ทำให้ใช้ [super initWithFrame:] และ [self addSubview:] ได้
    self = [super initWithFrame:CGRectMake(0, 0, colWidth, FL_ROW_H)];
    if (self) {
        action = actionBlock;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(16, (FL_ROW_H - 30)/2, colWidth - 32, 30);
        btn.backgroundColor = FL_PANEL;
        btn.layer.cornerRadius = 8.0f;
        [btn setTitle:btnName forState:UIControlStateNormal];
        [btn setTitleColor:FL_TEXT_PRIMARY forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        [btn addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    return self;
}

- (void)buttonTapped {
    if (action) action();
}

@end


// ═══════════════════════════════════════════════════════════════
//  SWITCHES BUILDER API
// ═══════════════════════════════════════════════════════════════
@implementation Switches

- (void)setupFluoriteLayout {
    // วาง Method นี้ทิ้งไว้เพื่อไม่ให้ Error ใน Menu.mm
    // คุณสามารถไปเรียกการสร้างสวิตช์ต่างๆ ของคุณใน Tweak.xm ได้ตามปกติ
}

- (void)addSwitch:(NSString *)hackName_ description:(NSString *)description_ {
    [self addSwitch:hackName_ description:description_ tab:FLTabVisualization];
}

- (void)addSwitch:(NSString *)hackName_ description:(NSString *)description_ tab:(FLTab)tab {
    OffsetSwitch *s = [[OffsetSwitch alloc]
        initHackNamed:hackName_ description:description_
              offsets:std::vector<uint64_t>{}
                bytes:std::vector<std::string>{}];
    [menu addSwitchToMenu:s tab:tab];
}

- (void)addOffsetSwitch:(NSString *)hackName_
            description:(NSString *)description_
                offsets:(std::initializer_list<uint64_t>)offsets_
                  bytes:(std::initializer_list<std::string>)bytes_ {
    [self addOffsetSwitch:hackName_ description:description_
                  offsets:offsets_ bytes:bytes_ tab:FLTabVisualization];
}

- (void)addOffsetSwitch:(NSString *)hackName_
            description:(NSString *)description_
                offsets:(std::initializer_list<uint64_t>)offsets_
                  bytes:(std::initializer_list<std::string>)bytes_
                    tab:(FLTab)tab {
    std::vector<uint64_t>    ov(offsets_.begin(), offsets_.end());
    std::vector<std::string> bv(bytes_.begin(),   bytes_.end());
    OffsetSwitch *s = [[OffsetSwitch alloc]
        initHackNamed:hackName_ description:description_ offsets:ov bytes:bv];
    [menu addSwitchToMenu:s tab:tab];
}

- (void)addTextfieldSwitch:(NSString *)hackName_
               description:(NSString *)description_
         inputBorderColor:(UIColor *)inputBorderColor_ {
    TextFieldSwitch *s = [[TextFieldSwitch alloc]
        initTextfieldNamed:hackName_ description:description_
          inputBorderColor:inputBorderColor_];
    [menu addSwitchToMenu:s tab:FLTabVisualization];
}

- (void)addSliderSwitch:(NSString *)hackName_
            description:(NSString *)description_
           minimumValue:(float)minimumValue_
           maximumValue:(float)maximumValue_
            sliderColor:(UIColor *)sliderColor_ {
    SliderSwitch *s = [[SliderSwitch alloc]
        initSliderNamed:hackName_ description:description_
           minimumValue:minimumValue_ maximumValue:maximumValue_
            sliderColor:sliderColor_];
    [menu addSwitchToMenu:s tab:FLTabVisualization];
}

- (void)addButton:(NSString *)btnName 
           action:(void (^)(void))actionBlock 
              tab:(FLTab)tab {
        ActionButton *btn = [[ActionButton alloc] initButtonNamed:btnName colWidth:(gMenuWidth/3.0f) action:actionBlock];
    [menu addSwitchToMenu:btn tab:tab];
}

- (NSString *)getValueFromSwitch:(NSString *)name {
    NSString *key = [name stringByApplyingTransform:
                        NSStringTransformLatinToCyrillic reverse:NO];
    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (str) return str;
    float fv = [[NSUserDefaults standardUserDefaults] floatForKey:key];
    if (fv != 0) return [NSString stringWithFormat:@"%f", fv];
    return nil;
}

- (bool)isSwitchOn:(NSString *)switchName {
    return [[NSUserDefaults standardUserDefaults] boolForKey:switchName];
}

@end
