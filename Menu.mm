//
//  Menu.mm  — FLUORITE-style dark modal UI
//

#import "Menu.h"

// ── COLOURS ──────────────────────────────────────────────────
#define FL_BG           [UIColor colorWithRed:0.04f green:0.04f blue:0.06f alpha:0.98f]
#define FL_HEADER_BG    [UIColor clearColor]
#define FL_TAB_ACTIVE   [UIColor colorWithRed:0.60f green:0.33f blue:0.90f alpha:1.0f]
#define FL_TEXT_PRIMARY [UIColor whiteColor]
#define FL_TEXT_SEC     [UIColor colorWithWhite:0.60f alpha:1.0f]
#define FL_DIVIDER      [UIColor colorWithWhite:1.0f alpha:0.05f]
#define FL_CORNER       28.0f
#define FL_ROW_H        44.0f

static NSUserDefaults *defaults;
static CGFloat         gMenuWidth  = 780.0f; // กว้างขึ้นแบบ UI บน iPad
static UIColor        *gSwitchColor;
static UIButton       *gMenuButton;
static UIWindow       *gMainWindow;

// per-tab & per-column arrays (3 Tabs, 3 Columns)
static NSMutableArray *gTabCols[3][3];
static UIScrollView   *gTabSV[3];

Menu     *menu     = [[Menu alloc] init];
Switches *switches = [[Switches alloc] init];

@implementation Menu {
    UIView *_containerView;
    NSArray *_tabButtons;
    FLTab _activeTab;
    CGPoint _dragStart;
    CGPoint _containerStart;
}

- (id)initWithTitle:(NSString *)title_ titleColor:(UIColor *)titleColor_ titleFont:(NSString *)titleFont_ credits:(NSString *)credits_ headerColor:(UIColor *)headerColor_ switchOffColor:(UIColor *)switchOffColor_ switchOnColor:(UIColor *)switchOnColor_ switchTitleFont:(NSString *)switchTitleFont_ switchTitleColor:(UIColor *)switchTitleColor_ infoButtonColor:(UIColor *)infoButtonColor_ maxVisibleSwitches:(int)maxVisibleSwitches_ menuWidth:(CGFloat)menuWidth_ menuIcon:(NSString *)menuIconBase64_ menuButton:(NSString *)menuButtonBase64_ {

    gMainWindow  = [UIApplication sharedApplication].keyWindow;
    defaults     = [NSUserDefaults standardUserDefaults];
    gMenuWidth   = menuWidth_ > 0 ? menuWidth_ : 780.0f;
    gSwitchColor = switchTitleColor_;

    for (int t = 0; t < 3; t++)
        for (int c = 0; c < 3; c++)
            gTabCols[t][c] = [NSMutableArray new];

    self = [super initWithFrame:gMainWindow.bounds];
    self.layer.opacity = 0.0f;
    [gMainWindow addSubview:self];

    // Background Dim
    UIView *dim = [[UIView alloc] initWithFrame:self.bounds];
    dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
    [self addSubview:dim];

    // Card Container
    CGFloat ch = 450.0f;
    _containerView = [[UIView alloc] initWithFrame:CGRectMake((self.bounds.size.width - gMenuWidth)/2, (self.bounds.size.height - ch)/2, gMenuWidth, ch)];
    _containerView.backgroundColor = FL_BG;
    _containerView.layer.cornerRadius = FL_CORNER;
    _containerView.layer.borderWidth = 1.0f;
    _containerView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.06f].CGColor;
    [self addSubview:_containerView];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_containerView addGestureRecognizer:pan];

    // Header Toolbar
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, gMenuWidth, 70)];
    [_containerView addSubview:header];

    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, 150, 70)];
    logo.text = @"🪷 FLUORITE";
    logo.textColor = [UIColor whiteColor];
    logo.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    [header addSubview:logo];

    // Tab Bar (Center)
    CGFloat tabTotalW = 300.0f;
    UIView *tabBg = [[UIView alloc] initWithFrame:CGRectMake((gMenuWidth - tabTotalW)/2, 18, tabTotalW, 34)];
    tabBg.backgroundColor = [UIColor colorWithRed:0.08f green:0.08f blue:0.11f alpha:1.0f];
    tabBg.layer.cornerRadius = 17.0f;
    [header addSubview:tabBg];

    NSArray *tabNames = @[@"Visualization", @"Automation", @"Settings"];
    NSMutableArray *tabBtns = [NSMutableArray new];
    for (int i = 0; i < 3; i++) {
        UIButton *tb = [UIButton buttonWithType:UIButtonTypeSystem];
        tb.frame = CGRectMake(i*(tabTotalW/3), 0, tabTotalW/3, 34);
        tb.tag = i;
        [tb setTitle:tabNames[i] forState:UIControlStateNormal];
        tb.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [tb addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [tabBg addSubview:tb];
        [tabBtns addObject:tb];
    }
    _tabButtons = [tabBtns copy];

    // Close Button
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(gMenuWidth-50, 0, 50, 70);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:FL_TEXT_SEC forState:UIControlStateNormal];
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:close];

    // Divider Header
    UIView *hdiv = [[UIView alloc] initWithFrame:CGRectMake(0, 69.5f, gMenuWidth, 0.5f)];
    hdiv.backgroundColor = FL_DIVIDER;
    [_containerView addSubview:hdiv];

    // Content ScrollViews + Column Dividers
    CGFloat svY = 70.0f, svH = ch - svY;
    for (int t = 0; t < 3; t++) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, svY, gMenuWidth, svH)];
        sv.hidden = (t != 0);
        
        // Add vertical lines between columns
        UIView *vLine1 = [[UIView alloc] initWithFrame:CGRectMake(gMenuWidth/3.0f, 16, 1, svH - 32)];
        vLine1.backgroundColor = FL_DIVIDER;
        [sv addSubview:vLine1];
        
        UIView *vLine2 = [[UIView alloc] initWithFrame:CGRectMake((gMenuWidth*2)/3.0f, 16, 1, svH - 32)];
        vLine2.backgroundColor = FL_DIVIDER;
        [sv addSubview:vLine2];

        gTabSV[t] = sv;
        [_containerView addSubview:sv];
    }

    _activeTab = FLTabVisualization;
    [self refreshTabAppearance];
    
    // Auto Load Setup
    [switches setupFluoriteLayout];
    
    return self;
}

- (void)tabTapped:(UIButton *)sender {
    _activeTab = (FLTab)sender.tag;
    for (int i = 0; i < 3; i++) gTabSV[i].hidden = (i != _activeTab);
    [self refreshTabAppearance];
}

- (void)refreshTabAppearance {
    for (int i = 0; i < 3; i++) {
        UIButton *tb = _tabButtons[i];
        BOOL active  = (i == _activeTab);
        [tb setTitleColor:active ? [UIColor whiteColor] : FL_TEXT_SEC forState:UIControlStateNormal];
        tb.backgroundColor = active ? FL_TAB_ACTIVE : [UIColor clearColor];
        tb.layer.cornerRadius = 17.0f;
    }
}

- (void)addSwitchToMenu:(id)switchView  tab:(FLTab)tab column:(int)col {
    NSMutableArray *colArray = gTabCols[tab][col];
    CGFloat colW = gMenuWidth / 3.0f;
    CGFloat rowY = 16.0f + (colArray.count * FL_ROW_H); // Padding Top 16

    UIView *row = (UIView *)switchView;
    row.frame = CGRectMake(col * colW, rowY, colW, FL_ROW_H);
    [colArray addObject:switchView];

    UIScrollView *sv = gTabSV[tab];
    [sv addSubview:row];
    sv.contentSize = CGSizeMake(gMenuWidth, rowY + FL_ROW_H + 20);

    // Restore saved toggles
    if ([switchView respondsToSelector:@selector(getPreferencesKey)]) {
        NSString *key = [switchView performSelector:@selector(getPreferencesKey)];
        BOOL saved = [defaults boolForKey:key];
        if ([switchView isKindOfClass:[OffsetSwitch class]]) {
            [(OffsetSwitch *)switchView restoreState:saved];
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        _dragStart = [gr locationInView:self];
        _containerStart = _containerView.center;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint now = [gr locationInView:self];
        _containerView.center = CGPointMake(_containerStart.x + now.x - _dragStart.x, _containerStart.y + now.y - _dragStart.y);
    }
}

- (void)showMenuButton {
    gMenuButton = [[UIButton alloc] initWithFrame:CGRectMake(20, gMainWindow.bounds.size.height/2 - 25, 50, 50)];
    gMenuButton.backgroundColor = FL_TAB_ACTIVE;
    gMenuButton.layer.cornerRadius = 25.0f;
    [gMenuButton setTitle:@"🪷" forState:UIControlStateNormal];
    [gMenuButton addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragButton:)];
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
    [UIView animateWithDuration:0.25 animations:^{ self.layer.opacity = 1.0f; }];
}
- (void)closeMenu {
    [UIView animateWithDuration:0.2 animations:^{ self.layer.opacity = 0.0f; }];
}
- (void)showPopup:(NSString *)t description:(NSString *)d {
    // Requires SCLAlertView integration
}
@end

// ═══════════════════════════════════════════════════════════════
// Offset Switch (Custom Toggle Style)
// ═══════════════════════════════════════════════════════════════
@implementation OffsetSwitch {
    UISwitch *toggleSwitch;
    UILabel *switchLabel;
    NSString *preferencesKey;
    std::vector<MemoryPatch> memoryPatches;
}

- (id)initHackNamed:(NSString *)hackName_ description:(NSString *)description_ offsets:(std::vector<uint64_t>)offsets_ bytes:(std::vector<std::string>)bytes_ colWidth:(CGFloat)colWidth {
    
    preferencesKey = hackName_;
    self = [super initWithFrame:CGRectMake(0, 0, colWidth, FL_ROW_H)];
    
    // Custom Label Checkbox-style vibe
    switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, colWidth - 80, FL_ROW_H)];
    switchLabel.text = hackName_;
    switchLabel.textColor = FL_TEXT_SEC;
    switchLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    [self addSubview:switchLabel];

    toggleSwitch = [[UISwitch alloc] init];
    toggleSwitch.onTintColor = FL_TAB_ACTIVE;
    toggleSwitch.transform = CGAffineTransformMakeScale(0.75, 0.75); // ทำให้สวิตช์เล็กลงเหมือนในรูป
    toggleSwitch.frame = CGRectMake(colWidth - 60, (FL_ROW_H - 31)/2, 51, 31);
    [toggleSwitch addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:toggleSwitch];

    return self;
}

- (void)restoreState:(BOOL)on {
    toggleSwitch.on = on;
    switchLabel.textColor = on ? [UIColor whiteColor] : FL_TEXT_SEC;
}

- (void)toggleChanged:(UISwitch *)sender {
    BOOL on = sender.isOn;
    [defaults setBool:on forKey:preferencesKey];
    [UIView animateWithDuration:0.2 animations:^{
        self->switchLabel.textColor = on ? [UIColor whiteColor] : FL_TEXT_SEC;
    }];
}

- (NSString *)getPreferencesKey { return preferencesKey; }
@end


// ═══════════════════════════════════════════════════════════════
// Button Action Switch
// ═══════════════════════════════════════════════════════════════
@implementation ActionButton {
    void(^_actionBlock)(void);
}
- (id)initButtonNamed:(NSString *)btnName_ colWidth:(CGFloat)colWidth action:(void(^)(void))actionBlock {
    self = [super initWithFrame:CGRectMake(0, 0, colWidth, FL_ROW_H)];
    _actionBlock = actionBlock;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(24, 4, colWidth - 48, FL_ROW_H - 8);
    btn.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.05f];
    btn.layer.cornerRadius = 8.0f;
    [btn setTitle:btnName_ forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [btn addTarget:self action:@selector(pressed) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
    return self;
}
- (void)pressed { if(_actionBlock) _actionBlock(); }
@end

// ═══════════════════════════════════════════════════════════════
// Switches setup populated like FLUORITE
// ═══════════════════════════════════════════════════════════════
@implementation Switches

- (void)addSwitch:(NSString *)name description:(NSString *)desc tab:(FLTab)tab column:(int)col {
    OffsetSwitch *s = [[OffsetSwitch alloc] initHackNamed:name description:desc offsets:{} bytes:{} colWidth:(gMenuWidth/3.0f)];
    [menu addSwitchToMenu:s tab:tab column:col];
}
- (void)addTextfieldSwitch:(NSString *)name description:(NSString *)desc tab:(FLTab)tab column:(int)col {
    // ปรับใช้ได้ตามต้องการ
}
- (void)addButton:(NSString *)btnName tab:(FLTab)tab column:(int)col action:(void(^)(void))actionBlock {
    ActionButton *btn = [[ActionButton alloc] initButtonNamed:btnName colWidth:(gMenuWidth/3.0f) action:actionBlock];
    [menu addSwitchToMenu:btn tab:tab column:col];
}

// โหลดทุกเมนูใส่เลย์เอาท์ 3 คอลัมน์
- (void)setupFluoriteLayout {
    // ━━━━━ TAB 0: Visualization ━━━━━
    // Col 0: Prediction
    [self addSwitch:@"Prediction" description:@"" tab:FLTabVisualization column:0];
    [self addSwitch:@"Projected Balls" description:@"" tab:FLTabVisualization column:0];
    [self addSwitch:@"Projection Lines" description:@"" tab:FLTabVisualization column:0];
    [self addSwitch:@"Pocket Markers" description:@"" tab:FLTabVisualization column:0];
    [self addSwitch:@"Keep Preview" description:@"" tab:FLTabVisualization column:0];
    [self addSwitch:@"Opponent Preview" description:@"" tab:FLTabVisualization column:0];

    // Col 1: Alerts
    [self addSwitch:@"Alerts" description:@"" tab:FLTabVisualization column:1];
    [self addSwitch:@"Pot Alert" description:@"" tab:FLTabVisualization column:1];
    [self addSwitch:@"Scratch Alert" description:@"" tab:FLTabVisualization column:1];

    // Col 2: Styling
    [self addButton:@"Balls Style (Classic)" tab:FLTabVisualization column:2 action:^{}];
    [self addButton:@"Lines Style (Neon)" tab:FLTabVisualization column:2 action:^{}];
    [self addButton:@"Pocket Style (Arrow)" tab:FLTabVisualization column:2 action:^{}];
    [self addButton:@"Pocket Anim (Burst)" tab:FLTabVisualization column:2 action:^{}];

    // ━━━━━ TAB 1: Automation ━━━━━
    // Col 0
    [self addSwitch:@"Auto Aim" description:@"" tab:FLTabAutomation column:0];
    [self addSwitch:@"Aim Guide" description:@"" tab:FLTabAutomation column:0];
    [self addButton:@"Play Style: Aggressive" tab:FLTabAutomation column:0 action:^{}];
    [self addButton:@"Aiming Method: Touches" tab:FLTabAutomation column:0 action:^{}];
    [self addSwitch:@"Solver Status" description:@"" tab:FLTabAutomation column:0];

    // Col 1
    [self addSwitch:@"Lucky Shot" description:@"" tab:FLTabAutomation column:1];
    [self addButton:@"Play Lucky Shot" tab:FLTabAutomation column:1 action:^{}];

    // Col 2
    [self addButton:@"Tier Selection: Max" tab:FLTabAutomation column:2 action:^{}];
    [self addButton:@" Play Queue" tab:FLTabAutomation column:2 action:^{}];
    [self addButton:@" Stop Queue" tab:FLTabAutomation column:2 action:^{}];

    // ━━━━━ TAB 2: Settings ━━━━━
    // Col 0
    [self addSwitch:@"Adblock" description:@"" tab:FLTabSettings column:0];
    [self addButton:@"Unlock Achievements" tab:FLTabSettings column:0 action:^{}];
    [self addButton:@"Reset Guest" tab:FLTabSettings column:0 action:^{}];

    // Col 1
    [self addSwitch:@"Streamproof" description:@"" tab:FLTabSettings column:1];
    [self addSwitch:@"Liquid Glass" description:@"" tab:FLTabSettings column:1];
    [self addButton:@"Watermark Position" tab:FLTabSettings column:1 action:^{}];

    // Col 2
    [self addButton:@"Save Config" tab:FLTabSettings column:2 action:^{}];
    [self addButton:@"Load Config" tab:FLTabSettings column:2 action:^{}];
    [self addButton:@"Reset Settings" tab:FLTabSettings column:2 action:^{}];
}

@end
