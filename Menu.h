//
//  Menu.h  — FLUORITE-style UI
//

#import "UIKit/UIKit.h"
#import "KittyMemory/MemoryPatch.hpp"
#import "SCLAlertView/SCLAlertView.h"

#import <vector>
#import <initializer_list>

@class OffsetSwitch;
@class TextFieldSwitch;
@class SliderSwitch;
@class Switches;

// ── Tab identifiers ──────────────────────────────────────────
typedef NS_ENUM(NSInteger, FLTab) {
    FLTabVisualization = 0,
    FLTabAutomation    = 1,
    FLTabSettings      = 2,
};

// ── Main menu window ─────────────────────────────────────────
@interface Menu : UIView

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
         menuButton:(NSString *)menuButtonBase64_;

- (void)showMenuButton;
- (void)addSwitchToMenu:(id)switch_ tab:(FLTab)tab;
- (void)addSwitchToMenu:(id)switch_;          // default → Visualization tab
- (void)showPopup:(NSString *)title_ description:(NSString *)description_;

@end

// ── Toggle row (base class) ───────────────────────────────────
@interface OffsetSwitch : UIView {
    NSString *preferencesKey;
    NSString *switchDescription;
    UILabel  *switchLabel;
    UISwitch *toggleSwitch;
}

- (id)initHackNamed:(NSString *)hackName_
        description:(NSString *)description_
            offsets:(std::vector<uint64_t>)offsets_
              bytes:(std::vector<std::string>)bytes_;

- (void)showInfo;
- (NSString *)getPreferencesKey;
- (NSString *)getDescription;
- (std::vector<MemoryPatch>)getMemoryPatches;

@end

// ── Text-field row ────────────────────────────────────────────
@interface TextFieldSwitch : OffsetSwitch <UITextFieldDelegate> {
    NSString *switchValueKey;
}

- (id)initTextfieldNamed:(NSString *)hackName_
             description:(NSString *)description_
       inputBorderColor:(UIColor *)inputBorderColor_;

- (NSString *)getSwitchValueKey;

@end

// ── Slider row ────────────────────────────────────────────────
@interface SliderSwitch : TextFieldSwitch

- (id)initSliderNamed:(NSString *)hackName_
          description:(NSString *)description_
         minimumValue:(float)minimumValue_
         maximumValue:(float)maximumValue_
          sliderColor:(UIColor *)sliderColor_;

@end

// ── Public switch-builder ─────────────────────────────────────
@interface Switches : NSObject

- (void)addSwitch:(NSString *)hackName_
      description:(NSString *)description_;

- (void)addSwitch:(NSString *)hackName_
      description:(NSString *)description_
              tab:(FLTab)tab;

- (void)addOffsetSwitch:(NSString *)hackName_
            description:(NSString *)description_
                offsets:(std::initializer_list<uint64_t>)offsets_
                  bytes:(std::initializer_list<std::string>)bytes_;

- (void)addOffsetSwitch:(NSString *)hackName_
            description:(NSString *)description_
                offsets:(std::initializer_list<uint64_t>)offsets_
                  bytes:(std::initializer_list<std::string>)bytes_
                    tab:(FLTab)tab;

- (void)addTextfieldSwitch:(NSString *)hackName_
               description:(NSString *)description_
         inputBorderColor:(UIColor *)inputBorderColor_;

- (void)addSliderSwitch:(NSString *)hackName_
            description:(NSString *)description_
           minimumValue:(float)minimumValue_
           maximumValue:(float)maximumValue_
            sliderColor:(UIColor *)sliderColor_;

- (NSString *)getValueFromSwitch:(NSString *)name;
- (bool)isSwitchOn:(NSString *)switchName;

@end

// ── Globals (defined in Menu.mm) ──────────────────────────────
extern Menu    *menu;
extern Switches *switches;
