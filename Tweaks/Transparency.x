#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================================
// Transparency.x — AIOTweaks
// 1. Transparent Dock background (SBDockView, SBFloatingDockPlatterView)
// 2. Transparent Home Bar (Home Grabber) globally across SpringBoard & all Apps
//    while keeping swipe gestures active
// ============================================================================

// Safe ivar lookup: checks class_getInstanceVariable first so it NEVER throws NSUndefinedKeyException
static inline UIView *safeGetViewIvarTR(id obj, const char *ivarName) {
    if (!obj || !ivarName) return nil;
    Ivar ivar = class_getInstanceVariable([obj class], ivarName);
    if (!ivar) return nil;
    id val = object_getIvar(obj, ivar);
    return [val isKindOfClass:[UIView class]] ? (UIView *)val : nil;
}

@interface SBDockView : UIView
- (void)setBackgroundAlpha:(double)alpha;
@end

@interface SBFloatingDockPlatterView : UIView
@end

@interface MTLumaDodgePillView : UIView
@end

@interface SBFHomeGrabberView : UIView
@end

@interface SBHomeGrabberView : UIView
@end

// ============================================================================
// GROUP 1: SpringBoard-Only Hooks (Dock & SB Home Grabber)
// ============================================================================
%group SpringBoardTransparency

// ----------------------------------------------------------------------------
// 1. Transparent Dock
// ----------------------------------------------------------------------------
%hook SBDockView

- (void)layoutSubviews {
    %orig;
    UIView *bgView = safeGetViewIvarTR(self, "_backgroundView");
    if (bgView) {
        bgView.hidden = YES;
        bgView.alpha = 0.0;
    }
    UIView *highlightView = safeGetViewIvarTR(self, "_highlightView");
    if (highlightView) {
        highlightView.hidden = YES;
        highlightView.alpha = 0.0;
    }
}

- (void)setBackgroundAlpha:(double)alpha {
    %orig(0.0);
}

- (double)backgroundAlpha {
    return 0.0;
}

%end

%hook SBFloatingDockPlatterView

- (void)layoutSubviews {
    %orig;
    UIView *bgView = safeGetViewIvarTR(self, "_backgroundView");
    if (bgView) {
        bgView.hidden = YES;
        bgView.alpha = 0.0;
    }
}

%end

%end // group SpringBoardTransparency

// ============================================================================
// GROUP 2: Global Hooks (SpringBoard + All Apps via com.apple.UIKit)
// Hides the Home Bar visual pill (MTLumaDodgePillView) in every app and
// SpringBoard while keeping all swipe-up / app-switching gestures intact.
// ============================================================================
%group GlobalHomeBarTransparency

%hook MTLumaDodgePillView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.hidden = YES;
}

- (void)didMoveToWindow {
    %orig;
    self.alpha = 0.0;
    self.hidden = YES;
}

- (CGFloat)alpha {
    return 0.0;
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

%end

%end // group GlobalHomeBarTransparency

%ctor {
    @autoreleasepool {
        // Only initialize inside SpringBoard or standard user/system applications (skip background daemons)
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *bundleID = [mainBundle bundleIdentifier];
        if (!bundleID) return;

        BOOL isSpringBoard = [bundleID isEqualToString:@"com.apple.springboard"];
        if (isSpringBoard) {
            %init(SpringBoardTransparency);
        }
        if (isSpringBoard || [[mainBundle executablePath] containsString:@".app/"]) {
            %init(GlobalHomeBarTransparency);
        }
    }
}
