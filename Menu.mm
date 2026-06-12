#import <Foundation/Foundation.h>
#import "Menu.h"

// ── COLOURS (Fluorite Theme) ─────────────────────────────────
#define FL_BG           [UIColor colorWithRed:0.04f green:0.04f blue:0.06f alpha:0.99f]
#define FL_PANEL        [UIColor colorWithRed:0.08f green:0.08f blue:0.11f alpha:1.0f]
#define FL_PANEL2       [UIColor colorWithRed:0.10f green:0.10f blue:0.14f alpha:1.0f]
#define FL_TAB_ACTIVE   [UIColor colorWithRed:0.60f green:0.33f blue:0.90f alpha:1.0f]
#define FL_TEXT_PRIMARY [UIColor whiteColor]
#define FL_TEXT_SEC     [UIColor colorWithWhite:0.55f alpha:1.0f]
#define FL_DIVIDER      [UIColor colorWithWhite:1.0f alpha:0.05f]
#define FL_CORNER       22.0f
#define FL_ROW_H        52.0f
#define FL_COL_W        (gMenuWidth / 3.0f)

// ── GLOBALS ───────────────────────────────────────────────────
static NSUserDefaults *defaults;
static CGFloat         gMenuWidth  = 760.0f;
static NSString       *gSwitchFont;
static UIColor        *gSwitchColor;
static UIButton       *gMenuButton;
static UIWindow       *gMainWindow;

static NSMutableArray *gTabRows[3];
static UIScrollView   *gTabSV[3];

// Per-tab column scroll views (3 columns per tab)
static UIScrollView   *gColSV[3][3];
static NSMutableArray *gColRows[3][3];
static CGFloat         gColWidths[3];

Menu     *menu     = [[Menu alloc] init];
Switches *switches = [[Switches alloc] init];

// ═══════════════════════════════════════════════════════════════
//  MENU IMPLEMENTATION  (3-column layout per tab)
// ═══════════════════════════════════════════════════════════════
@interface Menu ()
@property (strong, nonatomic) UIView   *containerView;
@property (strong, nonatomic) UILabel  *titleLabel;
@property (strong, nonatomic) NSArray  *tabButtons;
@property (assign, nonatomic) FLTab     activeTab;
@property (assign, nonatomic) CGPoint   dragStart;
@property (assign, nonatomic) CGPoint   containerStart;
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
  
  gMainWindow = [UIApplication sharedApplication].keyWindow;
  defaults    = [NSUserDefaults standardUserDefaults];
  gMenuWidth  = menuWidth_;
  gSwitchFont = switchTitleFont_;
  gSwitchColor = switchTitleColor_;
  
  for (int t = 0; t < 3; t++) {
  gTabRows[t] = [NSMutableArray new];
  for (int c = 0; c < 3; c++)
  gColRows[t][c] = [NSMutableArray new];
  }
  
  // Column widths — equal thirds with 1px dividers
  CGFloat divW = 1.0f;
  CGFloat colW = (gMenuWidth - divW * 2) / 3.0f;
  gColWidths[0] = colW;
  gColWidths[1] = colW;
  gColWidths[2] = colW;
  
  self = [super initWithFrame:gMainWindow.bounds];
  self.backgroundColor = [UIColor clearColor];
  self.layer.opacity   = 0.0f;
  [gMainWindow addSubview:self];
  
  // Dim overlay
  UIView *dim = [[UIView alloc] initWithFrame:self.bounds];
  dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55f];
  [self addSubview:dim];
  
  // Card
  CGFloat cw = gMenuWidth, ch = 420.0f;
  _containerView = [[UIView alloc] initWithFrame:CGRectMake(
  (self.bounds.size.width - cw)/2,
  (self.bounds.size.height - ch)/2,
  cw, ch)];
  _containerView.backgroundColor     = FL_BG;
  _containerView.layer.cornerRadius  = FL_CORNER;
  _containerView.layer.masksToBounds = YES;
  _containerView.layer.borderWidth   = 1.0f;
  _containerView.layer.borderColor   = FL_DIVIDER.CGColor;
  [self addSubview:_containerView];
  
  UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
  initWithTarget:self action:@selector(handlePan:)];
  [_containerView addGestureRecognizer:pan];
  
  // ── Header ──────────────────────────────────────────────
  CGFloat hh = 62.0f;
  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cw, hh)];
  header.backgroundColor = [UIColor clearColor];
  [_containerView addSubview:header];
  
  // Gem + Title
  UILabel *gem = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 28, hh)];
  gem.text      = @“❖”;
  gem.textColor = FL_TAB_ACTIVE;
  gem.font      = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
  [header addSubview:gem];
  
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, 130, hh)];
  _titleLabel.text      = @“FLUORITE”;
  _titleLabel.textColor = FL_TEXT_PRIMARY;
  _titleLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
  NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:@“FLUORITE”];
  [attr addAttribute:NSKernAttributeName value:@(2.5f) range:NSMakeRange(0, attr.length)];
  _titleLabel.attributedText = attr;
  [header addSubview:_titleLabel];
  
  // Tab bar — centered
  CGFloat tabW = 340.0f, tabH = 40.0f;
  UIView *tabContainer = [[UIView alloc] initWithFrame:
  CGRectMake((cw-tabW)/2, (hh-tabH)/2, tabW, tabH)];
  tabContainer.backgroundColor    = FL_PANEL;
  tabContainer.layer.cornerRadius = 20.0f;
  [header addSubview:tabContainer];
  
  NSArray *tabNames = @[@“Visualization”, @“Automation”, @“Settings”];
  NSMutableArray *tabBtns = [NSMutableArray new];
  CGFloat tw = tabW / 3.0f;
  for (int i = 0; i < 3; i++) {
  UIButton *tb = [UIButton buttonWithType:UIButtonTypeSystem];
  tb.frame = CGRectMake(i*tw, 0, tw, tabH);
  tb.tag   = i;
  [tb setTitle:tabNames[i] forState:UIControlStateNormal];
  tb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  [tb addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
  [tabContainer addSubview:tb];
  [tabBtns addObject:tb];
  }
  _tabButtons = [tabBtns copy];
  
  // Close button
  UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
  close.frame = CGRectMake(cw-52, 0, 52, hh);
  [close setTitle:@“X” forState:UIControlStateNormal];
  close.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
  [close setTitleColor:FL_TEXT_SEC forState:UIControlStateNormal];
  [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
  [header addSubview:close];
  
  // ── Content area: 3 columns per tab ─────────────────────
  CGFloat svY = hh + 1, svH = ch - svY;
  
  for (int t = 0; t < 3; t++) {
  UIView *tabView = [[UIView alloc] initWithFrame:CGRectMake(0, svY, cw, svH)];
  tabView.tag     = 100 + t;
  tabView.hidden  = (t != 0);
  [_containerView addSubview:tabView];
  
  ```
    CGFloat xOff = 0;
    for (int c = 0; c < 3; c++) {
        // Vertical divider (except before col 0)
        if (c > 0) {
            UIView *div = [[UIView alloc] initWithFrame:CGRectMake(xOff, 0, 1, svH)];
            div.backgroundColor = FL_DIVIDER;
            [tabView addSubview:div];
            xOff += 1;
        }
  
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:
            CGRectMake(xOff, 0, gColWidths[c], svH)];
        sv.backgroundColor            = [UIColor clearColor];
        sv.showsVerticalScrollIndicator = NO;
        sv.contentInset = UIEdgeInsetsMake(16, 0, 16, 0);
        gColSV[t][c] = sv;
        [tabView addSubview:sv];
        xOff += gColWidths[c];
    }
  ```
  
  }
  
  _activeTab = FLTabVisualization;
  [self refreshTabAppearance];
  return self;
  }
- (void)tabTapped:(UIButton *)sender {
  _activeTab = (FLTab)sender.tag;
  for (int t = 0; t < 3; t++) {
  UIView *v = [_containerView viewWithTag:100 + t];
  v.hidden = (t != _activeTab);
  }
  [self refreshTabAppearance];
  }
- (void)refreshTabAppearance {
  for (int i = 0; i < 3; i++) {
  UIButton *tb = _tabButtons[i];
  BOOL active  = (i == _activeTab);
  [tb setTitleColor:active ? FL_TEXT_PRIMARY : FL_TEXT_SEC forState:UIControlStateNormal];
  tb.backgroundColor    = active ? FL_TAB_ACTIVE : [UIColor clearColor];
  tb.layer.cornerRadius = 20.0f;
  }
  }

// addSwitchToMenu — routes to col 0 of current tab

- (void)addSwitchToMenu:(id)switch_ {
  [self addSwitchToMenu:switch_ tab:FLTabVisualization col:0];
  }
- (void)addSwitchToMenu:(id)switch_ tab:(FLTab)tab {
  [self addSwitchToMenu:switch_ tab:tab col:0];
  }
- (void)addSwitchToMenu:(id)switch_ tab:(FLTab)tab col:(int)col {
  if (col < 0 || col > 2) col = 0;
  NSMutableArray *rows = gColRows[tab][col];
  CGFloat rowY = 0;
  for (id r in rows) rowY += [(UIView*)r frame].size.height;
  
  UIView *row = (UIView *)switch_;
  row.frame = CGRectMake(0, rowY, gColWidths[col], row.frame.size.height ?: FL_ROW_H);
  [rows addObject:switch_];
  
  UIScrollView *sv = gColSV[tab][col];
  [sv addSubview:row];
  sv.contentSize = CGSizeMake(gColWidths[col], rowY + row.frame.size.height + 8);
  
  if ([switch_ respondsToSelector:@selector(getPreferencesKey)]) {
  NSString *key = [switch_ performSelector:@selector(getPreferencesKey)];
  BOOL saved    = [defaults boolForKey:key];
  if ([switch_ isKindOfClass:[OffsetSwitch class]])
  [(OffsetSwitch *)switch_ restoreState:saved];
  }
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
  gMenuButton = [[UIButton alloc] initWithFrame:
  CGRectMake(20, gMainWindow.bounds.size.height/2 - s/2, s, s)];
  gMenuButton.backgroundColor     = FL_TAB_ACTIVE;
  gMenuButton.layer.cornerRadius  = s/2;
  gMenuButton.layer.shadowColor   = FL_TAB_ACTIVE.CGColor;
  gMenuButton.layer.shadowOpacity = 0.6f;
  gMenuButton.layer.shadowRadius  = 14.0f;
  gMenuButton.layer.shadowOffset  = CGSizeMake(0, 4);
  
  UILabel *lbl = [[UILabel alloc] initWithFrame:gMenuButton.bounds];
  lbl.text          = @“❖”;
  lbl.textColor     = [UIColor whiteColor];
  lbl.font          = [UIFont systemFontOfSize:24];
  lbl.textAlignment = NSTextAlignmentCenter;
  [gMenuButton addSubview:lbl];
  
  [gMenuButton addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchUpInside];
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
  subTitle:[NSString stringWithFormat:@”%@\n\n%@”, title_, description_]
  closeButtonTitle:@“OK” duration:0];
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
  
  preferencesKey    = hackName_;
  switchDescription = description_;
  
  if (offsets_.size() != bytes_.size()) {
  [menu showPopup:@“Invalid input count” description:@“Offsets ≠ bytes”];
  } else {
  for (size_t i = 0; i < offsets_.size(); i++) {
  MemoryPatch p = MemoryPatch::createWithHex(NULL, offsets_[i], bytes_[i]);
  if (p.isValid()) memoryPatches.push_back(p);
  }
  }
  
  CGFloat colW = gColWidths[0];
  self = [super initWithFrame:CGRectMake(0, 0, colW, FL_ROW_H)];
  self.backgroundColor = [UIColor clearColor];
  
  toggleSwitch = [[UISwitch alloc] init];
  toggleSwitch.onTintColor = FL_TAB_ACTIVE;
  toggleSwitch.frame = CGRectMake(
  colW - toggleSwitch.frame.size.width - 16,
  (FL_ROW_H - toggleSwitch.frame.size.height)/2,
  toggleSwitch.frame.size.width,
  toggleSwitch.frame.size.height);
  [toggleSwitch addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
  [self addSubview:toggleSwitch];
  
  switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, colW - 80, FL_ROW_H)];
  switchLabel.text      = hackName_;
  switchLabel.textColor = FL_TEXT_PRIMARY;
  switchLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  [self addSubview:switchLabel];
  
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
  initWithTarget:self action:@selector(showInfo)];
  tap.numberOfTapsRequired = 2;
  [self addGestureRecognizer:tap];
  
  return self;
  }
- (void)restoreState:(BOOL)on { toggleSwitch.on = on; }
- (void)showInfo {
  [menu showPopup:preferencesKey description:switchDescription];
  }
- (void)toggleChanged:(UISwitch *)sender {
  BOOL on = sender.isOn;
  [defaults setBool:on forKey:preferencesKey];
  for (auto &p : memoryPatches)
  on ? p.Modify() : p.Restore();
  }
- (NSString *)getPreferencesKey { return preferencesKey; }
- (NSString *)getDescription    { return switchDescription; }
- (std::vector<MemoryPatch>)getMemoryPatches { return memoryPatches; }

@end

// ═══════════════════════════════════════════════════════════════
//  TEXT-FIELD SWITCH
// ═══════════════════════════════════════════════════════════════
@implementation TextFieldSwitch {
UITextField *textfieldValue;
}

- (id)initTextfieldNamed:(NSString *)hackName_
  description:(NSString *)description_
  inputBorderColor:(UIColor *)inputBorderColor_ {
  
  preferencesKey    = hackName_;
  switchValueKey    = [hackName_ stringByAppendingString:@”*val”];
  switchDescription = description*;
  
  CGFloat colW = gColWidths[0];
  self = [super initWithFrame:CGRectMake(0, 0, colW, FL_ROW_H)];
  self.backgroundColor = [UIColor clearColor];
  
  switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, colW*0.5f, FL_ROW_H)];
  switchLabel.text      = hackName_;
  switchLabel.textColor = FL_TEXT_PRIMARY;
  switchLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  [self addSubview:switchLabel];
  
  textfieldValue = [[UITextField alloc] initWithFrame:
  CGRectMake(colW - 130 - 16, (FL_ROW_H-34)/2, 130, 34)];
  textfieldValue.layer.borderColor  = inputBorderColor_.CGColor;
  textfieldValue.layer.borderWidth  = 1.5f;
  textfieldValue.layer.cornerRadius = 10.0f;
  textfieldValue.textColor          = FL_TEXT_PRIMARY;
  textfieldValue.textAlignment      = NSTextAlignmentCenter;
  textfieldValue.font               = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
  textfieldValue.backgroundColor    = FL_PANEL2;
  textfieldValue.delegate           = self;
  
  NSString *saved = [defaults objectForKey:switchValueKey];
  if (saved) textfieldValue.text = saved;
  [self addSubview:textfieldValue];
  return self;
  }
- (BOOL)textFieldShouldReturn:(UITextField *)tf {
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
  
  preferencesKey    = hackName_;
  switchValueKey    = [hackName_ stringByAppendingString:@”*sliderval”];
  switchDescription = description*;
  
  CGFloat colW = gColWidths[0];
  self = [super initWithFrame:CGRectMake(0, 0, colW, FL_ROW_H + 20)];
  self.backgroundColor = [UIColor clearColor];
  
  switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, colW*0.6f, 20)];
  switchLabel.text      = hackName_;
  switchLabel.textColor = FL_TEXT_PRIMARY;
  switchLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
  [self addSubview:switchLabel];
  
  sliderValue = [[UISlider alloc] initWithFrame:CGRectMake(16, 34, colW-90, 20)];
  sliderValue.minimumValue          = minimumValue_;
  sliderValue.maximumValue          = maximumValue_;
  sliderValue.thumbTintColor        = sliderColor_;
  sliderValue.minimumTrackTintColor = FL_TAB_ACTIVE;
  sliderValue.maximumTrackTintColor = FL_PANEL2;
  sliderValue.continuous            = YES;
  [sliderValue addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
  
  float saved = [defaults floatForKey:switchValueKey];
  if (saved != 0) sliderValue.value = saved;
  
  UILabel *valLbl = [[UILabel alloc] initWithFrame:CGRectMake(colW-68, 34, 50, 20)];
  valLbl.tag       = 77;
  valLbl.textColor = FL_TEXT_SEC;
  valLbl.font      = [UIFont monospacedDigitSystemFontOfSize:11 weight:UIFontWeightMedium];
  valLbl.text      = [NSString stringWithFormat:@”%.2f”, sliderValue.value];
  [self addSubview:valLbl];
  [self addSubview:sliderValue];
  return self;
  }
- (void)sliderChanged:(UISlider *)s {
  [defaults setFloat:s.value forKey:switchValueKey];
  UILabel *lbl = (UILabel *)[self viewWithTag:77];
  lbl.text = [NSString stringWithFormat:@”%.2f”, s.value];
  }

@end

// ═══════════════════════════════════════════════════════════════
//  ACTION BUTTON
// ═══════════════════════════════════════════════════════════════
@implementation ActionButton {
void (^action)(void);
}

- (id)initButtonNamed:(NSString *)btnName
  colWidth:(CGFloat)colWidth
  actionBlock:(void (^)(void))actionBlock {
  self = [super initWithFrame:CGRectMake(0, 0, colWidth, FL_ROW_H)];
  if (self) {
  self.backgroundColor = [UIColor clearColor];
  action = actionBlock;
  
  ```
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(16, 10, colWidth - 32, FL_ROW_H - 20);
    btn.backgroundColor    = FL_PANEL2;
    btn.layer.cornerRadius = 10.0f;
    [btn setTitle:btnName forState:UIControlStateNormal];
    [btn setTitleColor:FL_TEXT_PRIMARY forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [btn addTarget:self action:@selector(btnTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
  ```
  
  }
  return self;
  }
- (void)btnTapped { if (action) action(); }

@end

// ═══════════════════════════════════════════════════════════════
//  SWITCHES BUILDER
// ═══════════════════════════════════════════════════════════════
@implementation Switches

- (void)setupFluoriteLayout {}
- (void)addSwitch:(NSString *)hackName_ description:(NSString *)description_ {
  [self addSwitch:hackName_ description:description_ tab:FLTabVisualization];
  }
- (void)addSwitch:(NSString *)hackName_ description:(NSString *)description_ tab:(FLTab)tab {
  [self addSwitch:hackName_ description:description_ tab:tab col:0];
  }
- (void)addSwitch:(NSString *)hackName_ description:(NSString *)description_ tab:(FLTab)tab col:(int)col {
  OffsetSwitch *s = [[OffsetSwitch alloc]
  initHackNamed:hackName_ description:description_
  offsets:std::vector<uint64_t>{}
  bytes:std::vector<std::string>{}];
  [menu addSwitchToMenu:s tab:tab col:col];
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
  ActionButton *btn = [[ActionButton alloc]
  initButtonNamed:btnName colWidth:gColWidths[0] actionBlock:actionBlock];
  [menu addSwitchToMenu:btn tab:tab];
  }
- (NSString *)getValueFromSwitch:(NSString *)name {
  NSString *key = [name stringByAppendingString:@”_val”];
  NSString *str = [defaults objectForKey:key];
  if (str) return str;
  float fv = [defaults floatForKey:key];
  if (fv != 0) return [NSString stringWithFormat:@”%f”, fv];
  return nil;
  }
- (bool)isSwitchOn:(NSString *)switchName {
  return [defaults boolForKey:switchName];
  }

@end
