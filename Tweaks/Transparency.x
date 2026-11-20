#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "iiKitPrefs.h"

// ============================================================================
// Transparency.x — iiKit
// 1. Transparent Dock background (SBDockView, SBFloatingDockPlatterView)
// 2. Transparent Home Bar (Home Grabber / Home Affordance) across SpringBoard,
//    Lock Screen (CoverSheet), and all Apps while keeping swipe gestures active
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

@interface CSHomeAffordanceView : UIView
@end

@interface CSHomeAffordanceViewController : UIViewController
@end

@interface CSTeachableMomentsContainerView : UIView
@property (nonatomic, retain) UIView *homeAffordanceContainerView;
@end

@interface SBDashBoardTeachableMomentsContainerView : UIView
@property (nonatomic, retain) UIView *homeAffordanceContainerView;
@end

// ============================================================================
// GROUP 1: SpringBoard-Only Hooks (Transparent Dock)
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
// GROUP 2: SpringBoard & Lock Screen (CoverSheet) Home Bar Transparency
// Hides the Lock Screen home indicator (CSHomeAffordanceView /
// CSTeachableMomentsContainerView) and SpringBoard home grabber views
// safely without calling -[SBHomeGrabberView setHidden:], which throws an
// NSInternalInconsistencyException in SpringBoard on iOS 16+.
// ============================================================================
%group SpringBoardHomeBarTransparency

// ----------------------------------------------------------------------------
// 2A. Lock Screen CoverSheet Home Affordance View
// ----------------------------------------------------------------------------
%hook CSHomeAffordanceView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.layer.opacity = 0.0;
    self.layer.hidden = YES;
    for (UIView *subview in self.subviews) {
        subview.alpha = 0.0;
        subview.layer.opacity = 0.0;
        subview.layer.hidden = YES;
    }
}

- (void)didMoveToWindow {
    %orig;
    self.alpha = 0.0;
    self.layer.opacity = 0.0;
    self.layer.hidden = YES;
}

- (CGFloat)alpha {
    return 0.0;
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

%end

// ----------------------------------------------------------------------------
// 2B. Lock Screen CoverSheet Home Affordance View Controller
// ----------------------------------------------------------------------------
%hook CSHomeAffordanceViewController

- (void)viewDidLoad {
    %orig;
    if ([self isViewLoaded]) {
        self.view.alpha = 0.0;
        self.view.layer.opacity = 0.0;
        self.view.layer.hidden = YES;
    }
}

- (void)viewWillLayoutSubviews {
    %orig;
    if ([self isViewLoaded]) {
        self.view.alpha = 0.0;
        self.view.layer.opacity = 0.0;
        self.view.layer.hidden = YES;
    }
}

%end

// ----------------------------------------------------------------------------
// 2C. Lock Screen Teachable Moments Container Views (Host for Home Affordance)
// ----------------------------------------------------------------------------
%hook CSTeachableMomentsContainerView

- (void)layoutSubviews {
    %orig;
    UIView *homeContainer = safeGetViewIvarTR(self, "_homeAffordanceContainerView");
    if (!homeContainer && [self respondsToSelector:@selector(homeAffordanceContainerView)]) {
        homeContainer = self.homeAffordanceContainerView;
    }
    if (homeContainer) {
        homeContainer.alpha = 0.0;
        homeContainer.layer.opacity = 0.0;
        homeContainer.layer.hidden = YES;
    }
}

- (void)setHomeAffordanceContainerView:(UIView *)view {
    %orig(view);
    if (view) {
        view.alpha = 0.0;
        view.layer.opacity = 0.0;
        view.layer.hidden = YES;
    }
}

%end

%hook SBDashBoardTeachableMomentsContainerView

- (void)layoutSubviews {
    %orig;
    UIView *homeContainer = safeGetViewIvarTR(self, "_homeAffordanceContainerView");
    if (!homeContainer && [self respondsToSelector:@selector(homeAffordanceContainerView)]) {
        homeContainer = self.homeAffordanceContainerView;
    }
    if (homeContainer) {
        homeContainer.alpha = 0.0;
        homeContainer.layer.opacity = 0.0;
        homeContainer.layer.hidden = YES;
    }
}

- (void)setHomeAffordanceContainerView:(UIView *)view {
    %orig(view);
    if (view) {
        view.alpha = 0.0;
        view.layer.opacity = 0.0;
        view.layer.hidden = YES;
    }
}

%end

// ----------------------------------------------------------------------------
// 2D. SpringBoard Home Grabber Views (Never call setHidden: directly)
// ----------------------------------------------------------------------------
%hook SBHomeGrabberView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.layer.opacity = 0.0;
    self.layer.hidden = YES;
}

- (void)didMoveToWindow {
    %orig;
    self.alpha = 0.0;
    self.layer.opacity = 0.0;
    self.layer.hidden = YES;
}

- (CGFloat)alpha {
    return 0.0;
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

%end

%hook SBFHomeGrabberView

- (void)layoutSubviews {
    %orig;
    self.alpha = 0.0;
    self.layer.opacity = 0.0;
    self.layer.hidden = YES;
}

- (void)didMoveToWindow {
    %orig;
    self.alpha = 0.0;
    self.layer.opacity = 0.0;
    self.layer.hidden = YES;
}

- (CGFloat)alpha {
    return 0.0;
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

%end

%end // group SpringBoardHomeBarTransparency

// ============================================================================
// GROUP 3: Global Hooks (SpringBoard + All Apps via com.apple.UIKit)
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
        if (isSpringBoard && iiKitPrefEnabled(iiKitPrefTransparentDock)) {
            %init(SpringBoardTransparency);
        }
        if (isSpringBoard && iiKitPrefEnabled(iiKitPrefTransparentHomeBar)) {
            %init(SpringBoardHomeBarTransparency);
        }
        if ((isSpringBoard || [[mainBundle executablePath] containsString:@".app/"]) &&
            iiKitPrefEnabled(iiKitPrefTransparentHomeBar)) {
            %init(GlobalHomeBarTransparency);
        }
    }
}
