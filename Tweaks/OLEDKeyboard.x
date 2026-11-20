#import <UIKit/UIKit.h>
#import "iiKitPrefs.h"

// ============================================================================
// OLEDKeyboard.x — iiKit
// OLED Black Mode for the iOS System Keyboard (based on Easy-Z/BARK)
// ============================================================================

@interface UIKeyboard : UIView
@end

@interface UIKeyboardDockView : UIView
@end

@interface UIKBRenderConfig : NSObject
- (void)setLightKeyboard:(BOOL)arg1;
@end

%group GlobalOLEDKeyboard

%hook UIKeyboard

- (void)layoutSubviews {
    %orig;
    self.backgroundColor = [UIColor blackColor];
}

%end

%hook UIKBRenderConfig

- (void)setLightKeyboard:(BOOL)arg1 {
    %orig(NO);
}

- (BOOL)lightKeyboard {
    return NO;
}

%end

%hook UIKeyboardDockView

- (void)layoutSubviews {
    %orig;
    self.backgroundColor = [UIColor blackColor];
}

%end

%end // group GlobalOLEDKeyboard

%ctor {
    @autoreleasepool {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *bundleID = [mainBundle bundleIdentifier];
        if (!bundleID) return;

        // Initialize in SpringBoard, all .app bundles, and keyboard/app extensions (.appex)
        NSString *execPath = [mainBundle executablePath];
        if (([bundleID isEqualToString:@"com.apple.springboard"] ||
             [execPath containsString:@".app/"] ||
             [execPath containsString:@".appex/"]) &&
            iiKitPrefEnabled(iiKitPrefOLEDKeyboard)) {
            %init(GlobalOLEDKeyboard);
        }
    }
}
